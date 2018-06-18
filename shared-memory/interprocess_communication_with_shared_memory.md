Interprocess communication in Python with shared memory
=======================================================

The python ecosystem has rich support for interprocess communication (IPC). The [multiprocessing](https://docs.python.org/3.4/library/multiprocessing.html?highlight=process)
API allows multiple python processes to coordinate by passing [pickled](https://docs.python.org/3/library/pickle.html) objects back and forth. Python has full support for signal handling, socket IO, and the select API ([to name just a few](https://docs.python.org/3/library/ipc.html)).

In this post, I'll explore interprocess communication via shared memory using python. Specifically, I'll make use of [memory mapped files](https://en.wikipedia.org/wiki/Memory-mapped_file) to facilitate shared state between arbitrary processes.

**NOTE:** This post assumes you are using Linux. Similar, but not identical code will work on Windows.


**NOTE:** The python standard library has built-in support for `mmap` and you should probably just use that, but to explore the space of the possible, I'll be using [Cython](http://cython.org/) to make `mmap` and associated calls.

Shared Memory with a backing file
---------------------------------

### Problem statement:

Lets say we have some data structure that contains some global state. When I say global, I mean *really* global. Like, multiple processes need access to this shared state. It also needs to be *really* fast.

### Solution

First let's make a data structure to represent the state. Suppose that the following `C` struct represents the data:

```C
typedef struct {
    int bar;
    int baz;
} foo;
```

Wait, let's try that again. We want to use this with Python, so here that is again in Cython:

```python
cdef struct foo:
    int bar
    int baz
```

Ok, better.

To use this in python We'll need a wrapper:

```python
from libc.stdlib cimport malloc, free


cdef class Foo:
    cdef foo* _foo
    cdef bint free_on_dealloc

    def __init__(self, bar=0, baz=0):
        self._foo = <foo*>malloc(sizeof(foo))
        self.bar = bar
        self.baz = baz
        self.free_on_dealloc = True

    def __dealloc__(self):
        if self.free_on_dealloc:
            free(self._foo)

    @staticmethod
    cdef Foo from_foo(foo* the_foo):
        cdef Foo c = Foo()
        free(c._foo)
        c._foo = the_foo
        return c

    @property
    def bar(self):
        return self._foo[0].bar

    @bar.setter
    def bar(self, int val):
        self._foo[0].bar = val

    @property
    def baz(self):
        return self._foo[0].baz

    @baz.setter
    def baz(self, int val):
        self._foo[0].baz = val

    @property
    def as_bytes(self):
        return str((<char*>self._foo)[:sizeof(foo)])

    @classmethod
    def from_bytes(cls, bytes foo_bytes):
        return Foo.from_foo(<foo*>(<char*>foo_bytes))

    def __len__(self):
        return sizeof(foo)

    def __repr__(self):
        return self.__class__.__name__ + '({self.bar}, {self.baz})'.format(self=self)
```

Now to share this thing across multiple processes.

We'll need to add the following import:

```python
from posix.mman cimport mmap, PROT_READ, PROT_WRITE, MAP_SHARED
```

Now we can add a factory:

```python
def foo_from_mmap(file_name):
    with open(file_name, 'ra+b') as f:
        ret_foo = Foo.from_foo(<foo*>(mmap(
            NULL, sizeof(foo), PROT_READ|PROT_WRITE, MAP_SHARED, f.fileno(), 0)
        ))
        ret_foo.free_on_dealloc = False
        return ret_foo
```

Let's give that a try:

```python
In [2]: f = foo_from_mmap('/tmp/suchfoo')
---------------------------------------------------------------------------
IOError                                   Traceback (most recent call last)
<ipython-input-5-cd36a7dcc9be> in <module>()
----> 1 f = foo_from_mmap('/tmp/suchfoo')

/home/harding/.cache/ipython/cython/_cython_magic_573532173283c4852c4f34d66889e965.pyx in _cython_magic_573532173283c4852c4f34d66889e965.foo_from_mmap()
     69
     70 def foo_from_mmap(file_name):
---> 71     with open(file_name, 'ra+b') as f:
     72         ret_foo = Foo.from_foo(<foo*>(mmap(
     73             NULL, sizeof(foo), PROT_READ|PROT_WRITE, MAP_SHARED, f.fileno(), 0)

IOError: [Errno 2] No such file or directory: '/tmp/suchfoo'
```

Oh, right. This is backed with a file. It might help to make the file first ...

```python
In [3]: with open('/tmp/suchfoo', 'wb') as f:
   ...:     pass
   ...:

In [4]: f = foo_from_mmap('/tmp/suchfoo')

In [5]: print(f)
[1]    17510 bus error (core dumped)  ipython

```

That's not good ... what happened there?

It turns out that if you use memory mapped files with a backing in the file-system, the file needs to already have enough bytes in it to support your needs.

Ok, so lets use that cool `as_bytes` property to prime the pump.

```python
In [3]: with open('/tmp/suchfoo', 'wb') as f:
   ...:     f.write(Foo(42, 98).as_bytes)

In [4]: f = foo_from_mmap('/tmp/suchfoo')

In [5]: print(f)
Foo(42, 98)
```

Awesome!

Now let's open up a new session and do some IPC!

```python
In [3]: f = foo_from_mmap('/tmp/suchfoo')

In [4]: print(f)
Foo(42, 98)
```

So far so good. We are able to read the state in a different process.

Now in that second process, let's change the state:

```python
In [5]: f.bar = 31337

In [6]: print(f)
Foo(31337, 98)
```

Ok, but did that change the state for the original process?

```python
In [6]: print(f)
Foo(31337, 98)
```

Victory! The original process also sees the change!

An arbitrary number of processes can memory map this file and read/write to share interprocess global state.


Shared Memory with no backing file
----------------------------------

If you don't want to expose the process's state to the file-system, you don't have to. The `mmap` call requires a file descriptor. We used a call to `.fileno()` on an open file to get it in the previous case, but that is not the only way.

We will call [`shm_open`](http://man7.org/linux/man-pages/man3/shm_open.3.html) to get a file descriptor that points to mapped memory that is not backed by a file, but rather referred to by name. If there isn't an existing mapping, one will be created, bet either way, you get a file descriptor that you can pass to `mmap`.

We'll need to add some more imports:

```python
from posix.mman cimport (
    mmap,
    shm_open,
    PROT_READ,
    PROT_WRITE,
    MAP_SHARED,
)
from posix.fcntl cimport (
    O_RDWR,
    O_CREAT
)
from posix.unistd cimport ftruncate
```

Now we can add a new factory which will facilitate IPC with no backing file:

```python
def foo_from_shm(bytes tagname):
    cdef int fd
    fd = shm_open(<const char*>tagname, O_RDWR | O_CREAT, 0666)
    ftruncate(fd, sizeof(foo))
    ret_foo = Foo.from_foo(<foo*>(mmap(
        NULL, sizeof(foo), PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0)
    ))
    ret_foo.free_on_dealloc = False
    return ret_foo
```

Now we can make the following call in two separate processes:

```python
In [4]: f = foo_from_shm('such_foo')
```

As before, each process can read and write to the shared state. The only difference is that in this case, the file-system is left completely out of the picture.


Final thoughts
--------------

Both ways of mapping shared memory are super fast. However, if you have a backing file in the file-system, you can persist state past the life of all the processes. i.e., the next time you fire up the process(s), you get the state as it was when everything was shut down the last time.

This may or may not be what you want. The second method makes sense for when you have no need (or actively don't want) to store state in the file-system.

Also, note that I haven't said anything about synchronizing access to the shared state. All the same problems that exist for multiple threads writing to a shared data structure are present with a shared interprocess data structure.

Lastly, I would point out the `from_bytes` and `as_bytes` methods on the `Foo` class. These enable you to extend the interprocess communication across multiple machines by using sockets. I'll leave the implementation details as an exercise for the reader.
