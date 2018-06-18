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
