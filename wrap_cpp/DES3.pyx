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
