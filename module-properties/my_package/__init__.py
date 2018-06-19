import sys
import importlib
from types import ModuleType


class MyModule(ModuleType):

    def __init__(self, name):
        super(MyModule, self).__init__(name)
        self.module1 = None
        self.module2 = None
        self.module3 = None

    def __getattribute__(self, attr):
        val = object.__getattribute__(self, attr)
        if val is None:
            try:
                ret = object.__getattribute__(self, '_' + attr)
            except AttributeError:
                return None

            setattr(self, attr, ret)
            return ret

        return val

    @property
    def _module1(self):
        if not self.__dict__.get('module1'):
            self.__dict__['module1'] = importlib.import_module('.module1', __package__)

        return self.__dict__['module1']

    @property
    def _module2(self):
        if not self.__dict__.get('module2'):
            self.__dict__['module2'] = importlib.import_module('.module2', __package__)

        return self.__dict__['module2']

    @property
    def _module3(self):
        if not self.__dict__.get('module3'):
            self.__dict__['module3'] = importlib.import_module('.module3', __package__)

        return self.__dict__['module3']


old = sys.modules[__name__]
new = MyModule(__name__)
new.__path__ = old.__path__

for k, v in list(old.__dict__.items()):
    new.__dict__[k] = v

sys.modules[__name__] = new
