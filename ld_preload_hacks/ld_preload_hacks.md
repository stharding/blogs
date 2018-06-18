`LD_PRELOAD` hacks
==================

This post is a bit of a departure from my normal [Python](https://www.python.org/) evangelism. Instead, I'm going back to my `C` roots and exploring the somewhat mystical world of the `LD_PRELOAD` environment variable.

TL;DR: `LD_PELOAD` is a (linux) variable you can set to hijack the symbol resolution order for linked libraries.

First lets consider a basic use case.

The simplest and easiest thing to do with `LD_PRELOAD` is to replace the implementation of a function defined in a library that an application links against.

Consider this simple program which prints out some random numbers:

```C
// print_rand.c

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main() {
    srand(time(NULL));
    int i = 10;
    while(i--) printf("%d\n",rand() % 100);
    return 0;
}
````

Let's compile and run:

```bash
$ gcc print_rand.c -o print_rand
$ ./print_rand
28
89
67
46
0
76
9
17
13
67
```

As expected, it prints out some random numbers.

Let's consider an alternate implementation of `rand()`:

```C
// better_rand.c

#include <stdio.h>

int rand() {
      printf("so random!\n");
      return 42; // obviously, this is the  most random number in the universe
}
```

To inject our new (better?) `rand` implementation we must first create a shared library:

```bash
gcc -shared -fPIC better_rand.c -o better_rand.so
```

Now we get to use it with our program:

```bash
LD_PRELOAD=$PWD/better_rand.so ./print_rand
so random!
42
so random!
42
so random!
42
so random!
42
so random!
42
so random!
42
so random!
42
so random!
42
so random!
42
so random!
42
```

Pretty cool right? We were able to change the behavior of our program without recompiling it! So how does that work? Essentially at load-time, when there is an unresolved symbol in the executable, the loader will traverse the list of linked libraries to find an implementation. The `LD_PRELOAD` variable allows you to insert a library at the head of that list.

So far we have only _replaced_ a function. A more interesting problem is to augment, or wrap a function. What if you wanted to do something extra (maybe logging, redirection, parameter inspection/alteration) when a function is called and also eventually actually call the original function? This is totally doable.

Lets wrap `printf`:

```C
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdarg.h>

typedef int (*orig_printf_f_type)(const char *format, ...);
typedef int (*orig_vprintf_f_type)(const char *format, va_list arglist);

int printf(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    orig_printf_f_type orig_printf = (orig_printf_f_type) dlsym(RTLD_NEXT, "printf");
    orig_vprintf_f_type orig_vprintf = (orig_vprintf_f_type) dlsym(RTLD_NEXT, "vprintf");
      // Some evil injected code goes here.

    orig_printf("Evil things, Pwahahahah!\n");

    int n = orig_vprintf(format, args);
    va_end(args);
    return n;
}
```

Whoa! There is a lot of crazy stuff going on there.

At a high level, wrapping a function requires you to get a pointer to the original function and then call the function through that pointer once you have done whatever extra stuff you want to do. Thats what the first typedef is all about. `orig_printf_f_type` captures the _type signature_ for `printf`. We then use the `dlsym` function to find the `printf` symbol somewhere in the linked libraries.

With `printf`, there is some extra work to do since it is a variadic function. There is no way to capture the variadic argument and pass them along to a variadic function. Fortunately there is usually a corresponding non-variadic function you can call with a `va_list`. In this case, we are interested in `vprintf`.

Our implementation begins by grabbing the `va_list` from the caller via a call to `va_start`. It then looks up both `printf` and `vprintf` in the linked libraries. We look up `printf` because for this demonstration, we want to print some text to the console to prove that we have succeeded in intercepting the function call. Once we print some text to the console, we call `vprintf` on the behalf of the original caller. Finally we need to make the `va_end` call and return the result of the `vprintf` call.

Lets take that for a spin:

```bash
$ gcc -shared -fPIC better_printf.c -o better_printf.so
$ LD_PRELOAD=$PWD/better_printf.so ./print_rand
Evil things, Pwahahahah!
0
Evil things, Pwahahahah!
13
Evil things, Pwahahahah!
54
Evil things, Pwahahahah!
15
Evil things, Pwahahahah!
47
Evil things, Pwahahahah!
70
Evil things, Pwahahahah!
17
Evil things, Pwahahahah!
42
Evil things, Pwahahahah!
71
Evil things, Pwahahahah!
43
```

Sweet!

We can also apply more than one at the same time:

```bash
$ LD_PRELOAD=$PWD/better_rand.so:$PWD/better_printf.so ./print_rand
so random!
Evil things, Pwahahahah!
42
so random!
Evil things, Pwahahahah!
42
so random!
Evil things, Pwahahahah!
42
so random!
Evil things, Pwahahahah!
42
so random!
Evil things, Pwahahahah!
42
so random!
Evil things, Pwahahahah!
42
so random!
Evil things, Pwahahahah!
42
so random!
Evil things, Pwahahahah!
42
so random!
Evil things, Pwahahahah!
42
so random!
Evil things, Pwahahahah!
42
```

The possibilities are endless. Perhaps you are interested (or worried about) in what an executable is doing. You could write a library that sandboxes applications by wrapping all the IO functions and keeps everything contained to a part of the filesystem, or maybe you want to spoof network IO functions.

Ok, function rewriting/wrapping is pretty neat, but we can do better.

Lets install a signal handler via `LD_PRELOAD`!

Core dumps are pretty useful for debugging problems, but maybe you want to do something more dynamic when some programs receive `SIGSEGV`. Perhaps you want to try and determine if the crash was the result of a memory corruption attack and you want to deploy an offensive cyber counter-attack. Again, the possibilities are endless.

In general, installing signal handlers is pretty easy in C. You just define a function that takes an `int` (the signal number) and returns void. You install it by calling `signal` with the signal number and the handler function as arguments.

Here is the handler we would like to install via `LD_PRELOAD`:

```C
// handler.c

#include <execinfo.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#include <dlfcn.h>
#include <stdio.h>

void handler(int sig) {
    printf("Error: signal %d:\n", sig);
    printf("I can do whatever I want in here!\n");
    exit(1);
}

void _init(void)
{
    printf("Loading hack.\n");
    signal(SIGSEGV, handler);
}
```

It turns out that every library has an `_init` function that gets called when the library is loaded. We leverage that by installing our handler in `_init`

Lets comile:

```bash
$ gcc -shared -fPIC handler.c -o handler.so
/tmp/ccj5sZeU.o: In function `_init':
handler.c:(.text+0x37): multiple definition of `_init'
/usr/lib/gcc/x86_64-linux-gnu/5/../../../x86_64-linux-gnu/crti.o:(.init+0x0): first defined here
collect2: error: ld returned 1 exit status
```

Oh no! That didn't work :(

It turns out that the way `gcc` works we can't define `_init` and compile with `-shared` because it will create the `_init` function for you and then there is a name collision.

To solve this, we need to break it into two steps:

```bash
gcc -fPIC -c handler.c
ld -shared -shared handler.o -o handler.so
```

Fantastic. Now lets write a program that will segfault:

```C
// segfaulty.c

#include <stdio.h>
#include <stdlib.h>

int main() {
    printf("it goes downhill from here ...\n");
    int i = *(int*)0;
    return 0;
}
```

Lets make sure it 'works' as expected:

```bash
$ gcc segfaulty.c -o segfaulty
$ ./segfaulty
it goes downhill from here ...
[1]    39265 segmentation fault (core dumped)  ./segfaulty
```

So far so good.

Now lets try it with our custom handler:

```bash
$ LD_PRELOAD=$PWD/handler.so ./segfaulty
Loading hack.
it goes downhill from here ...
Error: signal 11:
I can do whatever I want in here!
```

Very cool! There are two things to pay attention to here. First, take note the the `_init` function runs before `main`. If you need to do some setup before a program runs, you can do it in `_init`. Second, we successfully intercepted the `SIGSEGV`. We can do absolutely anything we want in the body of that function! Just remember that once the handler function exits, there will be a long jump to the instruction that was executing when the program received the signal. In this case, the program caused the signal so you will end up in an infinite loop unless you do someting like `exit` or `exec` in the body of the function.

I think there are tons of potential research applications for `LD_PRELOAD` (and its cousins on other operating systems). What do you think? Let me know in the comments.

Happy coding!

-----------------------------------------------------------------------------

Some of the content for this post was inspired by (lifted from) [this post](https://rafalcieslak.wordpress.com/2013/04/02/dynamic-linker-tricks-using-ld_preload-to-cheat-inject-features-and-investigate-programs/).
