from libc.stdlib cimport malloc, free
from cpython.string cimport PyString_AsString

import sys

cdef extern from "main.h":
    int main_body()
    int argc
    char **argv
    char *user_progname


cdef extern from "exten.h":
    int shell_enabled_p

cdef extern from "dump.h":
    char *dump_name

cdef extern from "globals.h":
    # Defined in tex.c
    # If are we INITEX
    int ini_version

cdef extern from "kpathsea/progname.h":
    void kpse_set_program_name(char *av0, char *progname)
    char *kpse_program_name

cdef extern from "kpathsea/getopt.h":
    struct option:
        pass
    int getopt_long_only(int argc, char *const *argv, const char *shortopts,
                         const option *longopts, int *longind)

cdef extern from "tex_error.h":
    unsigned char interaction_option

cdef extern from "tex_io.h":
    long format_default_length
    char *TEX_format_default

cdef extern:
    option[] long_options

interaction_option_map = {
    'batchmode': 0,
    'nonstopmode': 1,
    'scrollmode': 2,
    'errorstopmode': 3,
    'default': 4,
}


cdef char **to_cstring_array(list_str):
    cdef char **ret = <char **>malloc(len(list_str) * sizeof(char *))
    for i in range(len(list_str)):
        ret[i] = PyString_AsString(list_str[i])
    return ret


def main_init_py(av_list, parsed_args):
    global argc
    argc = len(av_list)
    global argv
    argv = to_cstring_array(av_list)

    # Unfortunately, this parsing seems to have some side-effect that is
    # important, so we can't just remove it.
    # Maybe it gobbles up the options so that all that is left is the file
    # name to open?
    cdef int option_index
    while True:
        g = getopt_long_only(argc, argv, "+", long_options, &option_index)
        if g == -1:
            # End of arguments, exit the loop.
            break

    global user_progname
    if parsed_args.progname is not None:
        user_progname = parsed_args.progname

    global job_name
    if parsed_args.jobname is not None:
        job_name = parsed_args.jobname

    global ini_version
    if parsed_args.ini:
        ini_version = True

    kpse_set_program_name(argv[0], user_progname)
    global dump_name
    global dump_option
    if parsed_args.efm is not None:
        dump_name = parsed_args.efm
        if not user_progname:
            user_progname = parsed_args.efm
        dump_option = True
    else:
        dump_name = kpse_program_name

    global interaction_option
    interaction_option = interaction_option_map[parsed_args.interaction]

    TEX_format_default_py = b" {}.efm".format(dump_name)
    global TEX_format_default
    TEX_format_default = TEX_format_default_py
    # Not sure why need -1, maybe to do with C-strings being
    # null-terminated? Not even sure what that means, just heard it.
    # Or maybe to get index of last character.
    # We are trying to match result of: `strlen(TEX_format_default + 1)`.
    global format_default_length
    format_default_length = len(TEX_format_default) - 1

    global shell_enabled_p
    shell_enabled_p = 1

def main_body_py():
    return main_body()
