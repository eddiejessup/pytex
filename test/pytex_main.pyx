from libc.stdlib cimport malloc, free
from cpython.string cimport PyString_AsString

import sys

cdef extern from "main.h":
    int main_body()
    int argc
    char **argv
    char *user_progname
    long mem_top
    long mem_min
    long mem_max


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

# FILENAME_MAX is a standard-library macro, representing the
# maximum length of a file-name string.
mem_bot = 0
ssup_error_line = 255
ssup_max_strings = 262143
ssup_trie_opcode = 65535
ssup_trie_size = 262143
ssup_hyph_size = 65535
iinf_hyphen_size = 610
max_font_max = 2000
font_base = 0
inf_trie_size = 8000
sup_trie_size = ssup_trie_size
inf_main_memory = 2999
sup_main_memory = 32000000
inf_max_strings = 3000
sup_max_strings = ssup_max_strings
inf_strings_free = 100
sup_strings_free = sup_max_strings
inf_buf_size = 500
sup_buf_size = 300000
inf_nest_size = 40
sup_nest_size = 4000
inf_max_in_open = 6
sup_max_in_open = 127
inf_param_size = 60
sup_param_size = 6000
inf_save_size = 600
sup_save_size = 40000
inf_stack_size = 200
sup_stack_size = 30000
inf_dvi_buf_size = 800
sup_dvi_buf_size = 65536
inf_font_mem_size = 20000
sup_font_mem_size = 1000000
sup_font_max = max_font_max
# Could be smaller, but why?
inf_font_max = 50
inf_pool_size = 32000
sup_pool_size = 40000000
inf_pool_free = 1000
sup_pool_free = sup_pool_size
inf_string_vacancies = 8000
sup_string_vacancies = sup_pool_size-23000
sup_hyph_size = ssup_hyph_size
# Must be not less than |hyph_prime|!
inf_hyph_size = iinf_hyphen_size
# min size of the cross-reference table for PDF output
inf_obj_tab_size = 32000
# max size of the cross-reference table for PDF output
sup_obj_tab_size = 8388607
# min size of the |pdf_mem| array
inf_pdf_mem_size = 32000
# max size of the |pdf_mem| array
sup_pdf_mem_size = 524288
inf_dest_names_size = 10000
sup_dest_names_size = 131072
ssup_error_line = 255

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
  global obj_tab_size; obj_tab_size = 65536
  global pdf_mem_size; pdf_mem_size = 65536
  global dest_names_size; dest_names_size = 20000
  global error_line; error_line = 79
  global half_error_line; half_error_line = 50
  global max_print_line; max_print_line = 79


def limit_value(value, minimum, maximum):
    return max(min(value, maximum), minimum)


def limit_constant_values_py():
  global main_memory; main_memory = limit_value(main_memory, inf_main_memory, sup_main_memory)
  global extra_mem_top
  global extra_mem_bot
  if ini_version:
      extra_mem_top = 0;
      extra_mem_bot = 0;
  if extra_mem_bot > sup_main_memory:
      extra_mem_bot = sup_main_memory;
  if extra_mem_top > sup_main_memory:
      extra_mem_top = sup_main_memory;
  global mem_top; mem_top = mem_bot + main_memory;
  global mem_min; mem_min = mem_bot;
  global mem_max; mem_max = mem_top;

  global pool_size; pool_size = limit_value(pool_size, inf_pool_size, sup_pool_size)
  global string_vacancies; string_vacancies = limit_value(string_vacancies, inf_string_vacancies, sup_string_vacancies)
  global pool_free; pool_free = limit_value(pool_free, inf_pool_free, sup_pool_free)
  global max_strings; max_strings = limit_value(max_strings, inf_max_strings, sup_max_strings)
  global strings_free; strings_free = limit_value(strings_free, inf_strings_free, sup_strings_free)
  global font_mem_size; font_mem_size = limit_value(font_mem_size, inf_font_mem_size, sup_font_mem_size)
  global font_max; font_max = limit_value(font_max, inf_font_max, sup_font_max)
  global trie_size; trie_size = limit_value(trie_size, inf_trie_size, sup_trie_size)
  global hyph_size; hyph_size = limit_value(hyph_size, inf_hyph_size, sup_hyph_size)
  global buf_size; buf_size = limit_value(buf_size, inf_buf_size, sup_buf_size)
  global nest_size; nest_size = limit_value(nest_size, inf_nest_size, sup_nest_size)
  global max_in_open; max_in_open = limit_value(max_in_open, inf_max_in_open, sup_max_in_open)
  global param_size; param_size = limit_value(param_size, inf_param_size, sup_param_size)
  global save_size; save_size = limit_value(save_size, inf_save_size, sup_save_size)
  global stack_size; stack_size = limit_value(stack_size, inf_stack_size, sup_stack_size)
  global dvi_buf_size; dvi_buf_size = limit_value(dvi_buf_size, inf_dvi_buf_size, sup_dvi_buf_size)
  global obj_tab_size; obj_tab_size = limit_value(obj_tab_size, inf_obj_tab_size, sup_obj_tab_size)
  global pdf_mem_size; pdf_mem_size = limit_value(pdf_mem_size, inf_pdf_mem_size, sup_pdf_mem_size)
  global dest_names_size; dest_names_size = limit_value(dest_names_size, inf_dest_names_size, sup_dest_names_size)
  global error_line
  if error_line > ssup_error_line:
      error_line = ssup_error_line

def main_body_py():
    set_up_bound_variables_py();
    limit_constant_values_py();
    return main_body()
