import sys

cdef extern from "main.h":
    int main(int ac, char **av)
    int main_body()
    void parse_options(int argc, char **argv)

cdef extern:
    # Defined in exten.c
    int shell_enabled_p
    # Defined in main.c
    int argc
    char **argv
    char *user_progname
    # Defined in dump.c
    char *dump_name
    # Defined in a weird way in kpathsea/progname.c
    void kpse_set_program_name(char *av0, char *progname)
    char *kpse_program_name
    # Defined in tex.c
    int ini_version
    # Defined in tex_error.c
    unsigned char interaction_option
    # Defined in mltex.c
    int mltex_p
    # Defined in texio.c
    long format_default_length
    char *TEX_format_default


cdef main_init_py(int ac, char **av):
    global argc
    argc = ac
    global argv
    argv = av
    global interaction_option
    interaction_option = 4
    parse_options(ac, av)
    kpse_set_program_name(argv[0], user_progname)

    # Local variable
    virversion = False
    global ini_version
    global mltex_p
    if kpse_program_name == b"pdfeinitex":
        ini_version = True
    elif kpse_program_name == b"pdfevirtex":
        virversion = True
    elif kpse_program_name == b"mltex":
        mltex_p = True
    elif kpse_program_name == b"initex":
        ini_version = True
    elif kpse_program_name == b"virtex":
        virversion = True
    global dump_name
    if not dump_name:
        # Can't use ternary operator (x if b else y), does not compile
        if virversion:
            dump_name = b"plain"
        else:
            dump_name = kpse_program_name

    if dump_name:
        TEX_format_default_py = b" {}.efm".format(dump_name)
        global TEX_format_default
        TEX_format_default = TEX_format_default_py
        # Not sure why need -1, maybe to do with C-strings being
        # null-terminated? Not even sure what that means, just heard it.
        # Or maybe to get index of last character.
        # We are trying to match result of: `strlen(TEX_format_default + 1)`.
        global format_default_length
        format_default_length = len(TEX_format_default) - 1
    else:
        sys.exit()
    global shell_enabled_p
    shell_enabled_p = 1


def test(fname):
    cdef char **b = ["cytex", "-ini", fname]
    cdef int i = 3
    main_init_py(i, b)
    cdef int ret = main_body()
    return ret
