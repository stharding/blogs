
cpdef int fib(int n):
    return 1 if n <= 1 else fib(n - 1) + fib(n - 2)
