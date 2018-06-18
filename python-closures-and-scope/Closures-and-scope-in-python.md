Closures and scope in python
============================

I recently ran into a bug that came up because of my lack of understanding when it comes to how scoping works in python closures.

Check out this code:

```python
import threading

def threaded_print():
    for i in range(10):
        def print_number():
            print 'the number is: {}'.format(i)
        threading.Thread(target=print_number).start()

threaded_print()
```

What do you think it prints?

If you think it prints:

```
the number is: 0
the number is: 1
the number is: 2
the number is: 3
the number is: 4
the number is: 5
the number is: 6
the number is: 7
the number is: 8
the number is: 9
```

You are most likely correct, but if you are like I was yesterday, you would think so for the wrong reason. I thought it would print that because I thought that since `i` was a primitive type, the value of `i` would be bound in the print function *at function definition time* (for the `print_number` function).

This is absolutely not the case.

Consider this modification:

```python
import threading
import time

def threaded_print():
    for i in range(10):
        def print_number():
            time.sleep(0.1)
            print 'the number is: {}'.format(i)
        threading.Thread(target=print_number).start()

threaded_print()
```

This outputs:

```
the number is: 9
the number is: 9
the number is: 9
the number is: 9
the number is: 9
the number is: 9
the number is: 9
the number is: 9
the number is: 9
the number is: 9
```

Gah?!

This demonstrates that the first version only *accidentally* runs as expected. It is in fact a classic race condition. The only reason that is printed what I expected was that it was printing the ***current*** value of the ***shared*** variable `i` (shared between all the copies of `print_number`).

In python, a closure is a function which captures the enclosing scope. For example:

```python
In [1]: def f():
   ...:     x = 10
   ...:     def g():
   ...:         print x
   ...:     return g
   ...:

In [2]: g = f()

In [3]: g()
10
```

In this snippet, the ***variable*** *(not the value)* `x` is captured by `g`. As proof, take a look at this:

```python
In [1]: def f():
   ...:     x = 10
   ...:     def g():
   ...:         print x
   ...:     x += 1
   ...:     return g
   ...:

In [2]: g = f()

In [3]: g()
11
```

This is also known as 'late binding'. i.e. the value of `x` is not looked up until `g` is called.

At this point, you (like me) might think you can do this:

```python
In [4]: def f():
   ...:     x = 10
   ...:     def g():
   ...:         print x
   ...:     def h():
   ...:         x += 1
   ...:     return g, h
   ...:
```

Unfortunately, the scoping rules will see the assignment and treat is as a local (to `h`) variable and you will get this error:

```python
In [5]: g, h = f()

In [6]: g()
10

In [7]: h()
---------------------------------------------------------------------------
UnboundLocalError                         Traceback (most recent call last)
<ipython-input-7-59696a9ab36e> in <module>()
----> 1 h()

<ipython-input-4-1132edef3f6b> in h()
      4         print x
      5     def h():
----> 6         x += 1
      7     return g, h
      8

UnboundLocalError: local variable 'x' referenced before assignment
```

You can however share a captured variable and do anything but assignment:

```python
In [1]: def f():
   ...:     x = []
   ...:     def pushx(val):
   ...:         x.append(val)
   ...:     def popx():
   ...:         return x.pop()
   ...:     def printx():
   ...:         print x
   ...:     return pushx, popx, printx
   ...:

In [2]: pushx, popx, printx = f()

In [3]: printx()
[]

In [4]: pushx('awesome')

In [5]: popx()
Out[5]: 'awesome'

In [6]: for i in "that's all folks!".split(): pushx(i)

In [7]: printx()
["that's", 'all', 'folks!']

In [8]:
```

Happy coding!