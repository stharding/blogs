Using C/C++ libraries in python
===============================

In my last post, I introduced Cython as a tool to speed up your python code
by generating a native module. That's great if you have your solution already
prototyped in pure python, but sometimes you may want to take advantage of a
pre-existing library that solves your problem. If that library is written in
C or C++, it's pretty easy to construct a wrapper for the functionality you
are interested in and access it from your python code.

It turns out that this is such a common task, there are several ways to
accomplish this.

In this post, I'll only examine two technologies to do this wrapping:
Boost-Python and our old friend Cython.

Our Case Study:
---------------

We'll wrap a small C++ implementation of the [DES3](https://en.wikipedia.org/wiki/Triple_DES)
encryption algorithm found at the following github repository:
[https://github.com/fffaraz/cppDES](https://github.com/fffaraz/cppDES)
using Boost-Python and using Cython.

**NOTE**: I in no way endorse or validate the faithfulness of the
implementation in the repository. I chose it more or less at random and the
only metric I used to select it was the simplicity of the API. Please do not
use this to encrypt any information you care about without investigating the
validity of the implementation!

This implementation of DES3 provides a class `FileEncryption` with the
following API:

```c++
class FileEncryption
{
public:
    FileEncryption(ui64 key);
    int encrypt(string input, string output);
    int decrypt(string input, string output);
    int cipher (string input, string output, bool mode);
}
```

The constructor takes a hexidecimal key (`ui64` is typedefed to `uint64_t`).
The member methods `encrypt` and `decrypt` are implemented by calling
`cipher`. In our wrapper, we will only expose `encrypt` and `decrypt`. They
each take a filename `input` and `output`. Since `input` is a keyword in
Python, we'll want to change the parameter names.

The goal is to create a native module that allows code like:

```python
In [1]: from DES3 import FileEncryption

In [2]: f = FileEncryption(0xfeadface)

In [3]: f.encrypt(
   ...:     input_filename='input.txt',
   ...:     output_filename='cyphertext')
Out[3]: 0

In [4]: g = FileEncryption(0xfeadface)

In [5]: g.decrypt(
   ...:     input_filename='cyphertext',
   ...:     output_filename='output.txt')
Out[5]: 0

In [6]: with open('input.txt') as input_file:
   ...:     with open('output.txt') as output_file:
   ...:         input_text = input_file.readlines()
   ...:         output_text = output_file.readlines()
   ...:         assert(input_text == output_text)
   ...:
```

**Note**: We make a new instance to decrypt (`g`) because we need to reset
the random number generator.

Let's start by cloning the repository:

```bash
$ git clone https://github.com/fffaraz/cppDES.git
```

Now let's make a shared library:

```bash
$ cd cppDES/cppDES/
$ rm main.cpp
$ g++ -std=c++11 -fPIC -shared *.cpp -o libdes.so
```

**Note**: I deleted the `main.cpp` file because Boost-python will complain
about multiple definitions of the symbol `main`.

Boost-Python:
-------------

Boost-Python is a part of the [Boost](http://www.boost.org/) project. If you
use C++ and you've never encountered Boost, take some time to explore this
project. Boost has been a proving ground for modern C++ features. Many new
features in the standard library were implemented first in boost--
[this stack overflow answer](https://stackoverflow.com/a/8852421/2069572)
does a nice job detailing all the C++11 features that were first boost
features.

Boost-Python provides an easy way to generate python bindings for existing
C++ code.

The bindings for this library are quite simple:

For ease of presentation, let's build the Boost-python version at the same
directory level as the repo we checked out.

```bash
$ cd ../..
```

Now, in this directory, we make the following files:


```c++
// bp_des.cpp

#include <cstdint>
#include <boost/python.hpp>

#include "fileencryption.h"

namespace bp = boost::python;

BOOST_PYTHON_MODULE(DES3)
{
    bp::class_<FileEncryption>("FileEncryption", bp::init<uint64_t>(
        bp::arg("key")))

        .def("encrypt", &FileEncryption::encrypt,
            (bp::arg("input"), bp::arg("output")))

        .def("decrypt", &FileEncryption::decrypt,
            (bp::arg("input"), bp::arg("output")))
    ;
}
```

I used the following `CMake` file to build this:

```cmake
# CMakeLists.txt

CMAKE_MINIMUM_REQUIRED(VERSION 3.0.0 FATAL_ERROR)

project("DES3")
set(PROJECT_VERSION 1.0.0)

SET(BOOST_LIBS ${BOOST_LIBS}
    python
)

FIND_PACKAGE(Boost COMPONENTS ${BOOST_LIBS})
FIND_PACKAGE(PythonLibs 2.7 REQUIRED)

SET(CMAKE_CXX_STANDARD 11)

SET(LIBRARIES
    ${Boost_LIBRARIES}
    ${PYTHON_LIBRARIES}
)

INCLUDE_DIRECTORIES(
    .
    "cppDES/cppDES"
    ${Boost_INCLUDE_DIRS}
    ${PYTHON_INCLUDE_DIRS}
)

LINK_DIRECTORIES(
    ${Boost_LIBRARY_DIRS}
)
FILE(GLOB_RECURSE SOURCES "*.cpp")

PYTHON_ADD_MODULE(DES3 ${SOURCES})
TARGET_LINK_LIBRARIES(DES3 ${LIBRARIES} )
```

To build the wrapper:

```bash
$ mkdir build
$ cd build
$ cmake ..
$ make
```

This will make a file called `DES.so`. This is the native module--lets take it
for a spin. First, lets make a plain-text file to encrypt:

```bash
$ echo 'Such secrets!' > input.txt
```

Now, in an `ipython` session let's test the encryption:

```python
In [1]: from DES3 import FileEncryption

In [2]: f = FileEncryption(0xfeadface)

In [3]: f.encrypt(
   ...:     input_filename='input.txt',
   ...:     output_filename='cyphertext')
Out[3]: 0

In [4]: g = FileEncryption(0xfeadface)

In [5]: g.decrypt(
   ...:     input_filename='cyphertext',
   ...:     output_filename='output.txt')
Out[5]: 0

In [6]: with open('input.txt') as input_file:
   ...:     with open('output.txt') as output_file:
   ...:         input_text = input_file.readlines()
   ...:         output_text = output_file.readlines()
   ...:         assert(input_text == output_text)
   ...:
```

This should run without errors and the assertion should pass.

Now, lets look at the generated files and compare them to our input file:

```bash
$ cat input.txt | xxd
00000000: 5375 6368 2073 6563 7265 7473 210a       Such secrets!.

$ cat cyphertext | xxd
00000000: 4912 e0f2 85e9 4302 88f8 17d3 443a dbec  I.....C.....D:..

$ cat output.txt| xxd
00000000: 5375 6368 2073 6563 7265 7473 210a       Such secrets!.
```

Seems to be working!

Cython:
-------

For the Cython wrapper, We'll just add our `pyx` file and the `setup.py`
in the same directory as the C++ files in the DES3 repo:

```python
# distutils: language = c++
# distutils: include_dirs = .
# distutils: library_dirs = .
# distutils: libraries = des

from libc.stdint cimport uint64_t
from libcpp.string cimport string

cdef extern from "fileencryption.h":
    cdef cppclass _FileEncryption "FileEncryption":
        _FileEncryption(uint64_t key) except +
        int encrypt(string input, string output)
        int decrypt(string input, string output)


cdef class FileEncryption:
    cdef _FileEncryption* _this_ptr

    def __cinit__(self, uint64_t key):
        self._this_ptr = new _FileEncryption(key)

    def __dealloc(self):
        del self._this_ptr

    def encrypt(self, string input_filename, string output_filename):
        self._this_ptr.encrypt(input_filename, output_filename)

    def decrypt(self, string input_filename, string output_filename):
        self._this_ptr.decrypt(input_filename, output_filename)
```

built with this `setup.py`:

```python
from setuptools import setup, Extension
from Cython.Build import cythonize

setup(
    ext_modules=cythonize(
        Extension(
            'DES3',                   # the extension name
            sources=[
                'DES3.pyx',           # our Cython source
            ],
            language='c++',           # generate C++ code
            extra_compile_args=['-std=c++11'],
        ),
        compiler_directives={'embedsignature': True},
    )
)

```

This will also generate a file called `DES3.so` which we can import in
a python session or script. I won't bother pasting in the iPython session
I used to test my results using the Cython version because it is identical.

-----------------------------------------------------------------------------

Parting thoughts
----------------

I didn't go into any detail about the specific syntax or methodology
for either approach because you could fill a book going into all the details.
Seriously, there are some good books out there on this topic. Check them out.
I just finished reading [this one](https://www.amazon.com/Cython-Programmers-Kurt-W-Smith/dp/1491901551).

I'm really just documenting basic wrapping for my future use and to hopefully
spark interest in this topic.

That said, there are some very high level take aways I can leave you with.
I've spent quite a bit of time with both of these technologies and I think
that the major benefit of Boost-python is the brevity with which you can
wrap a C/C++ library. Boost-python also offers very fine grain control over
object lifetime and memory management problems.

Cython on the other hand requires you to both declare the C/C++ interface you
want to use in the rest of the Cython code *and* make an extension class which
holds references to the underlying C/C++ objects and also expose an interface
which can be accessed by Python code.

I've actually come to prefer Cython because I almost always want to modify
the interface to the API I'm exposing to make it more 'Pythonic'. Since Cython
is a superset of Python, I can do all that work in Python while also enjoying
the performance benefits offered by Cython.
