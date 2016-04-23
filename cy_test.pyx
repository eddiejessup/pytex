cdef extern from "main.h":
    int main(int ac, char **av)


def test():
    cdef char* a = "test.tex"
    cdef char **b = &a
    cdef int i = 1
    cdef int ret = main(i, b)
    return ret
