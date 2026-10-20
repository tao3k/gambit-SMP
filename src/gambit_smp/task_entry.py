"""Task entry policy shared by action modules, without importing command routing."""
import sys
from functools import wraps
from contextvars import ContextVar
from importlib import import_module

_dispatch=ContextVar("smp_dispatch",default=False)


def _dispatcher():
    return import_module("gambit_smp.cli").main


def module_main(command, callback):
    """Direct module execution uses the single installed command dispatcher."""
    return _dispatcher()([command, *sys.argv[1:]], _callback=callback)


def managed_entry(command):
    """Imported main() calls and module/console calls have one dispatch policy."""
    def decorate(function):
        @wraps(function)
        def managed(*args,**kwargs):
            if _dispatch.get():return function(*args,**kwargs)
            return _dispatcher()([command,*sys.argv[1:]],_callback=lambda:function(*args,**kwargs))
        return managed
    return decorate


def managed_tool(name):
    def decorate(function):
        @wraps(function)
        def managed(*args,**kwargs):
            if _dispatch.get():return function(*args,**kwargs)
            return tool_main(name,lambda:function(*args,**kwargs))
        return managed
    return decorate


def tool_main(name,callback):
    def invoke_tool():
        previous=sys.argv
        try:
            sys.argv=['gambit-smp tool '+name,*previous[2:]]
            return callback()
        finally:sys.argv=previous
    return _dispatcher()(['tool',name,*sys.argv[1:]],_callback=invoke_tool)
