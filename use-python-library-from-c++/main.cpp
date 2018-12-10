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
