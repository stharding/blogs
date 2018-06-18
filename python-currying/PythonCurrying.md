Currying in Python with decorators
==================================

In some functional languages like haskell, all functions are automatically
curried. Consider the following function:

```haskell
f a b c = a + b + c
```

The type inference engine determines that the type is:

```haskell
f :: Num a => a -> a -> a -> a
```

This should be exactly what we expected. It says that `f` is a function which
consumes three __`a`__'s and produces an __`a`__ (where __`a`__ conforms to
the typeclass `Num` because we are using the `+` operator in the function
body).

Since all functions are curried, we can 'partially apply' the function---e.g.
`f 1` is a valid expression.

What about the type of `f 1`? If we check the type in the REPL, we get:

```haskell
f 1 :: Num a => a -> a -> a
```

We see that `f 1` is a function which takes two `a`s and produces an `a`.
Similarly `f 1 2` is another valid function. Often it is through currying that
meaningful programs can be elegantly constructed by composing (sometimes
partially applied) functions.

So what if we want to leverage this in Python? At first, we might be tempted
to think that the following is a reasonable translation of `f` in Python:


```python
def f(a, b, c):
    return a + b + c
```

Unfortunately this is not the case. Python does not automatically curry
functions for you---i.e. `f(5)` is not a valid expression because `f` is a
function which takes three arguments! In order to rewrite `f` to be equivalent
to the haskell function `f` we must do something like the following:

```python
def f(a):
    return lambda b:\
               lambda c:\
                   a + b + c
```

Or if you don't like the `lambda` expressions:

```python
def f(a):
    def g(b):
        def h(c):
            return a + b + c
        return h
    return g
```

Now `f` is a faithful representation of the haskell version. Unfortunately,
arguably neither of the rewrites of `f` is desirable. The hoops that we have
to jump though to enable currying for even simple Python functions is both
cumbersome and has a deleterious effect on the readability of our code.

Furthermore, the operator for function application in Python is parentheses!
This makes calling our curried functions look a bit odd (or at the very least,
decidedly non-pythonic). If we want the equivalent of the haskell `f 1 2` we
have to do `f(1)(2)`.

Fortunately there is an elegant solution. Decorators!

Python Decorators
-----------------

Decorators are nothing more than syntactic sugar for the application of a
higher-order function to the definition of an ordinary function.

Recall that a higher-order function is nothing more than a function which
takes a function as a parameter and returns a function as a result.

The syntax for decorators is to put an `@` symbol followed by the decorator
function name. The next line starts the ordinary `def`.

Lets say that we have written a higher-order function which transforms
ordinary functions into extraordinary functions! Say we called this function
`extra`. This is how we apply this awesome function:

```python
@extra
def ordinary(arg1, arg2, arg3):
    # implementation of ordinary function ...
```

This is exactly the same as doing this:

```python
def ordinary(arg1, arg2, arg3):
    # implementation of ordinary function ...

ordinary = extra(ordinary)
```

What does `extra` do? Whatever you want it to! The sky is the limit. You can
even stack the decorations. If you had another higher-order function that made
things super, you could do:

```python
@super
@extra
def ordinary(arg1, arg2, arg3):
    # implementation of ordinary function ...
```

Which is the same thing as:

```python
def ordinary(arg1, arg2, arg3):
    # implementation of ordinary function ...

ordinary = super(extra(ordinary))
```

Lets see if we can fix currying in python with one of these guys. We want a
function that will transform an ordinary function with arbitrary numbers of
arguments and keyword-arguments and rewrite them in a form similar to the
rewrite of `f` above. To do this, we will keep track of the number of
arguments we see, and the number of expected arguments. With this information,
we can construct a recursive function that will return an appropriate lambda
expression to do the partial (or full) function application.

Here goes!

```python
def curry(func):
    def curried(*args, **kwargs):
        if len(args) + len(kwargs) >= func.__code__.co_argcount:
            return func(*args, **kwargs)
        return (lambda *args2, **kwargs2:
                curried(*(args + args2), **dict(kwargs, **kwargs2)))
    return curried
```

(this snippet was shamelessly copied from [here](https://gist.github.com/JulienPalard/021f1c7332507d6a494b))

Note that the base case of the recursion is hit when we are provided with all
of the expected arguments. In this case we just return the function applied to
it's `*args, **kwargs`. If we don't we return a `lambda` which is expecting
the rest of the parameters.

Now we can do this:

```python
@curry
def f(a, b, c):
    return a + b + c
```

This 'decorated' version of `f` is now completely faithful to the original
haskell implementation. The really awesome bit is that not only is the
function implementation no longer mangled by manual currying, the application
is also completely transparent!

Check out this ipython session to see the glory of this!

```python
In [1]: def curry(func):
   ...:     def curried(*args, **kwargs):
   ...:         if len(args) + len(kwargs) >= func.__code__.co_argcount:
   ...:             return func(*args, **kwargs)
   ...:         return (lambda *args2, **kwargs2:
   ...:                 curried(*(args + args2), **dict(kwargs, **kwargs2)))
   ...:     return curried
   ...:

In [2]: @curry
   ...: def f(a, b, c):
   ...:     return a + b + c
   ...:

In [3]: type(f)
Out[3]: function

In [4]: type(f(1))
Out[4]: function

In [5]: type(f(1, 2))
Out[5]: function

In [6]: type(f(1, 2, 3))
Out[6]: int

In [7]: f(1)(2)(3)
Out[7]: 6

In [8]: f(1)(2, 3)
Out[8]: 6

In [9]: f(1, 2, 3)
Out[9]: 6

In [10]: f(1, 2)(3)
Out[10]: 6

In [11]: f(1, 2, 3)
Out[11]: 6
```

Note that we can now call `f` in a variety of ways. We can still call it with
multiple function applications like: `f(1)(2)(3)` but we can also call it with
a parameter list: `f(1, 2, 3)` and we get exactly the same results.

Happy coding!
