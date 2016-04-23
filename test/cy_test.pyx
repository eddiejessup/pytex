cdef extern from "main.h":
    int main(int ac, char *av[])
    void main_init(int ac, char *av[])
    int main_body()


def test(fname):
    cdef char **b = ["cytex", "-ini", fname]
    cdef int i = 3
    main_init(i, b)
    cdef int ret = main_body()
    return ret
