
Speed up Python with native modules using Cython
================================================

Hi folks! Todays post is all about one of the tools to speed up your
Python code. In my [post](https://blog.spawar.navy.mil/harding/2016/09/python-in-production.html)
about using Python in production, I mentioned several techniques to handle
Python "performance shortcomings". Arguably the easiest to use is Cython.

Cython can be installed with pip:

```bash
pip install cython
```

Cython is very close to a superset of Python syntax. That is to say, most
Python expressions are valid Cython. I'm not going to cover all the details
because I honestly don't know all of them, but the ones that I've come across
are some metaclass limitations and the apparent lack of support for decorators.
Cython is has a *very* active community of developers so eventually these will
probably be addressed.

What the heck is Cython anyway?
-------------------------------

Cython is a tool which takes Python like code and generates C (or C++) code
which uses the CPython API. When compiled as a shared object, this library
can be imported just like any standard Python module. For more details, read
it from the [horse's mouth](http://cython.readthedocs.io/en/latest/index.html).

Let's consider a Python module which exposes a function to compute Fibonacci
numbers. The implementation is terrible (exponential complexity) but that's
convenient for benchmarking purposes.

This is the function (I put it in a file called fib_python.py):

```python
def fib(n):
    return 1 if n <= 1 else fib(n - 1) + fib(n - 2)
```

Now let's make sure it works correctly:

```python
In [1]: from fib_python import fib

In [2]: [fib(n) for n in range(10)]
Out[2]: [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
```

Looks good to me.

Ok, now to establish a baseline performance metric:

```python
In [3]: %timeit fib(25)
10 loops, best of 3: 26.8 ms per loop
```

26.8 ms is a long time. The 'right' way to speed this up is to fix
the implementation (see my [memoization post](https://blog.spawar.navy.mil/harding/2016/05/python-memoization.html)),
but let's see what Cython can do for us.

As I said, most Python programs are valid Cython programs.
Let's transplant our function into a new file which we'll call `fib_cython.pyx`
(By convention, we use the pyx file extension for Cython source files.)

`fib_cython.pyx` contains:

```python
def fib(n):
    return 1 if n <= 1 else fib(n - 1) + fib(n - 2)
```

To compile, we'll use the `cythonize` command:

```bash
$ cythonize -i fib_cython.pyx
```

This produces the following output on my machine:

```bash
Compiling /Users/harding/Documents/blogs/cython/fib_cython.pyx because it changed.
[1/1] Cythonizing /Users/harding/Documents/blogs/cython/fib_cython.pyx
running build_ext
building 'fib_cython' extension
creating /Users/harding/Documents/blogs/cython/tmpVVAe2F/Users
creating /Users/harding/Documents/blogs/cython/tmpVVAe2F/Users/harding
creating /Users/harding/Documents/blogs/cython/tmpVVAe2F/Users/harding/Documents
creating /Users/harding/Documents/blogs/cython/tmpVVAe2F/Users/harding/Documents/blogs
creating /Users/harding/Documents/blogs/cython/tmpVVAe2F/Users/harding/Documents/blogs/cython
gcc -fno-strict-aliasing -I/Users/harding/anaconda/include -arch x86_64 -DNDEBUG -g -fwrapv -O3 -Wall -Wstrict-prototypes -I/Users/harding/anaconda/include/python2.7 -c /Users/harding/Documents/blogs/cython/fib_cython.c -o /Users/harding/Documents/blogs/cython/tmpVVAe2F/Users/harding/Documents/blogs/cython/fib_cython.o
gcc -bundle -undefined dynamic_lookup -L/Users/harding/anaconda/lib -arch x86_64 -arch x86_64 /Users/harding/Documents/blogs/cython/tmpVVAe2F/Users/harding/Documents/blogs/cython/fib_cython.o -L/Users/harding/anaconda/lib -o /Users/harding/Documents/blogs/cython/fib_cython.so
```

As you can see, the command made a C file which was then compiled using `gcc` and
produces an output file `fib_cython.so`. This is the native module which we can
import and use in Python. Let's give it a try:

```python
In [4]: from fib_cython import fib as fib_cython

In [5]: [fib_cython(n) for n in range(10)]
Out[5]: [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]

In [6]: %timeit fib_cython(25)
100 loops, best of 3: 8.7 ms per loop
```

Holy cow!!!! That's about three times faster *with no code changes!*

The only thing we had to do was compile it! This is super promising right?!

####It gets way better.####

One of the coolest tools that comes with Cython is the annotation tool:
(note that we use `cython` and not `cythonize` here.)

```bash
cython -a fib_cython.pyx
```
This produces an html file called `fib_cython.html` which visualizes the Cython
code and uses yellow highlighting with varying shades of yellow to indicate how
much C code is generated for the given line. If you click on the line it shows
you the C code associated with that line. You can use the brightness of the line
as a heuristic for where you should focus your attention to add type annotations
to speed thing up.

This is the rendered html for our Cython file:

------------------------------------------------------------------------------

<style type="text/css">

body.cython { font-family: courier; font-size: 12; }

.cython.tag  {  }
.cython.line { margin: 0em }
.cython.code { font-size: 9; color: #444444; display: none; margin: 0px 0px 0px 8px; border-left: 8px none; }

.cython.line .run { background-color: #B0FFB0; }
.cython.line .mis { background-color: #FFB0B0; }
.cython.code.run  { border-left: 8px solid #B0FFB0; }
.cython.code.mis  { border-left: 8px solid #FFB0B0; }

.cython.code .py_c_api  { color: red; }
.cython.code .py_macro_api  { color: #FF7000; }
.cython.code .pyx_c_api  { color: #FF3000; }
.cython.code .pyx_macro_api  { color: #FF7000; }
.cython.code .refnanny  { color: #FFA000; }
.cython.code .trace  { color: #FFA000; }
.cython.code .error_goto  { color: #FFA000; }

.cython.code .coerce  { color: #008000; border: 1px dotted #008000 }
.cython.code .py_attr { color: #FF0000; font-weight: bold; }
.cython.code .c_attr  { color: #0000FF; }
.cython.code .py_call { color: #FF0000; font-weight: bold; }
.cython.code .c_call  { color: #0000FF; }

.cython.score-0 {background-color: #FFFFff;}
.cython.score-1 {background-color: #FFFFe7;}
.cython.score-2 {background-color: #FFFFd4;}
.cython.score-3 {background-color: #FFFFc4;}
.cython.score-4 {background-color: #FFFFb6;}
.cython.score-5 {background-color: #FFFFaa;}
.cython.score-6 {background-color: #FFFF9f;}
.cython.score-7 {background-color: #FFFF96;}
.cython.score-8 {background-color: #FFFF8d;}
.cython.score-9 {background-color: #FFFF86;}
.cython.score-10 {background-color: #FFFF7f;}
.cython.score-11 {background-color: #FFFF79;}
.cython.score-12 {background-color: #FFFF73;}
.cython.score-13 {background-color: #FFFF6e;}
.cython.score-14 {background-color: #FFFF6a;}
.cython.score-15 {background-color: #FFFF66;}
.cython.score-16 {background-color: #FFFF62;}
.cython.score-17 {background-color: #FFFF5e;}
.cython.score-18 {background-color: #FFFF5b;}
.cython.score-19 {background-color: #FFFF57;}
.cython.score-20 {background-color: #FFFF55;}
.cython.score-21 {background-color: #FFFF52;}
.cython.score-22 {background-color: #FFFF4f;}
.cython.score-23 {background-color: #FFFF4d;}
.cython.score-24 {background-color: #FFFF4b;}
.cython.score-25 {background-color: #FFFF48;}
.cython.score-26 {background-color: #FFFF46;}
.cython.score-27 {background-color: #FFFF44;}
.cython.score-28 {background-color: #FFFF43;}
.cython.score-29 {background-color: #FFFF41;}
.cython.score-30 {background-color: #FFFF3f;}
.cython.score-31 {background-color: #FFFF3e;}
.cython.score-32 {background-color: #FFFF3c;}
.cython.score-33 {background-color: #FFFF3b;}
.cython.score-34 {background-color: #FFFF39;}
.cython.score-35 {background-color: #FFFF38;}
.cython.score-36 {background-color: #FFFF37;}
.cython.score-37 {background-color: #FFFF36;}
.cython.score-38 {background-color: #FFFF35;}
.cython.score-39 {background-color: #FFFF34;}
.cython.score-40 {background-color: #FFFF33;}
.cython.score-41 {background-color: #FFFF32;}
.cython.score-42 {background-color: #FFFF31;}
.cython.score-43 {background-color: #FFFF30;}
.cython.score-44 {background-color: #FFFF2f;}
.cython.score-45 {background-color: #FFFF2e;}
.cython.score-46 {background-color: #FFFF2d;}
.cython.score-47 {background-color: #FFFF2c;}
.cython.score-48 {background-color: #FFFF2b;}
.cython.score-49 {background-color: #FFFF2b;}
.cython.score-50 {background-color: #FFFF2a;}
.cython.score-51 {background-color: #FFFF29;}
.cython.score-52 {background-color: #FFFF29;}
.cython.score-53 {background-color: #FFFF28;}
.cython.score-54 {background-color: #FFFF27;}
.cython.score-55 {background-color: #FFFF27;}
.cython.score-56 {background-color: #FFFF26;}
.cython.score-57 {background-color: #FFFF26;}
.cython.score-58 {background-color: #FFFF25;}
.cython.score-59 {background-color: #FFFF24;}
.cython.score-60 {background-color: #FFFF24;}
.cython.score-61 {background-color: #FFFF23;}
.cython.score-62 {background-color: #FFFF23;}
.cython.score-63 {background-color: #FFFF22;}
.cython.score-64 {background-color: #FFFF22;}
.cython.score-65 {background-color: #FFFF22;}
.cython.score-66 {background-color: #FFFF21;}
.cython.score-67 {background-color: #FFFF21;}
.cython.score-68 {background-color: #FFFF20;}
.cython.score-69 {background-color: #FFFF20;}
.cython.score-70 {background-color: #FFFF1f;}
.cython.score-71 {background-color: #FFFF1f;}
.cython.score-72 {background-color: #FFFF1f;}
.cython.score-73 {background-color: #FFFF1e;}
.cython.score-74 {background-color: #FFFF1e;}
.cython.score-75 {background-color: #FFFF1e;}
.cython.score-76 {background-color: #FFFF1d;}
.cython.score-77 {background-color: #FFFF1d;}
.cython.score-78 {background-color: #FFFF1c;}
.cython.score-79 {background-color: #FFFF1c;}
.cython.score-80 {background-color: #FFFF1c;}
.cython.score-81 {background-color: #FFFF1c;}
.cython.score-82 {background-color: #FFFF1b;}
.cython.score-83 {background-color: #FFFF1b;}
.cython.score-84 {background-color: #FFFF1b;}
.cython.score-85 {background-color: #FFFF1a;}
.cython.score-86 {background-color: #FFFF1a;}
.cython.score-87 {background-color: #FFFF1a;}
.cython.score-88 {background-color: #FFFF1a;}
.cython.score-89 {background-color: #FFFF19;}
.cython.score-90 {background-color: #FFFF19;}
.cython.score-91 {background-color: #FFFF19;}
.cython.score-92 {background-color: #FFFF19;}
.cython.score-93 {background-color: #FFFF18;}
.cython.score-94 {background-color: #FFFF18;}
.cython.score-95 {background-color: #FFFF18;}
.cython.score-96 {background-color: #FFFF18;}
.cython.score-97 {background-color: #FFFF17;}
.cython.score-98 {background-color: #FFFF17;}
.cython.score-99 {background-color: #FFFF17;}
.cython.score-100 {background-color: #FFFF17;}
.cython.score-101 {background-color: #FFFF16;}
.cython.score-102 {background-color: #FFFF16;}
.cython.score-103 {background-color: #FFFF16;}
.cython.score-104 {background-color: #FFFF16;}
.cython.score-105 {background-color: #FFFF16;}
.cython.score-106 {background-color: #FFFF15;}
.cython.score-107 {background-color: #FFFF15;}
.cython.score-108 {background-color: #FFFF15;}
.cython.score-109 {background-color: #FFFF15;}
.cython.score-110 {background-color: #FFFF15;}
.cython.score-111 {background-color: #FFFF15;}
.cython.score-112 {background-color: #FFFF14;}
.cython.score-113 {background-color: #FFFF14;}
.cython.score-114 {background-color: #FFFF14;}
.cython.score-115 {background-color: #FFFF14;}
.cython.score-116 {background-color: #FFFF14;}
.cython.score-117 {background-color: #FFFF14;}
.cython.score-118 {background-color: #FFFF13;}
.cython.score-119 {background-color: #FFFF13;}
.cython.score-120 {background-color: #FFFF13;}
.cython.score-121 {background-color: #FFFF13;}
.cython.score-122 {background-color: #FFFF13;}
.cython.score-123 {background-color: #FFFF13;}
.cython.score-124 {background-color: #FFFF13;}
.cython.score-125 {background-color: #FFFF12;}
.cython.score-126 {background-color: #FFFF12;}
.cython.score-127 {background-color: #FFFF12;}
.cython.score-128 {background-color: #FFFF12;}
.cython.score-129 {background-color: #FFFF12;}
.cython.score-130 {background-color: #FFFF12;}
.cython.score-131 {background-color: #FFFF12;}
.cython.score-132 {background-color: #FFFF11;}
.cython.score-133 {background-color: #FFFF11;}
.cython.score-134 {background-color: #FFFF11;}
.cython.score-135 {background-color: #FFFF11;}
.cython.score-136 {background-color: #FFFF11;}
.cython.score-137 {background-color: #FFFF11;}
.cython.score-138 {background-color: #FFFF11;}
.cython.score-139 {background-color: #FFFF11;}
.cython.score-140 {background-color: #FFFF11;}
.cython.score-141 {background-color: #FFFF10;}
.cython.score-142 {background-color: #FFFF10;}
.cython.score-143 {background-color: #FFFF10;}
.cython.score-144 {background-color: #FFFF10;}
.cython.score-145 {background-color: #FFFF10;}
.cython.score-146 {background-color: #FFFF10;}
.cython.score-147 {background-color: #FFFF10;}
.cython.score-148 {background-color: #FFFF10;}
.cython.score-149 {background-color: #FFFF10;}
.cython.score-150 {background-color: #FFFF0f;}
.cython.score-151 {background-color: #FFFF0f;}
.cython.score-152 {background-color: #FFFF0f;}
.cython.score-153 {background-color: #FFFF0f;}
.cython.score-154 {background-color: #FFFF0f;}
.cython.score-155 {background-color: #FFFF0f;}
.cython.score-156 {background-color: #FFFF0f;}
.cython.score-157 {background-color: #FFFF0f;}
.cython.score-158 {background-color: #FFFF0f;}
.cython.score-159 {background-color: #FFFF0f;}
.cython.score-160 {background-color: #FFFF0f;}
.cython.score-161 {background-color: #FFFF0e;}
.cython.score-162 {background-color: #FFFF0e;}
.cython.score-163 {background-color: #FFFF0e;}
.cython.score-164 {background-color: #FFFF0e;}
.cython.score-165 {background-color: #FFFF0e;}
.cython.score-166 {background-color: #FFFF0e;}
.cython.score-167 {background-color: #FFFF0e;}
.cython.score-168 {background-color: #FFFF0e;}
.cython.score-169 {background-color: #FFFF0e;}
.cython.score-170 {background-color: #FFFF0e;}
.cython.score-171 {background-color: #FFFF0e;}
.cython.score-172 {background-color: #FFFF0e;}
.cython.score-173 {background-color: #FFFF0d;}
.cython.score-174 {background-color: #FFFF0d;}
.cython.score-175 {background-color: #FFFF0d;}
.cython.score-176 {background-color: #FFFF0d;}
.cython.score-177 {background-color: #FFFF0d;}
.cython.score-178 {background-color: #FFFF0d;}
.cython.score-179 {background-color: #FFFF0d;}
.cython.score-180 {background-color: #FFFF0d;}
.cython.score-181 {background-color: #FFFF0d;}
.cython.score-182 {background-color: #FFFF0d;}
.cython.score-183 {background-color: #FFFF0d;}
.cython.score-184 {background-color: #FFFF0d;}
.cython.score-185 {background-color: #FFFF0d;}
.cython.score-186 {background-color: #FFFF0d;}
.cython.score-187 {background-color: #FFFF0c;}
.cython.score-188 {background-color: #FFFF0c;}
.cython.score-189 {background-color: #FFFF0c;}
.cython.score-190 {background-color: #FFFF0c;}
.cython.score-191 {background-color: #FFFF0c;}
.cython.score-192 {background-color: #FFFF0c;}
.cython.score-193 {background-color: #FFFF0c;}
.cython.score-194 {background-color: #FFFF0c;}
.cython.score-195 {background-color: #FFFF0c;}
.cython.score-196 {background-color: #FFFF0c;}
.cython.score-197 {background-color: #FFFF0c;}
.cython.score-198 {background-color: #FFFF0c;}
.cython.score-199 {background-color: #FFFF0c;}
.cython.score-200 {background-color: #FFFF0c;}
.cython.score-201 {background-color: #FFFF0c;}
.cython.score-202 {background-color: #FFFF0c;}
.cython.score-203 {background-color: #FFFF0b;}
.cython.score-204 {background-color: #FFFF0b;}
.cython.score-205 {background-color: #FFFF0b;}
.cython.score-206 {background-color: #FFFF0b;}
.cython.score-207 {background-color: #FFFF0b;}
.cython.score-208 {background-color: #FFFF0b;}
.cython.score-209 {background-color: #FFFF0b;}
.cython.score-210 {background-color: #FFFF0b;}
.cython.score-211 {background-color: #FFFF0b;}
.cython.score-212 {background-color: #FFFF0b;}
.cython.score-213 {background-color: #FFFF0b;}
.cython.score-214 {background-color: #FFFF0b;}
.cython.score-215 {background-color: #FFFF0b;}
.cython.score-216 {background-color: #FFFF0b;}
.cython.score-217 {background-color: #FFFF0b;}
.cython.score-218 {background-color: #FFFF0b;}
.cython.score-219 {background-color: #FFFF0b;}
.cython.score-220 {background-color: #FFFF0b;}
.cython.score-221 {background-color: #FFFF0b;}
.cython.score-222 {background-color: #FFFF0a;}
.cython.score-223 {background-color: #FFFF0a;}
.cython.score-224 {background-color: #FFFF0a;}
.cython.score-225 {background-color: #FFFF0a;}
.cython.score-226 {background-color: #FFFF0a;}
.cython.score-227 {background-color: #FFFF0a;}
.cython.score-228 {background-color: #FFFF0a;}
.cython.score-229 {background-color: #FFFF0a;}
.cython.score-230 {background-color: #FFFF0a;}
.cython.score-231 {background-color: #FFFF0a;}
.cython.score-232 {background-color: #FFFF0a;}
.cython.score-233 {background-color: #FFFF0a;}
.cython.score-234 {background-color: #FFFF0a;}
.cython.score-235 {background-color: #FFFF0a;}
.cython.score-236 {background-color: #FFFF0a;}
.cython.score-237 {background-color: #FFFF0a;}
.cython.score-238 {background-color: #FFFF0a;}
.cython.score-239 {background-color: #FFFF0a;}
.cython.score-240 {background-color: #FFFF0a;}
.cython.score-241 {background-color: #FFFF0a;}
.cython.score-242 {background-color: #FFFF0a;}
.cython.score-243 {background-color: #FFFF0a;}
.cython.score-244 {background-color: #FFFF0a;}
.cython.score-245 {background-color: #FFFF0a;}
.cython.score-246 {background-color: #FFFF09;}
.cython.score-247 {background-color: #FFFF09;}
.cython.score-248 {background-color: #FFFF09;}
.cython.score-249 {background-color: #FFFF09;}
.cython.score-250 {background-color: #FFFF09;}
.cython.score-251 {background-color: #FFFF09;}
.cython.score-252 {background-color: #FFFF09;}
.cython.score-253 {background-color: #FFFF09;}
.cython.score-254 {background-color: #FFFF09;}
.cython .hll { background-color: #ffffcc }
.cython  { background: #f8f8f8; }
.cython .c { color: #408080; font-style: italic } /* Comment */
.cython .err { border: 1px solid #FF0000 } /* Error */
.cython .k { color: #008000; font-weight: bold } /* Keyword */
.cython .o { color: #666666 } /* Operator */
.cython .ch { color: #408080; font-style: italic } /* Comment.Hashbang */
.cython .cm { color: #408080; font-style: italic } /* Comment.Multiline */
.cython .cp { color: #BC7A00 } /* Comment.Preproc */
.cython .cpf { color: #408080; font-style: italic } /* Comment.PreprocFile */
.cython .c1 { color: #408080; font-style: italic } /* Comment.Single */
.cython .cs { color: #408080; font-style: italic } /* Comment.Special */
.cython .gd { color: #A00000 } /* Generic.Deleted */
.cython .ge { font-style: italic } /* Generic.Emph */
.cython .gr { color: #FF0000 } /* Generic.Error */
.cython .gh { color: #000080; font-weight: bold } /* Generic.Heading */
.cython .gi { color: #00A000 } /* Generic.Inserted */
.cython .go { color: #888888 } /* Generic.Output */
.cython .gp { color: #000080; font-weight: bold } /* Generic.Prompt */
.cython .gs { font-weight: bold } /* Generic.Strong */
.cython .gu { color: #800080; font-weight: bold } /* Generic.Subheading */
.cython .gt { color: #0044DD } /* Generic.Traceback */
.cython .kc { color: #008000; font-weight: bold } /* Keyword.Constant */
.cython .kd { color: #008000; font-weight: bold } /* Keyword.Declaration */
.cython .kn { color: #008000; font-weight: bold } /* Keyword.Namespace */
.cython .kp { color: #008000 } /* Keyword.Pseudo */
.cython .kr { color: #008000; font-weight: bold } /* Keyword.Reserved */
.cython .kt { color: #B00040 } /* Keyword.Type */
.cython .m { color: #666666 } /* Literal.Number */
.cython .s { color: #BA2121 } /* Literal.String */
.cython .na { color: #7D9029 } /* Name.Attribute */
.cython .nb { color: #008000 } /* Name.Builtin */
.cython .nc { color: #0000FF; font-weight: bold } /* Name.Class */
.cython .no { color: #880000 } /* Name.Constant */
.cython .nd { color: #AA22FF } /* Name.Decorator */
.cython .ni { color: #999999; font-weight: bold } /* Name.Entity */
.cython .ne { color: #D2413A; font-weight: bold } /* Name.Exception */
.cython .nf { color: #0000FF } /* Name.Function */
.cython .nl { color: #A0A000 } /* Name.Label */
.cython .nn { color: #0000FF; font-weight: bold } /* Name.Namespace */
.cython .nt { color: #008000; font-weight: bold } /* Name.Tag */
.cython .nv { color: #19177C } /* Name.Variable */
.cython .ow { color: #AA22FF; font-weight: bold } /* Operator.Word */
.cython .w { color: #bbbbbb } /* Text.Whitespace */
.cython .mb { color: #666666 } /* Literal.Number.Bin */
.cython .mf { color: #666666 } /* Literal.Number.Float */
.cython .mh { color: #666666 } /* Literal.Number.Hex */
.cython .mi { color: #666666 } /* Literal.Number.Integer */
.cython .mo { color: #666666 } /* Literal.Number.Oct */
.cython .sb { color: #BA2121 } /* Literal.String.Backtick */
.cython .sc { color: #BA2121 } /* Literal.String.Char */
.cython .sd { color: #BA2121; font-style: italic } /* Literal.String.Doc */
.cython .s2 { color: #BA2121 } /* Literal.String.Double */
.cython .se { color: #BB6622; font-weight: bold } /* Literal.String.Escape */
.cython .sh { color: #BA2121 } /* Literal.String.Heredoc */
.cython .si { color: #BB6688; font-weight: bold } /* Literal.String.Interpol */
.cython .sx { color: #008000 } /* Literal.String.Other */
.cython .sr { color: #BB6688 } /* Literal.String.Regex */
.cython .s1 { color: #BA2121 } /* Literal.String.Single */
.cython .ss { color: #19177C } /* Literal.String.Symbol */
.cython .bp { color: #008000 } /* Name.Builtin.Pseudo */
.cython .vc { color: #19177C } /* Name.Variable.Class */
.cython .vg { color: #19177C } /* Name.Variable.Global */
.cython .vi { color: #19177C } /* Name.Variable.Instance */
.cython .il { color: #666666 } /* Literal.Number.Integer.Long */
</style>
<script>
    function toggleDiv(id) {
        theDiv = id.nextElementSibling
        if (theDiv.style.display != 'block') theDiv.style.display = 'block';
        else theDiv.style.display = 'none';
    }
</script>
<div class="cython">
<p><span style="border-bottom: solid 1px grey;">Generated by Cython 0.25.2</span></p>
<p>
<span style="background-color: #FFFF00">Yellow lines</span> hint at Python interaction.<br />
    Click on a line that starts with a "+" to see the C code that Cython generated for it.
</p>
<p>Raw output: <pre>fib_cython.c</pre></p>
<div class="cython"><pre class="cython line score-0">&#xA0;<span class="">1</span>: </pre>
<pre class="cython line score-20" onclick='toggleDiv(this)'>+<span class="">2</span>: <span class="k">def</span> <span class="nf">fib</span><span class="p">(</span><span class="n">n</span><span class="p">):</span></pre>
<pre class='cython code score-20 '>/* Python wrapper */
static PyObject *__pyx_pw_10fib_cython_1fib(PyObject *__pyx_self, PyObject *__pyx_v_n); /*proto*/
static PyMethodDef __pyx_mdef_10fib_cython_1fib = {"fib", (PyCFunction)__pyx_pw_10fib_cython_1fib, METH_O, 0};
static PyObject *__pyx_pw_10fib_cython_1fib(PyObject *__pyx_self, PyObject *__pyx_v_n) {
  PyObject *__pyx_r = 0;
  <span class='refnanny'>__Pyx_RefNannyDeclarations</span>
  <span class='refnanny'>__Pyx_RefNannySetupContext</span>("fib (wrapper)", 0);
  __pyx_r = __pyx_pf_10fib_cython_fib(__pyx_self, ((PyObject *)__pyx_v_n));

  /* function exit code */
  <span class='refnanny'>__Pyx_RefNannyFinishContext</span>();
  return __pyx_r;
}

static PyObject *__pyx_pf_10fib_cython_fib(CYTHON_UNUSED PyObject *__pyx_self, PyObject *__pyx_v_n) {
  PyObject *__pyx_r = NULL;
  <span class='refnanny'>__Pyx_RefNannyDeclarations</span>
  <span class='refnanny'>__Pyx_RefNannySetupContext</span>("fib", 0);
/* … */
  /* function exit code */
  __pyx_L1_error:;
  <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_1);
  <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_2);
  <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_4);
  <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_5);
  <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_6);
  <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_7);
  <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_8);
  <span class='pyx_c_api'>__Pyx_AddTraceback</span>("fib_cython.fib", __pyx_clineno, __pyx_lineno, __pyx_filename);
  __pyx_r = NULL;
  __pyx_L0:;
  <span class='refnanny'>__Pyx_XGIVEREF</span>(__pyx_r);
  <span class='refnanny'>__Pyx_RefNannyFinishContext</span>();
  return __pyx_r;
}
/* … */
  __pyx_tuple_ = <span class='py_c_api'>PyTuple_Pack</span>(1, __pyx_n_s_n); if (unlikely(!__pyx_tuple_)) __PYX_ERR(0, 2, __pyx_L1_error)
  <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_tuple_);
  <span class='refnanny'>__Pyx_GIVEREF</span>(__pyx_tuple_);
/* … */
  __pyx_t_1 = PyCFunction_NewEx(&amp;__pyx_mdef_10fib_cython_1fib, NULL, __pyx_n_s_fib_cython); if (unlikely(!__pyx_t_1)) __PYX_ERR(0, 2, __pyx_L1_error)
  <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_1);
  if (<span class='py_c_api'>PyDict_SetItem</span>(__pyx_d, __pyx_n_s_fib, __pyx_t_1) &lt; 0) __PYX_ERR(0, 2, __pyx_L1_error)
  <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_1); __pyx_t_1 = 0;
</pre><pre class="cython line score-103" onclick='toggleDiv(this)'>+<span class="">3</span>:     <span class="k">return</span> <span class="mf">1</span> <span class="k">if</span> <span class="n">n</span> <span class="o">&lt;=</span> <span class="mf">1</span> <span class="k">else</span> <span class="n">fib</span><span class="p">(</span><span class="n">n</span> <span class="o">-</span> <span class="mf">1</span><span class="p">)</span> <span class="o">+</span> <span class="n">fib</span><span class="p">(</span><span class="n">n</span> <span class="o">-</span> <span class="mf">2</span><span class="p">)</span></pre>
<pre class='cython code score-103 '>  <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_r);
  __pyx_t_2 = <span class='py_c_api'>PyObject_RichCompare</span>(__pyx_v_n, __pyx_int_1, Py_LE); <span class='refnanny'>__Pyx_XGOTREF</span>(__pyx_t_2); if (unlikely(!__pyx_t_2)) __PYX_ERR(0, 3, __pyx_L1_error)
  __pyx_t_3 = <span class='pyx_c_api'>__Pyx_PyObject_IsTrue</span>(__pyx_t_2); if (unlikely(__pyx_t_3 &lt; 0)) __PYX_ERR(0, 3, __pyx_L1_error)
  <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_2); __pyx_t_2 = 0;
  if (__pyx_t_3) {
    <span class='pyx_macro_api'>__Pyx_INCREF</span>(__pyx_int_1);
    __pyx_t_1 = __pyx_int_1;
  } else {
    __pyx_t_4 = <span class='pyx_c_api'>__Pyx_GetModuleGlobalName</span>(__pyx_n_s_fib); if (unlikely(!__pyx_t_4)) __PYX_ERR(0, 3, __pyx_L1_error)
    <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_4);
    __pyx_t_5 = <span class='pyx_c_api'>__Pyx_PyInt_SubtractObjC</span>(__pyx_v_n, __pyx_int_1, 1, 0); if (unlikely(!__pyx_t_5)) __PYX_ERR(0, 3, __pyx_L1_error)
    <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_5);
    __pyx_t_6 = NULL;
    if (CYTHON_UNPACK_METHODS &amp;&amp; unlikely(<span class='py_c_api'>PyMethod_Check</span>(__pyx_t_4))) {
      __pyx_t_6 = <span class='py_macro_api'>PyMethod_GET_SELF</span>(__pyx_t_4);
      if (likely(__pyx_t_6)) {
        PyObject* function = <span class='py_macro_api'>PyMethod_GET_FUNCTION</span>(__pyx_t_4);
        <span class='pyx_macro_api'>__Pyx_INCREF</span>(__pyx_t_6);
        <span class='pyx_macro_api'>__Pyx_INCREF</span>(function);
        <span class='pyx_macro_api'>__Pyx_DECREF_SET</span>(__pyx_t_4, function);
      }
    }
    if (!__pyx_t_6) {
      __pyx_t_2 = <span class='pyx_c_api'>__Pyx_PyObject_CallOneArg</span>(__pyx_t_4, __pyx_t_5); if (unlikely(!__pyx_t_2)) __PYX_ERR(0, 3, __pyx_L1_error)
      <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_5); __pyx_t_5 = 0;
      <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_2);
    } else {
      #if CYTHON_FAST_PYCALL
      if (<span class='py_c_api'>PyFunction_Check</span>(__pyx_t_4)) {
        PyObject *__pyx_temp[2] = {__pyx_t_6, __pyx_t_5};
        __pyx_t_2 = <span class='pyx_c_api'>__Pyx_PyFunction_FastCall</span>(__pyx_t_4, __pyx_temp+1-1, 1+1); if (unlikely(!__pyx_t_2)) __PYX_ERR(0, 3, __pyx_L1_error)
        <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_6); __pyx_t_6 = 0;
        <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_2);
        <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_5); __pyx_t_5 = 0;
      } else
      #endif
      #if CYTHON_FAST_PYCCALL
      if (<span class='pyx_c_api'>__Pyx_PyFastCFunction_Check</span>(__pyx_t_4)) {
        PyObject *__pyx_temp[2] = {__pyx_t_6, __pyx_t_5};
        __pyx_t_2 = <span class='pyx_c_api'>__Pyx_PyCFunction_FastCall</span>(__pyx_t_4, __pyx_temp+1-1, 1+1); if (unlikely(!__pyx_t_2)) __PYX_ERR(0, 3, __pyx_L1_error)
        <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_6); __pyx_t_6 = 0;
        <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_2);
        <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_5); __pyx_t_5 = 0;
      } else
      #endif
      {
        __pyx_t_7 = <span class='py_c_api'>PyTuple_New</span>(1+1); if (unlikely(!__pyx_t_7)) __PYX_ERR(0, 3, __pyx_L1_error)
        <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_7);
        <span class='refnanny'>__Pyx_GIVEREF</span>(__pyx_t_6); <span class='py_macro_api'>PyTuple_SET_ITEM</span>(__pyx_t_7, 0, __pyx_t_6); __pyx_t_6 = NULL;
        <span class='refnanny'>__Pyx_GIVEREF</span>(__pyx_t_5);
        <span class='py_macro_api'>PyTuple_SET_ITEM</span>(__pyx_t_7, 0+1, __pyx_t_5);
        __pyx_t_5 = 0;
        __pyx_t_2 = <span class='pyx_c_api'>__Pyx_PyObject_Call</span>(__pyx_t_4, __pyx_t_7, NULL); if (unlikely(!__pyx_t_2)) __PYX_ERR(0, 3, __pyx_L1_error)
        <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_2);
        <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_7); __pyx_t_7 = 0;
      }
    }
    <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_4); __pyx_t_4 = 0;
    __pyx_t_7 = <span class='pyx_c_api'>__Pyx_GetModuleGlobalName</span>(__pyx_n_s_fib); if (unlikely(!__pyx_t_7)) __PYX_ERR(0, 3, __pyx_L1_error)
    <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_7);
    __pyx_t_5 = <span class='pyx_c_api'>__Pyx_PyInt_SubtractObjC</span>(__pyx_v_n, __pyx_int_2, 2, 0); if (unlikely(!__pyx_t_5)) __PYX_ERR(0, 3, __pyx_L1_error)
    <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_5);
    __pyx_t_6 = NULL;
    if (CYTHON_UNPACK_METHODS &amp;&amp; unlikely(<span class='py_c_api'>PyMethod_Check</span>(__pyx_t_7))) {
      __pyx_t_6 = <span class='py_macro_api'>PyMethod_GET_SELF</span>(__pyx_t_7);
      if (likely(__pyx_t_6)) {
        PyObject* function = <span class='py_macro_api'>PyMethod_GET_FUNCTION</span>(__pyx_t_7);
        <span class='pyx_macro_api'>__Pyx_INCREF</span>(__pyx_t_6);
        <span class='pyx_macro_api'>__Pyx_INCREF</span>(function);
        <span class='pyx_macro_api'>__Pyx_DECREF_SET</span>(__pyx_t_7, function);
      }
    }
    if (!__pyx_t_6) {
      __pyx_t_4 = <span class='pyx_c_api'>__Pyx_PyObject_CallOneArg</span>(__pyx_t_7, __pyx_t_5); if (unlikely(!__pyx_t_4)) __PYX_ERR(0, 3, __pyx_L1_error)
      <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_5); __pyx_t_5 = 0;
      <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_4);
    } else {
      #if CYTHON_FAST_PYCALL
      if (<span class='py_c_api'>PyFunction_Check</span>(__pyx_t_7)) {
        PyObject *__pyx_temp[2] = {__pyx_t_6, __pyx_t_5};
        __pyx_t_4 = <span class='pyx_c_api'>__Pyx_PyFunction_FastCall</span>(__pyx_t_7, __pyx_temp+1-1, 1+1); if (unlikely(!__pyx_t_4)) __PYX_ERR(0, 3, __pyx_L1_error)
        <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_6); __pyx_t_6 = 0;
        <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_4);
        <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_5); __pyx_t_5 = 0;
      } else
      #endif
      #if CYTHON_FAST_PYCCALL
      if (<span class='pyx_c_api'>__Pyx_PyFastCFunction_Check</span>(__pyx_t_7)) {
        PyObject *__pyx_temp[2] = {__pyx_t_6, __pyx_t_5};
        __pyx_t_4 = <span class='pyx_c_api'>__Pyx_PyCFunction_FastCall</span>(__pyx_t_7, __pyx_temp+1-1, 1+1); if (unlikely(!__pyx_t_4)) __PYX_ERR(0, 3, __pyx_L1_error)
        <span class='pyx_macro_api'>__Pyx_XDECREF</span>(__pyx_t_6); __pyx_t_6 = 0;
        <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_4);
        <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_5); __pyx_t_5 = 0;
      } else
      #endif
      {
        __pyx_t_8 = <span class='py_c_api'>PyTuple_New</span>(1+1); if (unlikely(!__pyx_t_8)) __PYX_ERR(0, 3, __pyx_L1_error)
        <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_8);
        <span class='refnanny'>__Pyx_GIVEREF</span>(__pyx_t_6); <span class='py_macro_api'>PyTuple_SET_ITEM</span>(__pyx_t_8, 0, __pyx_t_6); __pyx_t_6 = NULL;
        <span class='refnanny'>__Pyx_GIVEREF</span>(__pyx_t_5);
        <span class='py_macro_api'>PyTuple_SET_ITEM</span>(__pyx_t_8, 0+1, __pyx_t_5);
        __pyx_t_5 = 0;
        __pyx_t_4 = <span class='pyx_c_api'>__Pyx_PyObject_Call</span>(__pyx_t_7, __pyx_t_8, NULL); if (unlikely(!__pyx_t_4)) __PYX_ERR(0, 3, __pyx_L1_error)
        <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_4);
        <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_8); __pyx_t_8 = 0;
      }
    }
    <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_7); __pyx_t_7 = 0;
    __pyx_t_7 = <span class='py_c_api'>PyNumber_Add</span>(__pyx_t_2, __pyx_t_4); if (unlikely(!__pyx_t_7)) __PYX_ERR(0, 3, __pyx_L1_error)
    <span class='refnanny'>__Pyx_GOTREF</span>(__pyx_t_7);
    <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_2); __pyx_t_2 = 0;
    <span class='pyx_macro_api'>__Pyx_DECREF</span>(__pyx_t_4); __pyx_t_4 = 0;
    __pyx_t_1 = __pyx_t_7;
    __pyx_t_7 = 0;
  }
  __pyx_r = __pyx_t_1;
  __pyx_t_1 = 0;
  goto __pyx_L0;
</pre></div></div>

------------------------------------------------------------------------------

This is where the Cython specific syntax comes in. In Python, *everything* is an
object. From a C API perspective, that means that everything is an instance of
the `PyObject` struct. Since every Python operation involves interfacing with
the `PyObject` at runtime there is a bit of overhead that you can eliminate.

Cython allows you to specify the types of variables, function return values etc.
which allows the resulting C code to use those types directly without any of
the `PyObject` boxing.

One other super important point. Cython also provides alternatives for the `def`
keyword: `cdef` and `cpdef`. `cdef` indicates that the function will only be
called from within Cython and can use the C calling convention instead of the
Python calling convention. This can be a *huge* speedup for problems which
involve many function calls. `cpdef` provides a compromise. Functions declared
as `cpdef` end up generating two versions. One with the C calling convention and
one with the Python calling convention. Calls from Cython code will use the c
version and calls from Python code will use the Python convention.

Let's try that out. We'll make a new file called `fib_cpdef.pyx`:

```
cpdef fib(n):
    return 1 if n <= 1 else fib(n - 1) + fib(n - 2)
```

Here's the results:

```
In [7]: from fib_cpdef import fib as fib_cpdef

In [8]: [fib_cpdef(n) for n in range(10)]
Out[8]: [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]

In [9]: %timeit fib_cpdef(25)
100 loops, best of 3: 5.35 ms per loop
```

Yeeeeehaw! That's one and a half times faster yet!

Now let's annotate the types. We'll use a file called `fib_typed.pyx`:

**EDIT:** Thanks @jreeder, I forgot to include the typed code:

```python
cpdef int fib(int n):
    return 1 if n <= 1 else fib(n - 1) + fib(n - 2)
```

The only additions are the `int` specifying the return type
and the `int` specifying the type of the parameter `n`.

**End Edit**

```
In [10]: from fib_typed import fib as fib_typed

In [11]: [fib_typed(n) for n in range(10)]
Out[11]: [1, 1, 2, 3, 5, 8, 13, 21, 34, 55]

In [12]: %timeit fib_typed(25)
1000 loops, best of 3: 255 µs per loop
```

Dear God. That's more than twenty times faster than the `cpdef` version!

The final version is 105 times faster than the original Python version.

The real test is to compare this performance to an actual hand-written c
implementation. Let's write a little C library to test against (fib.c):

```c
int fib(int n)
{
    if(n <= 1) {
        return 1;
    }
    return fib(n - 1) + fib(n - 2);
}
```

Make the lib by doing:

```bash
gcc -O3 -c fib.c
gcc -O3 -shared -fPIC fib.o -o fib.so
```

This produces `fib.so` which is a standard C dynamically linked library
(i.e. *not* a Python native module)

Let's use the Python C foreign function interface to test performance:

```python
In [13]: from ctypes import CDLL

In [14]: fib_lib = CDLL('fib.so')

In [15]: fib_c = fib_lib.fib

In [16]: %timeit fib_c(25)
1000 loops, best of 3: 255 µs per loop
```

Hooray! We got the exact same performance as a straight C library compiled
with `-O3`!

I think this is really amazing. Cython blends the fantastic syntax and rapid
development features of Python with the performance of raw C.

I've barely scratched the surface of what's possible with Cython, but
hopefully I've inspired you to play around with this fantastic tool and
hopefully you'll consider using Cython instead of porting perfectly good
Python code to C/C++.
