cdef extern from "main.h":
    int main(int ac, char *av[])


def test():
    cdef char **b = ["cytest", "-ini", "test.tex"]
    cdef int i = 3
    cdef int ret = main(i, b)
    return ret
