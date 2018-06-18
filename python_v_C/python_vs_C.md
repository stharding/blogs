I Recently had an email exchange with someone regarding the use of python in production.
This person strongly believes that the performance of python is so much worse than Java/C++
that he doesn't recommend using it in an actual system.

I completely disagree. What follows is largely lifted from my side of the conversation.

---------------------------------------------------------------------------------

Some folks are concerned that python may not be performant enough to be used in production code.

In fact, there is some validity to the concern when talking about CPU bound code (code that is computational in nature rather than primarily dealing with IO).

The reason for concern with CPU bound tasks is the Global Interpreter Lock (GIL). Python actually uses POSIX threads and allows the OS to manage the threads--very much like C, C++, Java, etc. However, the GIL prevents more than one thread from executing python bytecode at the same time. Basically what that means is that Python's threading model gives you concurrency, but not parallelism. So, if you were implementing a parallelizable CPU intensive task, you would not be able to use multiple cores to speed up the computation using Python's threading module.

That is not to say that cpu bound work can't be done well in Python. There are two main ways to do cpu bound work efficiently in Python.

The easiest is to use multiple processes. This sounds sort of awful at first, but the multiprocessing [1] module provides exactly the same interface as the threading module so from the developer's point of view it's pretty much just like threading.

The second main way is to use native modules [2]. There is a C API to write modules in native code (usually C or  C++ but it could be done with anything that can inter-operate with C) which can be compiled into a library that Python can import in exactly the same way as a plain Python module. In the native code, you can release the GIL and perform your cpu bound work in parallel.

If you google "best language for data science" [3] or "best language for machine learning" [4] you will find that R and Python are the top two. Data science/machine learning tasks are essentially the poster child of cpu bound work. The reason that Python is favored over C/C++/Java is that with the readily available and excellent native modules (such as Numpy [5] and SciPy [6]) performance is not an issue at all. Add to that the ease of development and the resulting clear and concise code, it shouldn't be surprising that Python is quite popular.

Writing native modules using just the Python API can be a bit tedious. Fortunately this is a solved problem for most use cases. Cython [7] lets you write Python code and optionally annotate types. The Cython code then gets transformed into C code which gets compiled into a native module that you can import into Python like any other module. 100x speedups are typical.

In my project, we wrote a native Python module to interact with DDS [8]. We use Boost-Python [9] which is part of the Boost framework [10]. Boost-Python lets you wrap existing C++ code and expose it to Python as a native module.

The GIL is actually automatically released for IO bound tasks. This is because the core Python library IO functions are all written in C and release the GIL while awaiting a result. For work that is not IO bound, the plain old threading module works just fine. The threading module is all implemented in C and has comparable performance to C/C++/Java for network IO tasks.

Sometimes just talking about this stuff doesn't do much to convince people, so I decided to generate some numbers. Numbers convince people right?

I hacked together a quick benchmark to exercise C and Python on equivalent tasks.
I wrote a python UDP server and an equivalent C UDP server which are both expecting
large packets (10 kilobytes) at a high data rate (100 Hz).

Each packet sent to the server has a timestamp and a 10KB payload. When the server
receives the packet, it does some cpu bound work. I decided that uppercasing the
entire payload was a fair proxy for real work since every byte of the payload gets
processed. Once that work is done, a new timestamp is generated and the difference
between the timestamp and the timestamp in the packet is computed. These
timestamps and the payload are stored in an in-memory data structure.

After 1000 packets have been processed, a file is generated containing all of data
that has been computed along with two statistics.

1) the average difference between the packet timestamp and the timestamp that was
generated after receiving and processing the payload.

2) the median value of the difference between the packet timestamp and the
timestamp that was generated after receiving and processing the payload.

What I found was sort of surprising. The average value for the C server was about
two orders of magnitude slower than the python version. However, the median value
was similar but a bit faster.

Here are some typical results running on my laptop:

C:

average difference: 0.051660
median difference: 0.000374

Python:

mean difference: 0.000891726970673
median difference: 0.000895977020264

If you look at the generated file for the C version you will find some outliers
that are bringing the average down. I'm sure that the C version could be fixed to
be faster than the Python version for both average and median.

However, I guess the point that I am making is that the C version is only faster
by about 0.4 milliseconds in the median case. The fact that the average case is
slower than Python is simply indicative of the fact that while it it possible to
write extremely fast code in C, it is just as likely to be slower because it's
harder to write correctly.

The python standard library is able to stand up to C performance for network IO
because it *is* C network IO. The implementations of those functions are all native.

I hosted this experiment on github. Please feel free to take a look.

It's at [`https://github.com/stharding/c_vs_python_net_test`](https://github.com/stharding/c_vs_python_net_test)

--------------------------------------------------------------------------------

Ok, rant over.

So, do you (or would you) use python in production code?

Leave a comment and let me know.

References:

\[1]:  [`https://docs.python.org/2/library/multiprocessing.html`](https://docs.python.org/2/library/multiprocessing.html) <br/>
\[2]:  [`https://docs.python.org/2/extending/extending.html`](https://docs.python.org/2/extending/extending.html) <br/>
\[3]:  [`https://www.google.com/search?q=best%20language%20for%20data%20science`](https://www.google.com/search?q=best%20language%20for%20data%20science) <br/>
\[4]:  [`https://www.google.com/search?q=best%20language%20for%20machine%20learning`](https://www.google.com/search?q=best%20language%20for%20machine%20learning) <br/>
\[5]:  [`http://www.numpy.org/`](http://www.numpy.org/) <br/>
\[6]:  [`https://www.scipy.org/`](https://www.scipy.org/) <br/>
\[7]:  [`http://cython.org/`](http://cython.org/) <br/>
\[8]:  [`http://portals.omg.org/dds/`](http://portals.omg.org/dds/) <br>
\[9]:  [`http://www.boost.org/doc/libs/1_61_0/libs/python/doc/html/index.html`](http://www.boost.org/doc/libs/1_61_0/libs/python/doc/html/index.html) <br/>
\[10]: [`http://www.boost.org`](http://www.boost.org) <br/>
