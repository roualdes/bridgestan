import ctypes


@ctypes.CFUNCTYPE(None, ctypes.c_char_p, ctypes.c_int)
def print_callback(s, n):
    print(ctypes.string_at(s, n).decode("utf-8"), end="")


import bridgestan

m = bridgestan.StanModel('./test_models/multi/multi_model.so', "./test_models/multi/multi.data.json")

m.stanlib.bs_set_print_callback(print_callback)

import numpy as np
x = np.linspace(1.0,10,10)

import contextlib
import io
