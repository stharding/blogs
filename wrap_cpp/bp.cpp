#include <cstdint>
#include <boost/python.hpp>

#include "fileencryption.h"

namespace bp = boost::python;

BOOST_PYTHON_MODULE(DES3)
{
    bp::class_<FileEncryption>("FileEncryption", bp::init<uint64_t>(
        bp::arg("key")))

        .def("encrypt", &FileEncryption::encrypt,
            (bp::arg("input_filename"), bp::arg("output_filename")))

        .def("decrypt", &FileEncryption::decrypt,
            (bp::arg("input_filename"), bp::arg("output_filename")))
    ;
}
