from libcpp.string cimport string

from art import text2art as _text2art

cdef public string text2art(string text):
    return _text2art(text)
