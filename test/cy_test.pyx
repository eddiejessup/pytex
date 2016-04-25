cdef extern from "main.h":
    int main(int ac, char **av)
    void main_init(int ac, char **av)
    int main_body()

cdef extern from "main.h":
    int shell_enabled_p



def test(fname):
    cdef char **b = ["cytex", "-ini", fname]
    cdef int i = 3
    main_init(i, b)
    cdef int ret = main_body()
    set_bool()
    return ret


def set_bool():
    shell_enabled_p = 1
