"""
IPython launch script
Author: Ely M. Spears
"""
from __future__ import print_function

import re
import os
import abc
import ast
import sys
import mock
import time
import types
import array
import pandas
import inspect
import platform
import cProfile
import unittest
import operator
import warnings
import datetime
import dateutil
import calendar
import itertools
import contextlib
import collections
import multiprocessing

import numpy             as np
import scipy             as sp
import scipy.stats       as st
import sqlalchemy.sql    as sql
import sqlalchemy.schema as schema
 
from sqlalchemy             import create_engine
from dateutil.relativedelta import relativedelta as drr
from IPython.core.magic     import (Magics,
                                    register_line_magic,
                                    register_cell_magic,
                                    register_line_cell_magic)

# Python 2/3 import safety checks
try:
    import cPickle as pickle
except:
    import pickle

try:
    import copy_reg
except:
    import copyreg as copy_reg

# When on local machine, attempt a default database 
# connection using local configuration.
if platform.node() == "eschaton":
    try:
        with open("/home/ely/.sqlalchemyrc", 'r') as db_file:
            db_config = ast.literal_eval(db_file.read())
            db_engine = create_engine(db_config["postgresql"])
            db_conn   = db_engine.connect()
            db_query  = lambda x: db_conn.execute(x+";").fetchall()
    except Exception as e:
        print("Exception while connecting to local postgres database server:")
        print(e)


###########################
# Pickle/Unpickle methods #
###########################

# See explanation at:
# < http://bytes.com/topic/python/answers/
#   552476-why-cant-you-pickle-instancemethods >
def _pickle_method(method):
    func_name = method.im_func.__name__
    obj = method.im_self
    cls = method.im_class
    return _unpickle_method, (func_name, obj, cls)

def _unpickle_method(func_name, obj, cls):
    for cls in cls.mro():
        try:
            func = cls.__dict__[func_name]
        except KeyError:
            pass
        else:
            break
    return func.__get__(obj, cls)

copy_reg.pickle(types.MethodType, _pickle_method, _unpickle_method)

# Helper context manager to modify PYTHONPATH to include a parent directory, 
# then revert PYTHONPATH back, so that parent directory relative imports will
# work inside a with-statement, e.g. `with enable_parent_import():` Note that
# this doesn't work in an IPython session, because the current frame is based
# on IPython-maintained session files, and not the working directory.
@contextlib.contextmanager
def enable_parent_import():
    """
    Temporarily modify PYTHONPATH to search the parent directory for imports.
    """
    path_appended = False
    try:
        current_file      = inspect.getfile(inspect.currentframe())
        current_directory = os.path.dirname(os.path.abspath(current_file))
        parent_directory  = os.path.dirname(current_directory)
        sys.path.insert(0, parent_directory) 
        path_appended = True
        yield
    finally:
        if path_appended:
            sys.path.pop(0)

#############
# Utilities #
#############
def interface_methods(*methods):
    """
    Class decorator that can decorate an abstract base class with method names
    that must be checked in order for isinstance or issubclass to return True.
    """
    def decorator(Base):
        def __subclasshook__(Class, Subclass):
            if Class is Base:
                all_ancestor_attrs = [ancestor_class.__dict__.keys()
                                      for ancestor_class in Subclass.__mro__]
                if all(method in all_ancestor_attrs for method in methods):
                    return True
            return NotImplemented
        Base.__subclasshook__ = classmethod(__subclasshook__)
        return Base

def interface(*attributes):
    """
    Class decorator checking for any kind of attributes, not just methods.

    Usage:

    @interface(('foo', 'bar', 'baz))
    class Blah
       pass

    Now, new classes will be treated as if they are subclasses of Blah, and 
    instances will be treated instances of Blah, provided they possess the
    attributes 'foo', 'bar', and 'baz'.
    """
    def decorator(Base):
        def checker(Other):
            return all(hasattr(Other, a) for a in attributes)
        
        def __subclasshook__(cls, Other):
            if checker(Other):
                return True
            return NotImplemented
        
        def __instancecheck__(cls, Other):
            return checker(Other)

        Base.__metaclass__.__subclasshook__ = classmethod(__subclasshook__)
        Base.__metaclass__.__instancecheck__ = classmethod(__instancecheck__)
        return Base
    return decorator

def ensure_return_type(permissible_types):
    """
    Decorator factory for method decoration. Forces output of decorated
    function to be a type from the tuple `permissible_types`.
    """
    from functools import wraps
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            potential_return = func(*args, **kwargs)
            if isinstance(potential_return, permissible_types):
                return potential_return
                #Note: could support a plain callable argument, instead of 
                #the tuple of types. Then replace the if-condition above
                #with calling that callable on the potential return value.
            else:
                err_msg = "Return values `{}` must be a type from {}".format(
                    potential_return, permissible_types)
                raise TypeError(err_msg)
        return wrapper
    return decorator

def target_getitem(function_name):
    """
    Endow a class with the property that calls to `__getitem__` will mirror the
    arguments into the class's function named 'function_name'. Optionally add
    an extra argument, api_mapper, which first sanitizes the arguments from
    `__getitem__` and then passes them on to the function.
    """
    def decorator(klass):
        def __getitem__(self, args):
            args = args if isinstance(args, tuple) else (args,) # For 1-D index
            return getattr(self, function_name)(*args)
        klass.__getitem__ = __getitem__
        return klass
    return decorator

def fn_unique(itr, cmp_op=operator.ne):
    """
    Creates an order-preserving new list from an input iterator, such that only
    the unique elements from the original appear. Optionally can be used with
    a different comparison operator. Inspired by Haskell's `nub` function. 
    This is implemented with recursion, so not useful for large arrays in 
    Python.
    """
    l = list(itr)
    f = lambda x: cmp_op(x, l[0])
    return [] if l == [] else l[0:1] + fn_unique(filter(f, l[1:]), cmp_op)

def fn_get_nth(seq, cond_callable, n=1):
    """
    Among all entries x within `seq` such that cond_callable(x) evaluates to
    True, return the n-th. Returns None if StopIteration or other issues cause
    an error in finding the n-th occurrence.
    """
    islice = itertools.islice

    # Due to changes to filter in Python 3.
    try:
        ifilter = itertools.ifilter
    except:
        ifilter = filter

    try:
        return (islice(ifilter(cond_callable, seq), n-1, n).next() if n >= 0
                else fn_get_nth(reversed(seq), cond_callable, -n))
    except:
        return None
    
def fn_context(call):
    """
    Create an on-the-fly context manager out of an arbitrary callable. E.g.:

        `with fn_context(set)(my_list) as s:`

    will create a `set` out of `my_list` by calling `set(my_list)` and then
    feeding it as the context manager for a `with` statement. Works with any
    callable in place of `set` in the example.
    """
    from contextlib import contextmanager
    apply_call_generator = lambda x: (call(y) for y in (x,))
    return contextmanager(apply_call_generator)

def fn_debug(f, *args, **kwargs):
    """
    Feed a function and args into the IPython debugger. Some other useful
    debugging options: 

        python -m pdb file.py
        %run -d file.py
    """
    from IPython.core.debugger import Pdb
    return Pdb(color_scheme="Linux").runcall(f, *args, **kwargs)

def fn_set_trace():
    """
    Sets a more feature-rich version of set_trace.
    """
    from IPython.core.debugger import Pdb
    Pdb(color_scheme="Linux").set_trace(sys._getframe().f_back)

def fn_console():
    """
    Prompt a code console to explore local variables. Similar to
    setting a trace.
    """
    import code
    code.interact(local=locals())

class attrdict(dict):
    """
    Inherits from dict and sets __getattr__ to mirror __getitem__, allowing
    dot-based access to the dict's keys.
    """
    def __getattr__(self, attr):
        return self[attr]

class get(object):
    """
    Class such that when an attribute is accessed, like g = get() then
    "g.a" returns a function that gets attribute "a" from its argument.

    This can be used for cutesy syntax for getting attributes, such as:

    _ = get()
    map(_.a, [x, y, z]) ---> [x.a, y.a, z.a]
    """
    from operator import attrgetter
    def __getattr__(self, attr):
        return lambda x: attrgetter(attr)(x)

class SliceMaker(object):
    """
    __getitem__ for this class just returns the "item" (slice) that was
    requested, so it is a factory for slices. So if x = SliceMaker(), then
    asking for x[some_slice] just returns some_slice as a slice object.

    This allows you to compactly pass around the slice syntax. Similar to
    the numpy s_ function.
    """
    def __getitem__(self, item):
        return item

class SelectableDataFrame(pandas.DataFrame):
    """
    Subclasses DataFrame purely to mokeypatch a select function. 
    """
    def select(self, column, value=None, op=None):
        """
        Inputs
        ------
        column: A string naming one of the DataFrame's columns.
        value: A value for comparison. Default is None.
        op: A callable that accepts either 1 or 2 arguments. For 1
            argument, op(self[column]) is called. For two,
            op(self[column], value) is callued. Default is None

        If op and value are None, then it functions to select where
        the column is not null. If op is None but value is not None,
        then it is assumed that equality-checking is the requested
        operation, and will return where self[column] == value. If only
        value is None, then the op is applied as a unary operator to
        the column.
        """
        if value is None and op is None:
            condition = self[column].notnull()
        elif value is not None and op is None:
            condition = (self[column] == value)
        elif value is None and op is not None:
            condition = op(self[column])
        else:
            condition = op(self[column], value)

        return SelectableDataFrame(self[condition])

class Infix(object):
    """
    Raymond Hettinger infix recipe (from ActiveState code example). Creates
    an instance object that overrides << and >> to function like an "infix"
    operator.
    """
    def __init__(self, function):
        self.function = function
    
    def __rlshift__(self, other):
        return Infix(lambda x, self=self, other=other: self.function(other, x))
    
    def __rshift__(self, other):
        return self.function(other)

    def __call__(self, value1, value2):
        return self.function(value1, value2)

class SelectInfix(Infix):
    """
    Special case of Infix that doessome parsing on what is requested
    and allows for SQL-like statements to appear on the left side.
    """
    def __init__(self):
        self.function = lambda x,y=None: (
            lambda z: self.parse_select_value(x, z))

    def __mul__(self, other):
        return self.function("*") << other

    def parse_select_value(self, val, df):
        if isinstance(val, (list, tuple, set)):
            return df[list(val)]

        elif isinstance(val, str):
            if val.startswith("TOP"):
                str_top, top_val = val.split()
                return df.head(int(top_val))

            elif val.startswith("BOTTOM"):
                str_bottom, bottom_val = val.split()
                return df.tail(int(bottom_val))

            elif val == "*":
                return df
                
class COL(object):
    """
    Column object. Wraps a string naming a column in an eventual DataFrame to
    be used with the infix tools. Creates selection callables based on 
    supported logic operations.
    """

    def __init__(self, column):
        self.column = column

    def make_function(self, other, op):
        return lambda x: SelectableDataFrame(x).select(self.column, other, op)

    def __gt__(self, other):
        op = operator.gt
        return self.make_function(other, op)

    def __ge__(self, other):
        op = operator.ge
        return self.make_function(other, op)

    def __lt__(self, other):
        op = operator.lt
        return self.make_function(other, op)

    def __le__(self, other):
        op = operator.le
        return self.make_function(other, op)

    def __eq__(self, other):
        op, other = ((lambda x: np.isnan(x), None) if np.isnan(other)
                     else (operator.eq, other))
        return self.make_function(other, op)

    def __ne__(self, other):
        op, other = ((lambda x: ~np.isnan(x), None) if np.isnan(other)
                     else (operator.ne, other))
        return self.make_function(other, op)

    def __mod__(self, other):
        op = lambda x, y: x.isin(y)
        return self.make_function(other, op)

class Timer(object):
    """
    Timing context manager. Usage: `with Timer() as foo: ...` then
    inspect foo.elapsed_time at the end.
    """
    def __init__(self, verbose=False, name = None):
        from timeit import default_timer
        self.timer, self.verbose = default_timer, verbose
        self.name = " " if name is None else "'" + name + "'"

    def __enter__(self):
        self.start = self.timer()

    def __exit__(self, *args):
        self.stop = self.timer()
        self.elapsed_time = self.stop - self.start
        if self.verbose:
            print ("Block {} elpased time: {}".format(self.name, 
                                                      self.elapsed_time))

###############################
# Data and instance utilities #
###############################
arry = np.random.rand(25)
dfrm = pandas.DataFrame(np.random.rand(10,3),
                        columns=["A", "B", "C"])

tall_dfrm = pandas.DataFrame(np.random.rand(200,5),
                             columns=["A", "B", "C", "D", "E"])
tall_dfrm["F"] = np.random.randint(0, 15, 200)
        
# For infix pandas/sql hack.
AND = Infix(lambda x, y: y(x))
FROM = Infix(lambda x, y: x(y))
WHERE = Infix(lambda x, y: y(x))
SELECT = SelectInfix()
    
    
    
