Generators and Coroutines
=========================

A couple people have suggested that a good topic for a post would be a discussion of the `yield` keyword in python.

`yield`
-------

So what is `yield` all about? Let's fire up an [IPython](https://ipython.org/) Read-Evaluate-Print-Loop (REPL) and dive right in with an example:

```python
In [1]: def yielder():
   ...:     i = 5
   ...:     while i > 0:
   ...:         yield i
   ...:         i -= 1
```

So what happens when we call `yielder`?

```python
In [2]: yielder()
Out[2]: <generator object yielder at 0x10519b5f0>
```

Interesting. So calling `yielder` didn't really do anything, but it returned a `generator` instance, whatever that is.

Ok, let's assign this to a variable and take a look at what we got:

```python
In [3]: y = yielder()
```

now, if we type `y.` and hit tab, we can see the public (i.e. doesn't start with underscore) methods:

```python
In [4]: y.
           y.close      y.gi_running y.throw
           y.gi_code    y.next
           y.gi_frame   y.send
```

For today's post, I'm just going to talk about `send` and `next`. You might not ever need to know about `gi_code`, `gi_running`, and `gi_frame`. The methods `close` and `throw` are more advanced coroutine topics that I'll skip for now.

The `next` method is primarily used with generators.

###Generators

Here's what happens when you call `next`:

```python
In [4]: y.next()
Out[4]: 5
```

Ok, cool! Now we're getting somewhere. Let's call that a few more times:

```python
In [5]: y.next()
Out[5]: 4

In [6]: y.next()
Out[6]: 3

In [7]: y.next()
Out[7]: 2

In [8]: y.next()
Out[8]: 1

In [9]: y.next()
---------------------------------------------------------------------------
StopIteration                             Traceback (most recent call last)
<ipython-input-9-75a92ee8313a> in <module>()
----> 1 y.next()

StopIteration:
```

It turns out that the `yield` keyword (as in other languages) is deeply connected with iteration. Calling `next` on the generator 'generates' the next value until there aren't any more values to generate. In python, the `StopIteration` exception is raised to indicate that the generator has exhausted its values.

We can actually use the `for` syntax to drive our generator:

```python
In [10]: for i in yielder():
    ...:     print i
    ...:
5
4
3
2
1

```

Pretty slick.

You can have as many yield statements as you want in a generator function:

```python
In [11]: def sg1():
    ...:     yield 'Jack'
    ...:     yield 'Dan'
    ...:     yield 'Sam'
    ...:     yield "Teal'c"
    ...:
```

You can also convert a generator to a list:

```python
In [12]: list(sg1())
Out[12]: ['Jack', 'Dan', 'Sam', "Teal'c"]
```

It's possible to construct infinite 'lists' using generators:

```python
In [13]: def evens():
    ...:     i = 0
    ...:     while True:
    ...:         yield i
    ...:         i += 2
    ...:
```

Just don't call `list(evens())` :)

Instead, you can implement some of the Haskell builtins ;)

Let's just do `take` for now:

```python
In [14]: from itertools import islice

In [15]: take = lambda n, gen: list(islice(gen(), 0, n))

In [16]: take(10, evens)
Out[16]: [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]

```

One of the most compelling reasons to use generators is that you can use them to process very large datasets in a constant amount of memory. If you don't know about generators, you might be tempted to make a list and keep appending your data to it and then do some post processing. That work-flow falls apart when you are dealing with terabytes of data. Generators can realy save your bacon in these situations.

In fact, generators are *so* useful, Python provides an alternate list comprehension syntax that gives you a generator rather than a list. It's just like a list comprehension, except you use parenthesis!

Consider this list:

```python
In [17]: my_list = [x**2 for x in range(10)]

In [18]: my_list
Out[18]: [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]
```

Now the generator version:

```python
In [19]: my_gen = (x**2 for x in range(10))

In [20]: my_gen
Out[20]: <generator object <genexpr> at 0x11d290be0>

In [21]: for i in my_gen: print i
0
1
4
9
16
25
36
49
64
81

```

Generators have first class support in python. Take a look at the [itertools](https://docs.python.org/2/library/itertools.html) built-in module.

Before we move on to coroutines, I want to make one final observation. When you call a generator function, nothing happens. What I mean by that is that none of the lines of code you write in the body of your function are run:

```python
In [22]: def yielder2():
    ...:     print "I'm a generator!"
    ...:     yield
    ...:


In [23]: y = yielder2()

In [24]: y.next()
I'm a generator!
```

Note that nothing happened until we called `next`. The takeaway is that if you include the keyword `yield` *anywhere* in your function (or method), your function *wont* run when you call it! To get anything to run, you must call `next`. It gets even more wild when you consider that when you call `next`, the function will only run until the *first* `yield`. Subsequent calls to `next` will run your function to the next `yield` and so on.

You've converted your function into an entirely different beast. This seemed deeply strange to me at first, but it turns out to be very powerful. Basically, the `yield` statement pauses the execution of your function. It is resumed by calling `next`. This actually opens up a whole new programming paradigm called coroutines.

###Coroutines

While the most common use case for generators is iteration, you can also use the `yield` statement to pause and resume execution of your functions. This can allow you to build a state-machine out of simple functions. You can think of `yield` as offering you a way to specify alternate entry and exit points for your program.

If we think of `yield` this way, one of the first things that may come to mind is that so far we have seen a way to return values, but be haven't seen a way to pass values into our generators. Enter the `send` function:

```python
In [25]: def my_coro():
    ...:     print 'My first co-routine!'
    ...:     print 'Send me a value ...'
    ...:     while True:
    ...:         val = yield
    ...:         print val
    ...:

In [26]: c = my_coro()

In [27]: c
Out[27]: <generator object my_coro at 0x11d290a00>

In [28]: c.next()
My first co-routine!
Send me a value ...

In [29]: c.send('spam')
spam

In [30]: c.send('eggs')
eggs
```

A couple things to note:

As you can see, this is still a generator object. Furthermore, we still need to 'warm it up' by calling `next`. Only then can we start calling it with `send` (actually, we could have done `send(None)` instead of `next`).

Pretty cool right?

So what should you do with generator/coroutines? Well that's completely up to you, the sky is the limit. However, one of the poster child uses of coroutines is thread-less concurrency.

People usually use threads (and multi-processes) for one of two reasons: parallelism or concurrency.

####Parallelism

Parallelism is using multiple CPU cores to speed up a computation--i.e. you split a problem into chunks that can be computed independently, compute them on separate threads (or processes or even separate machines), and finally combine the results of the computations into the final result.

It turns out that the [Global Interpreter Lock (GIL)](https://wiki.python.org/moin/GlobalInterpreterLock) prevents multiple threads from running simultaneously so in python, parallelism is typically done via multiprocessing.

####Concurrency

Concurrency on the other hand is having multiple tasks executing simultaneously. The distinction is subtle but important. Consider the bad old days when your computer had only one CPU core. You could run multiple programs at once just fine. That's concurrency. Note that parallelism is impossible on a single core machine.

In python, the threading module is often used for concurrency. However, threading has some overhead associated with it. If you are running a server and you want it to handle thousands of simultaneous network connections, your application will suffer if you decide to implement it by spawning thousands of threads (or even worse, processes). This is where coroutines really shine.

It is possible to (and many frameworks do) use coroutines to implement a single threaded cooperative multitasking environment by having an event-loop which manages the execution of tasks (coroutines) by calling the `next` method on each coroutine that is in the "I'm ready to do work bin". The task is then either done (`StopIteration`) or it puts it self back in the available queue by `yield`ing.

There are a couple gotchas when it comes to using coroutines for multitasking. First and foremost, if any of your coroutines blocks, your whole app comes to a grinding halt. So your app needs to be coroutines 'all the way down' so to speak. Second, this is *cooperative* multitasking. i.e. *not* preemptive, so there is no mechanism for the task scheduler to switch tasks unless the currently running task calls `yield`. If a task blocks, there isn't a way to switch---see the first gotcha.

-------------------------------------------------------------------------------------------------

One final note:

I've been calling `generator_instance.next()` in this post. It turns out that since python 2.6, there is a builtin `next` that you should call instead. e.g. `next(genertor_instance)`. This is to align the generator syntax with some of python's other protocols. In python 3.*, there is no `next` method. Instead there is a `__next__` method. Calling `next(generator_instance)` will always do the right thing and it's the way you should be calling it.

Hopefully this added another tool to your toolbox. Happy holidays!
