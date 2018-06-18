
Metaclasses
======

Hi folks!

Today I'm going to talk about metaclasses. Metaclasses are generally considered to be an advanced python topic, but I promise that it's really not that bad.

The first step on the path to understanding metaclasses is to recognize that in python, even though you don't need to specify types (as you do in many other programing languages), all python objects have a type. Essentially, the type of an object is the class that instantiated it.

Furthermore, we need to understand that *everything* in python is an object. Yes, everything. That means that if you can assign something to a variable in python the question "what is the type of this variable" is meaningful and has a concrete answer. Lets take a look at a few types we've all encountered. We do this by using the built-in function `type()`


```python
my_string = 'spam'
print type(my_string)
```

    <type 'str'>


Cool. As expected, `my_string` is of type `'str'`.

In fact, we could have defined `my_string` by using the class constructor like this:


```python
my_string = str('spam')
print type(my_string)
```

    <type 'str'>


Ok how about some numbers:


```python
print type(42)
print type(3.14159)
print type(1 + 6j)
```

    <type 'int'>
    <type 'float'>
    <type 'complex'>


Hopefully nothing unexpected there.

Now let's make our own type and inspect it:


```python
class foo(object):
    answer = 42

f = foo()
print type(f)
```

    <class '__main__.foo'>


Ok, that's a bit more interesting. `f` is of type `'__main__.foo'`. That means that the type is `foo` which is in the namespace `__main__`. The `__main__` part is just because we are in an interactive session. That would be replaced by the module (or package) if you were writing this in a file.

This is where things start to get wild.

What is the type of `foo`? Not an instance of `foo`, just `foo`. Let's find out:


```python
print type(foo)
```

    <type 'type'>


Ok. That's really weird. Apparently `foo` is an instance of the type `type` ... whatever that means.

It turns out that this is unnecessarily confusing. `type` in python does double duty. If you call `type` with a single argument it is a function which returns the class that instantiated the argument. That's what we've been doing so far.

The second (and more rare) use of `type` is as a constructor for the *class* `type`. Let that sink in for a moment.

That's right. `type` is a class and `foo` is an instance of that class.

Remember, *everything* in python is an object, which means that everything is an instance of some class---even classes!

Ok, since `foo` is a class, and it's an instance of `type`, that means that `type` is a special sort of class that instantiates other classes. As you may have already guessed, `type` is a 'metaclass'.

A metaclass is any class that produces other classes.

Let's get back to that second use of `type` as a constructor. Called as a constructor, `type` takes three arguments:
'`name`', '`bases`', and '`class_dict`'. '`name`' is the class name, '`bases`' are the ordered list (actually a tuple) of super-classes (remember that python supports multiple-inheritance), and '`class_dict`' is the dictionary that represents the class members (e.g. methods and class variables).

Let's try and recreate `foo` using this weird syntax (we'll call it foo2):


```python
foo2 = type('foo2', (object,), {'answer': 42})
f2 = foo2()

print f
print f2
print 'f.answer:', f.answer
print 'f2.answer:', f2.answer
```

    <__main__.foo object at 0x128be0b10>
    <__main__.foo2 object at 0x128aa3b10>
    f.answer: 42
    f2.answer: 42


Fantastic! `foo` and `foo2` are indistinguishable despite the dramatic syntactic difference in their class definition.

It turns out that using the `class` keyword is just syntactic sugar for the `type` syntax.

This leads to the key idea. What if we wanted to extend the behaviour of `type` for some of our classes? This turns out to be quite easy to do.


```python
class my_meta(type):
    def __init__(cls, name, bases, cls_dict):
        cls.came_from_my_meta = 'Oh yeah!'

class foo3(object):
    __metaclass__ = my_meta

f3 = foo3()
print f3.came_from_my_meta
```

    Oh yeah!


Note that the `came_from_my_meta` attribute was not specified in `foo3`; it came from the metaclass.

Now for the first metaclass superpower:

Metaclasses are forever. Any subclass of `foo3` will have the same metaclass. As [David Beazley](http://www.dabeaz.com/) said, metaclasses are like a genetic mutation. Subclasses automatically (and often without the author knowing about it) inherit the metaclass. This can be super powerful.


```python
class foo3_sub(foo3):
    pass

f3sub = foo3_sub()
f3sub.came_from_my_meta
```




    'Oh yeah!'



As you might expect, you can define more than just the `__init__` function. You can also define other special methods (double-underscore methods) like `__new__` etc. as well as ordinary methods and properties. Just keep in mind that these methods will only be on the resulting class and _**not**_ on instances of the resulting class. Lets extend that last metaclass to illustrate:


```python
class my_meta(type):
    def __init__(cls, name, bases, cls_dict):
        cls.came_from_my_meta = 'Oh yeah!'

    def foo(cls):
        return 'foo'

    @property
    def bar(cls):
        return 'bar'

class foo4(object):
    __metaclass__ = my_meta

f4 = foo4()
print f4.came_from_my_meta

print foo4.foo()
print foo4.bar
```

    Oh yeah!
    foo
    bar


Note that we called `foo` and `bar` on the class, not on the instance. Watch what happens if we do:


```python
f4.foo()
```


    ---------------------------------------------------------------------------

    AttributeError                            Traceback (most recent call last)

    <ipython-input-53-455f5e172045> in <module>()
    ----> 1 f4.foo()


    AttributeError: 'foo4' object has no attribute 'foo'


In vanilla python, you can decorate a method with `@classmethod` and the decorated method can be called via the class. It turns out that you can also call such `classmethod`s from an instance of the class. This is because of what is known as [method resolution order (mro)](https://www.python.org/download/releases/2.3/mro/) which is a slightly complicated topic that I won't bore you with now other than to say that in the case of `f4.foo()`, f4 looks for the definition of `foo` in `foo4` and its superclasses. In this case, the only superclasses are `object`. Hence, the lookup fails as the definition is in `my_meta` (which is not in the mro).

As a result of this, if you want to have methods that are _**only**_ callable from the class (and _**not**_ an instance), metaclasses are the obvious way to achive that goal.

----------------------------------------------------

Some Motivation
--------------

Ok, I've shown you some of the mechanics of metaclasses but not much in the way of why you might want to actually use them.

In my last couple of projects I've had to implement libraries which deal with representing binary data messages that are sent over the network using a custom protocol. I had to write classes which expose the fields of these messages and methods to take a filled out instance of one of these classes and convert it into a sequence of bytes to be sent over the wire. Also, I needed to write methods to take raw bytes read off the wire and convert them into the appropriate class instance.

Metaclasses saved the day for me in two interesting ways.

----------------------------------------------------

The first use I made of them is actually a pretty common use case. Registration of newly written classes in some global data-structure for lookup purposes. The challenge is that when you read a bunch of arbitrary bytes it's not immediately obvious which class corresponds with the bytes. In my case, a 'message ID' was present near the beginning of the message so that was the bit of information I needed to decide which class to use.

The obvious answer is to have a dictionary somewhere in the package that maps the ID to the class. Unfortunately, this is yet another thing that needs to be maintained. If the spec changes or a new message gets added or if an ID changes, you had better update that dictionary or the program will fail.

In my case, there were hundreds of these classes and maintaining all of that seemed like a nightmare.

Lets take a look at the solution:


```python
import sys

class MessageMeta(type):

    """
    A metaclass that will register all instances in the
    instance's module in a map called ID_MESSAGE_MAP
    """

    def __init__(cls, name, bases, clsdct):
        mod = sys.modules[cls.__module__]
        if not hasattr(mod, 'ID_MESSAGE_MAP'):
            mod.ID_MESSAGE_MAP = {}
        if hasattr(cls, 'message_id'):
            mod.ID_MESSAGE_MAP[cls.message_id] = cls

```

As you can see, the metaclass starts by determining the module that the class is in. If the module doesn't already have an `ID_MESSAGE_MAP` it adds it and initializes it to an empty dictionary. Next, if the class has an attribute called `message_id`, it registers the class by making an entry in the `ID_MESSAGE_MAP` dictionary.


```python
class MessageBase(object):
    __metaclass__ = MessageMeta

class MessageOne(MessageBase):
    message_id = 1

class MessageTwo(MessageBase):
    message_id = 2

print ID_MESSAGE_MAP
```

    {1: <class '__main__.MessageOne'>, 2: <class '__main__.MessageTwo'>, 3: <class '__main__.MessageFour'>}


As you can see, `ID_MESSAGE_MAP` auto-magically got populated with an ID:class mapping. This completely take care of the maintenance of this data-structure. Meta-programming for the win!

----------------------------------------------------

The second way I used (abused?) metaclasses is a little less orthodox.

I pretty much always use [sphinx](http://www.sphinx-doc.org/en/stable/) to generate documentation (if you've never used it, do yourself a favor and check it out).

Since I was documenting all the fields in the docstring, listing them in a `fields` attribute (needed for serialization since I need them in order), listing them in the `__init__` method parameters, and in the `__init__` body, I realized I had a bad case of [DRY](https://en.wikipedia.org/wiki/Don't_repeat_yourself) violation going on.

Take a look at a typical case:


```python
class MessageThree(MessageBase):

    """
    Message Three is the third of hundreds of messages :(

    :param int first_field: the first field, represents the first thing
    :param int second_field: the second field, represents the second thing
    :param int third_field: the third field, represents the third thing
    """

    message_id = 3

    fields = [
        'first_field',
        'second_field',
        'third_field'
    ]

    def __init__(self, first_field=0, second_field=0, third_field=0):
        self.first_field = first_field
        self.second_field = second_field
        self.third_field = third_field

```

Nasty right? Unfortunately it gets even worse!

In this protocol, they decided to make everything `int`s on the wire even if the data was floating point. Enter the ugly [scaled integer](https://en.wikipedia.org/wiki/Scale_factor_%28computer_science%29)

The docstrings end up actually looking like this:

:param int first_field: the first field, represents the first thing, scaling: 1e8, units: radians

To deal with the scaling, I had to add that information to the class somehow.

To deal with the scaling, I had to add that information to the class somehow. I thought about modifying the `fields` list and make the elements `tuple`s which have the attribute name and the scaling factor. I could then add attributes like `_first_field_scale = 1e8` to the class. Then I could make a bunch of properties that look like:

```python
    @property
    def first_field(self):
        return self._first_field / self._first_field_scale

    @first_field.setter
    def first_field(self, val):
        self._first_field = val * self._first_field_scale
```

This would work, but things are starting to get a little out of hand. Maintaining this mess is starting to look pretty depressing.

I then had the following key insight: all the information in this class is present in the docstring! I realized that I could use the metaclass to write the class body for me!

As insane as this sounds, the implementation is actually pretty succinct:


```python
class MessageMeta(type):

    """
    A metaclass that will register all instances in the
    instance's module in a map called ID_MESSAGE_MAP
    """

    def __init__(cls, name, bases, clsdct):
        mod = sys.modules[cls.__module__]
        if not hasattr(mod, 'ID_MESSAGE_MAP'):
            mod.ID_MESSAGE_MAP = {}
        if hasattr(cls, 'message_id'):
            mod.ID_MESSAGE_MAP[cls.message_id] = cls

        if not cls.__doc__:
            return

        fields = []
        types = []
        # we parse the docstring line by line looking for parameter information.
        for line in cls.__doc__.split('\n'):
            line = line.strip()
            # if the line starts with ':param' we know we the next two tokens
            # are the type and the field name
            if line.startswith(':param'):
                param = line.split()[2].strip(':')
                try:
                    param_type = eval(line.split()[1])
                except NameError:
                    return
                fields.append(param)
                types.append(param_type)
                scaling = 1
                if not hasattr(cls, param):
                    # if a field is a scaled integer, the word
                    # 'scaling' will be in the line
                    if 'scaling' in line:
                        scaling = float(line[line.index('scaling'):]
                                        .split(',')[0].split()[-1])
                        setattr(cls, '_' + param + '_scaling', scaling)
                        setattr(cls, '_' + param, param_type())

                        # we create a computed property with a getter/setter pair
                        # that handles the scaling factor for us.
                        def fget(self, param=param, scaling=scaling):
                            return getattr(self, '_' + param) / scaling

                        def fset(self, value, param=param, scaling=scaling):
                            setattr(self, '_' + param,
                                    param_type(value * scaling))

                        setattr(cls, param, property(fget, fset))
                    else:
                        # otherwise we don't need a property,
                        # a simple attribute will do fine
                        setattr(cls, param, param_type())
                # if a field has units associated with it, we store
                # it for use with __str__
                if 'units' in line:
                    attr = line.strip().split()[2].strip(':')
                    units = line[line.index('units'):].split(',')[0].split()[-1]
                    setattr(cls, '_' + attr + '_units', units)
        cls.fields = fields

        # for classes with a non-empty `fields` property, we generate
        # an `__init__` method which has each field as a parameter
        # with a default value and initializes the field to the parameter value.
        if cls.fields:
            param_list = ', '.join(f + '=' + repr(t())
                                   for f, t in zip(fields, types))

            init_body = '\n    '.join('self.' + f + ' = ' + f for f in fields)
            exec(('def __init__(self, {}):\n' +
                  '    {}\n').format(param_list, init_body), clsdct)

            cls.__init__ = clsdct['__init__']

class MessageBase(object):
    __metaclass__ = MessageMeta
```

Let's try it out:


```python
class MessageFour(MessageBase):

    """
    Message Four is the fourth of hundreds of messages :(

    :param int first_field: the first field, represents the first thing, scaling: 1e2, units: radians
    :param int second_field: the second field, represents the second thing, scaling: 1e4, units: meters/second
    :param int third_field: the third field, represents the third thing, scaling: 1e3, units: radians/second
    """

    message_id = 3

four = MessageFour(20, 30, 40)
print "first_field:", four.first_field
print "_first_field:", four._first_field
print "_first_field_scaling:", four._first_field_scaling
```

    first_field: 20.0
    _first_field: 2000
    _first_field_scaling: 100.0


Fantastic! The only thing that would make this better is a good `__str__` and `__repr__` function. I don't know about you, but I generally think in degrees rather than radians, feet rather than meters, and Knots rather than meters/second. Lets write something that will give us a useful printout:


```python
from math import pi

def radians_to_degrees(radians):

    """Converts radians to degrees"""

    return radians * 180 / pi


def meters_to_feet(meters):

    """Converts meters to feet"""

    return meters * 3.28084


def mps_to_kts(mps):

    """Converts meters / sec to Knots"""

    return mps / 0.51444444444


class MessageBase(object):
    __metaclass__ = MessageMeta

    def __repr__(self):
        return self.__class__.__name__ + '(' + ', '.join(
            [repr(getattr(self, f)) for f in self.fields]
        ) + ')'

    def __str__(self):

        printvals = []

        for field in self.fields:
            val = getattr(self, field)
            try:
                units = ' ' + getattr(self, '_' + field + '_units')
                if 'radians' in units:
                    units += (' (' + repr(radians_to_degrees(val)) +
                              units.replace('radians', 'degrees') + ')')

                if 'meters/second' in units:
                    units += (' (' + repr(mps_to_kts(val)) +
                              units.replace('meters/second', 'Kts') + ')')

                elif 'meters' in units:
                    units += (' (' + repr(meters_to_feet(val)) +
                              units.replace('meters', 'feet') + ')')
            except AttributeError:
                units = ''

            printvals.append(field + ': ' + repr(val)  + units)

        if not printvals:
            return repr(self)

        return self.__class__.__name__ +  ':\n    ' + '\n    '.join(printvals)

```

Lets kick the tires and light the fires:


```python
class MessageFive(MessageBase):

    """
    Message Five is the fifth of hundreds of messages :(

    :param int first_field: the first field, represents the first thing, scaling: 1e2, units: radians
    :param int second_field: the second field, represents the second thing, scaling: 1e4, units: meters/second
    :param int third_field: the third field, represents the third thing, scaling: 1e3, units: radians/second
    """

five = MessageFive(50, 60, 70)
print repr(five)
print five
```

    MessageFive(50.0, 60.0, 70.0)
    MessageFive:
        first_field: 50.0 radians (2864.7889756541163 degrees)
        second_field: 60.0 meters/second (116.63066954744389 Kts)
        third_field: 70.0 radians/second (4010.7045659157625 degrees/second)



----------------------------------------------------

Thats all folks!

If you've used metaclasses in your projects, I'd love to hear about what you guys have done.


