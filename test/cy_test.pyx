cdef extern from "main.h":
    int main(int ac, char *av[])


def test(fname):
    cdef char **b = ["cytex", "-ini", fname]
    cdef int i = 3
    cdef int ret = main(i, b)
    return ret
