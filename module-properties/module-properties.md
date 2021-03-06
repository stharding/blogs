Lazy-Loading Modules in Python
==============================

When I'm making a python package, I usually write an `__init__.py` which lifts the packages modules into the package namespace.

Assume you have a package like this:

```
my_package/
    __init__.py
    module1.py
    module2.py
    module3.py
```

If you leave the `__init__.py` blank, you cannot do:

```python
import my_package

my_package.module1
```

This will result in an error that looks like:

```python
---------------------------------------------------------------------------
AttributeError                            Traceback (most recent call last)
<ipython-input-2-dc2aca417ab9> in <module>()
----> 1 my_package.module1

AttributeError: module 'my_package' has no attribute 'module1'
```

Doing this also fails in the same way:

```python
from my_package import *

module1
```

This is because the `module1` symbol is not in the `my_package` namespace. That is one of the main purposes of the `__init__.py`. We can arbitrarily control the package namespace by importing symbols. Additionally, we can control what symbols are imported when someone does `from my_package import *` by listing the symbols (as strings) in a variable called `__all__`.

Simply importing the sub-modules in the `__init__.py` solves the problem:

```python
# my_package.__init__.py

from . import module1
from . import module2
from . import module3
```

This is fine for small packages, but what if there are hundreds of sub-modules? Or, what if loading the modules has significant overhead? It may make sense to not lift the modules into the package namespace. You often see this in large packages. The rational is easy to understand, but I got to wondering if there was a way to have the benefit of having the symbols lifted, and avoid the overhead of actually importing the modules.

A natural solution would be to use properties. If you've never used these, here is a crash course:

```python
class Foo(object):
    @property
    def bar(self):
        return 42
```

If you make an instance of `Foo` you can access `bar` without function application syntax:

```python
f = Foo()
print(f.bar)
```

This prints `42`. Note that we call `bar` without parenthesis. In fact, `f.bar()` results in an error because `int` instances are not callable. The `@property` mechanism is often used to implement computed properties that in other languages would need to be in getter/setter functions.

Back to the problem at hand. We would like to expose the symbols at the package level, but delay the actual import until the symbol is accessed. Using properties, this would look something like:

```python
@property
def module1():
    from . import module1 as _module1
    return _module1
```

Unfortunately, this does not work. This is because `@properties` are designed to work with class instances, not classes. When we try to call `module1`, instead of the function running, we get this:

```python
In [10]: module1
Out[10]: <property at 0x1058a8cc8>
```

We got a `property` instance. The property needs to be bound to an instance in order to run.

It's starting to look like you can't have properties on modules. :(

Except that you can! You just have to be willing to go a little off the beaten path.

As I've said in previous posts, *everyting* in python is an object. We will use this fact to bend python to our will.

Specifically, we can extend the module object type to do what we want:

```python
from types import ModuleType

class MyModule(ModuleType):
    @property
    def module1(self):
        from . import module1 as _module1
        return _module1

    @property
    def module2(self):
        from . import module2 as _module2
        return _module1

    @property
    def module3(self):
        from . import module3 as _module3
        return _module1
```

Now, if we make an instance of `MyModule`, those properties should work as expected. Additionally, we will need to replace the existing module in the cache with an instance of `MyModule`:

```python
import sys
sys.modules[__name__] = MyModule(__name__)
```

This is very close to a working solution, but there are still some missing pieces.

This code touches on one of the areas which are significantly different between python2 and python3. Much of the import mechanisms have been moved from C code in the interpreter to python code that you can inspect and interact with. This results in subtle differences in what happens when you do an import. Here is some code that, so far as I can tell, runs the same in both versions of the language:

```python
import sys
import importlib
from types import ModuleType


class MyModule(ModuleType):
    @property
    def module1(self):
        if not self.__dict__.get('module1'):
            self.__dict__['module1'] = importlib.import_module('.module1', __package__)

        return self.__dict__['module1']

    @module1.setter
    def module1(self, mod):
        self.__dict__['module1'] = mod

    # and so on for all the modules

old = sys.modules[__name__]
new = MyModule(__name__)
new.__path__ = old.__path__

for k, v in list(old.__dict__.items()):
    new.__dict__[k] = v

sys.modules[__name__] = new
```

It turns out that in python3, we need a setter because deep in the python code that performs the import it does a `setattr` on the module, while in the python2 version it relies on the builtin `__import__` function which seems to manipulate the module `__dict__` directly.

There is one last element that could use some improvement.

When I'm developing, I spend a lot of time in the REPL (I prefer iPython) and I rely on tab completion. Since `@property` methods don't end up in the class `__dict__` the sub-modules don't auto-complete on tab. Let's fix that.

```python
import sys
import importlib
from types import ModuleType


class MyModule(ModuleType):

    def __init__(self, name):
        super(MyModule, self).__init__(name)
        self.module1 = None
        self.module2 = None
        self.module3 = None

    def __getattribute__(self, attr):
        val = object.__getattribute__(self, attr)
        if val is None:
            try:
                ret = object.__getattribute__(self, '_' + attr)
            except AttributeError:
                return None

            setattr(self, attr, ret)
            return ret

        return val

    @property
    def _module1(self):
        if not self.__dict__.get('module1'):
            self.__dict__['module1'] = importlib.import_module('.module1', __package__)

        return self.__dict__['module1']

    # and so on for all the modules

old = sys.modules[__name__]
new = MyModule(__name__)
new.__path__ = old.__path__

for k, v in list(old.__dict__.items()):
    new.__dict__[k] = v

sys.modules[__name__] = new
```

Note that since we re-named the `@property`s, we no longer need the setters.

This is a python2/3 compatible recipe for lazy module loading while maintaining the semantics of eager loading (and symbol lifting) in a package `__init__.py`
