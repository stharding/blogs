# Calling Python from C++

Have you ever been writing C++ and you find yourself writing non-performance-critical code that would be absolutely trivial in Python? Or perhaps there is some complex problem that has an optimized solution in a python package, and if you could just call it from your C++ code life would be so much better.

It turns out that this is fairly easy to do. I've talked about using Cython to wrap C/C++ for python, and as it happens, Cython can this job in reverse as well.

To demonstrate this, I'll call into the [`art`](https://github.com/sepandhaghighi/art) package from a simple C++ program.

First, we need the art package installed:

```bash
pip install art
```

Now lets write a Cython file that exposes a function that accepts a `std::string` and calls the `text2art` function in the `art` package and returns the result.


```python
# art_wrapper.pyx

from libcpp.string cimport string

from art import text2art as _text2art

cdef public string text2art(string text):
    return _text2art(text)
```

If you don't have Cython installed, you will also need to:

```bash
pip install cython
```

Because we used the `public` keyword in our `cdef` function, when we call:

```bash
cython -2 art_wrapper.pyx
```

Two files are generated: `art_wrapper.c` and `art_wrapper.h`. We include this generated header file in our C++ program:

```c++
// main.cpp

#include <iostream>
#include "Python.h"
#include "art_wrapper.h"

int main(int argc, char *argv[])
{
    Py_Initialize();
    initart_wrapper();
    std::cout << text2art("Python in C++!") << std::endl;
    Py_Finalize();
    return 0;
}
```

Now we are ready to build!

```bash
g++ art_wrapper.c main.cpp -o main $(python-config --libs) $(python-config --includes) $(python-config --cflags)
```

Lets run it!

```
$ ./main
 ____          _    _                     _           ____                _
|  _ \  _   _ | |_ | |__    ___   _ __   (_) _ __    / ___|   _      _   | |
| |_) || | | || __|| '_ \  / _ \ | '_ \  | || '_ \  | |     _| |_  _| |_ | |
|  __/ | |_| || |_ | | | || (_) || | | | | || | | | | |___ |_   _||_   _||_|
|_|     \__, | \__||_| |_| \___/ |_| |_| |_||_| |_|  \____|  |_|    |_|  (_)
        |___/
```

------

A few notes:

- I hope this is obvious, but including `Python.h` and running `Py_Initialize` embeds the python interpreter in your C++ application. Python is pretty light-weight, so this is generally not a problem.

- This executable depends on python being installed on the system. In particular, the python shared libraries will need to be installed in a location where the loader can map them into the process at load-time. This is not a problem if python is installed on the target system in the usual way.

- The call to `initart_wrapper` is Python2 specific. If you are using Python3, you would do: `PyImport_AppendInittab("cymod", PyInit_art_wrapper);` prior to the `Py_Initialize` call. (the `art_wrapper` part of the function name is the cython module name, substitute your module name)

- In the Cython code, all the `public` function should return a C++ type and all the parameters should be C++ types. If you do not annotate the types, the type will default to `PyObject*` which introduces unnecessary complexity in your C++ code, especially if you are not already comfortable with the Python C-API.

- The `python-config` program is awesome. Use it to generate the libs/includes/compiler flags.
