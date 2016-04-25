from libc.stdlib cimport malloc, free
from cpython.string cimport PyString_AsString

import sys

cdef extern from "main.h":
    void limit_constant_values()
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
    # If we are initex.
    int ini_version
    # Total number of memory words allocated in initex.
    long main_memory
    long extra_mem_bot
    long extra_mem_top
    # Number of words of font_info for all fonts.
    long font_mem_size
    long font_max
    # Maximum number of hyphen exceptions.
    long hyph_size
    # Maximum number of characters simultaneously present in
    # current lines of open files and in control sequences.
    long buf_size
    # Maximum number of simultaneous input sources.
    long stack_size
    # Maximum number of simultaneous ongoing input files and error insertions.
    long max_in_open
    # Maximum number of simultaneous macro parameters.
    long param_size
    # Maximum number of semantic levels simultaneously active.
    long nest_size
    # Space for saving values outside of current group.
    long save_size
    # Size of the output buffer; must be a multiple of 8.
    long dvi_buf_size

cdef extern from "tex_string.h":
    # Maximum number of strings.
    long max_strings
    # Number of strings available after format loaded.
    long strings_free
    # The minimum number of characters that should be available.
    long string_vacancies
    long pool_size
    long pool_free

cdef extern from "trie.h":
    long trie_size

cdef extern from "tex_io.h":
    long format_default_length
    char *TEX_format_default

cdef extern from "tex_error.h":
    # Width of context lines in terminal error messages.
    long error_line
    long half_error_line
    unsigned char interaction_option

cdef extern from "print.h":
    long max_print_line

cdef extern from "pdfxref.h":
    long obj_tab_size

cdef extern from "pdfbasic.h":
    long pdf_mem_size

cdef extern from "pdfproc.h":
    # Maximum number of names in name tree of PDF output file.
    long dest_names_size

cdef extern from "kpathsea/progname.h":
    void kpse_set_program_name(char *av0, char *progname)
    char *kpse_program_name

cdef extern from "kpathsea/getopt.h":
    struct option:
        pass
    int getopt_long_only(int argc, char *const *argv, const char *shortopts,
                         const option *longopts, int *longind)

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


def set_up_bound_variables_py():
  global main_memory; main_memory = 250000
  global extra_mem_top; extra_mem_top = 0
  global extra_mem_bot; extra_mem_bot = 0
  global pool_size; pool_size = 50000
  global string_vacancies; string_vacancies = 750
  global pool_free; pool_free = 500
  global max_strings; max_strings = 300
  global strings_free; strings_free = 100
  global font_mem_size; font_mem_size = 100000
  global font_max; font_max = 500
  global trie_size; trie_size = 20000
  global hyph_size; hyph_size = 659
  global buf_size; buf_size = 3000
  global nest_size; nest_size = 50
  global max_in_open; max_in_open = 15
  global param_size; param_size = 60
  global save_size; save_size = 4000
  global stack_size; stack_size = 300
  global dvi_buf_size; dvi_buf_size = 16384
  global error_line; error_line = 79
  global half_error_line; half_error_line = 50
  global max_print_line; max_print_line = 79
  global obj_tab_size; obj_tab_size = 65536
  global pdf_mem_size; pdf_mem_size = 65536
  global dest_names_size; dest_names_size = 20000


def main_body_py():
    set_up_bound_variables_py();
    limit_constant_values();
    return main_body()
