Python private function hacks
========================

Ok, there isn't actually a notion of public/private levels of access in python. However, functions which have double underscores "`__`" are not meant to be called from client code. Some of these functions have special meaning and are what actually get called when operators (such as `+`, `-`, `*`, `/`, `**`, `[]`, `()`, `.`, etc.)

If you want, you can implement or override these functions in your classes and gain fine grain control over functionality that is not available to you in other languages.

Let's start with a basic example. ( All the examples here are from an [ipython](https://ipython.org/) session.)

First let's make a class:

```python
In [1]: class foo(object):
   ...:     pass
   ...:
```

This doesn't do much yet. Lets put some attributes on it:

```python
In [2]: foo.a = 'aaa'

In [3]: foo.b = 'bbb'
```

Now let's make an instance and take a look at those attributes:

```python
In [4]: f = foo()

In [5]: f.a
Out[5]: 'aaa'

In [6]: f.b
Out[6]: 'bbb'
```

So far so good.

What if we wanted to be able to access the attributes of our class using dictionary lookup syntax?
Our class doesn't currently support this:

```python
In [7]: f['a']
---------------------------------------------------------------------------
TypeError                                 Traceback (most recent call last)
<ipython-input-7-43ec18acbe75> in <module>()
----> 1 f['a']

TypeError: 'foo' object has no attribute '__getitem__'
```

That error message is actually quite helpful. All we need to do is implement `__getitem__`:

This is really simple:

```python
In [8]: foo.__getitem__ = foo.__getattribute__

In [9]: f['a']
Out[9]: 'aaa'
```

Awesome! How about assignment with dictionary syntax?

Again, our class does not currently support that ...

```python
In [10]: f['a'] = 'zzz'
---------------------------------------------------------------------------
TypeError                                 Traceback (most recent call last)
<ipython-input-10-194e98347d7e> in <module>()
----> 1 f['a'] = 'zzz'

TypeError: 'foo' object does not support item assignment
```

But the fix is just as simple:

```python
In [11]: foo.__setitem__ = foo.__setattr__

In [12]: f['a'] = 'zzz'

In [13]: f['a']
Out[13]: 'zzz'

In [14]: f['another_attribute'] = 42

In [15]: f.another_attribute
Out[15]: 42
```

Sweet! Now we can access and set values as if our class is a dictionary (and we can still use the `.` syntax as well).

Hopefully by now you've notices that square bracket `[]` access and assignment operations are implemented in the `__getitem__` and `__setitem__` functions.

This opens up a lot of possibilities! Say you wanted a callback function to fire whenever an attribute is accessed. Just put it in the `__getattribute__` function!

Let's write a new class:

```python
In [16]: class bar(object):
   ....:     def __init__(self, callback):
   ....:         self.callback = callback
   ....:     def __getattribute__(self, name):
   ....:         self.callback(name)
   ....:         return self.__dict__[name]
```

Let's make a callback function and make and instance of `bar`:

```python
In [17]: def callback(name):
   ....:     print "in the callback, name was:", name
   ....:
   In [18]: b = bar(callback)
```

Ok, let's take it for a spin!

```python
In [19]: b.a = 42

In [20]: b.a
---------------------------------------------------------------------------
RuntimeError                              Traceback (most recent call last)
<ipython-input-20-76ea6bf73769> in <module>()
----> 1 b.a

<ipython-input-16-e3cb6dbfcabe> in __getattribute__(self, name)
      3         self.callback = callback
      4     def __getattribute__(self, name):
----> 5         self.callback(name)
      6         return self.__dict__[name]
      7

<many, many pages of this>


<ipython-input-16-e3cb6dbfcabe> in __getattribute__(self, name)
      3         self.callback = callback
      4     def __getattribute__(self, name):
----> 5         self.callback(name)
      6         return self.__dict__[name]
      7

RuntimeError: maximum recursion depth exceeded
```

Oh noes! What happened there?

Remember, the `.` in `self.callback` is handled by `__getattribute__` ... and we were using `self.callback` (as well as `self.__dict__`) in the implementation of `__getattribute__` . Oops.

That's OK, there is a fix. We'll just use the `__getattribute__` method on the superclass!

```python
In [21]: class bar(object):
   ....:     def __init__(self, callback):
   ....:         self.callback = callback
   ....:     def __getattribute__(self, name):
   ....:         object.__getattribute__(self, 'callback')(name)
   ....:         return object.__getattribute__(self, name)
   ....:

In [22]: b = bar(callback)

In [23]: b.a = 42

In [24]: b.a
in the callback, name was: a
Out[24]: 42
```

Sweet is the taste of victory!

There are a [bunch of these functions](https://docs.python.org/2/reference/datamodel.html#special-method-names) that have special meaning. If you implement them in your classes, you can enhance the functionality and elegance of your code---just take care to follow the [principle of least astonishment](https://en.wikipedia.org/wiki/Principle_of_least_astonishment).


