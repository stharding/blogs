from functools import partial


def debug_fn_name(fn, classname=''):
    """
    A decorator that prints out the class name (if provided) and
    the function name prior to the function call execution
    """

    def _debug(*args, **kwargs):
        if classname:
            print('in class', classname, 'in fucntion:', fn.__name__)
        else:
            print('in fucntion:', fn.__name__)

        return fn(*args, **kwargs)
    return _debug


class TraceFunctionNameMeta(type):
    """
    A metaclass which if set on a class will apply the `debug_fn_name`
    decorator to all class methods on the class and any subclasses.
    """

    def __new__(cls, name, bases, clsdict):
        for fname, fn in clsdict.items():
            if callable(fn):
                clsdict[fname] = partial(debug_fn_name, classname=name)(fn)
        return super(TraceFunctionNameMeta, cls).__new__(cls, name, bases, clsdict)
