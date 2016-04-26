from libc.stdlib cimport malloc, free
from cpython.string cimport PyString_AsString

import sys

import arrow

import constants


ctypedef unsigned char packed_ASCII_code
ctypedef unsigned char ASCII_code
ctypedef unsigned char quarterword
ctypedef int halfword

cdef extern from "main.h":
    int main_body()
    void allocate_memory_for_arrays()
    void initialize()
    void init_prim(int noninit)
    int argc
    char **argv
    char *user_progname
    long mem_top
    long mem_min
    long mem_max

cdef extern from "main.h":
    void topenin()

cdef extern from "exten.h":
    int shell_enabled_p

cdef extern from "dump.h":
    char *dump_name

cdef extern from "types.h":
    struct in_state_record:
        quarterword state_field,
        quarterword index_field,
        halfword start_field,
        halfword loc_field,
        halfword limit_field,
        halfword name_field,

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

cdef extern from "hash.h":
    const int hash_prime

cdef extern from "cmdchr.h":
    void cmdchr_initialize()
    in_state_record cur_input

cdef extern from "tex_string.h":
    # Maximum number of strings.
    long max_strings
    # Number of strings available after format loaded.
    long strings_free
    # The minimum number of characters that should be available.
    long string_vacancies
    long pool_size
    long pool_free
    long pool_free
    packed_ASCII_code *str_pool
    long *str_start
    long pool_ptr
    long str_ptr
    long init_pool_ptr
    long init_str_ptr
    long make_string()

cdef extern from "trie.h":
    long trie_size

cdef extern from "tex_io.h":
    int init_terminal()
    long format_default_length
    char *TEX_format_default
    # Lines of characters being read.
    ASCII_code *buffer
    unsigned int first
    unsigned int last
    unsigned int loc
    # If a file name is being scanned.
    int name_in_progress
    # Principal file name.
    long jobname
    # If the transcript file has been opened.
    int log_opened
    # Full name of the output file.
    long output_file_name

cdef extern from "tex_error.h":
    # Width of context lines in terminal error messages.
    long error_line
    long half_error_line
    unsigned char interaction_option
    unsigned char history

cdef extern from "print.h":
    void print_initialize()
    long max_print_line
    unsigned char selector
    int tally
    unsigned int term_offset
    unsigned int file_offset

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
  global main_memory; main_memory = constants.main_memory
  global extra_mem_top; extra_mem_top = constants.extra_mem_top
  global extra_mem_bot; extra_mem_bot = constants.extra_mem_bot
  global pool_size; pool_size = constants.pool_size
  global string_vacancies; string_vacancies = constants.string_vacancies
  global pool_free; pool_free = constants.pool_free
  global max_strings; max_strings = constants.max_strings
  global strings_free; strings_free = constants.strings_free
  global font_mem_size; font_mem_size = constants.font_mem_size
  global font_max; font_max = constants.font_max
  global trie_size; trie_size = constants.trie_size
  global hyph_size; hyph_size = constants.hyph_size
  global buf_size; buf_size = constants.buf_size
  global nest_size; nest_size = constants.nest_size
  global max_in_open; max_in_open = constants.max_in_open
  global param_size; param_size = constants.param_size
  global save_size; save_size = constants.save_size
  global stack_size; stack_size = constants.stack_size
  global dvi_buf_size; dvi_buf_size = constants.dvi_buf_size
  global obj_tab_size; obj_tab_size = constants.obj_tab_size
  global pdf_mem_size; pdf_mem_size = constants.pdf_mem_size
  global dest_names_size; dest_names_size = constants.dest_names_size
  global error_line; error_line = constants.error_line
  global half_error_line; half_error_line = constants.half_error_line
  global max_print_line; max_print_line = constants.max_print_line

  global mem_top; mem_top = constants.mem_bot + main_memory;
  global mem_min; mem_min = constants.mem_bot;
  global mem_max; mem_max = mem_top;


def check_for_bad_constants_py():
    global bad; bad = 0
    if (half_error_line < 30) or (half_error_line > error_line - 15):
        bad = 1
    if max_print_line < 60:
        bad = 2
    if dvi_buf_size % 8 != 0:
        bad = 3
    if constants.mem_bot + 1100 > mem_top:
        bad = 4
    if hash_prime > constants.HASH_SIZE:
        bad = 5
    if max_in_open >= 128:
        bad = 6
    if mem_top < 256 + 11:
        bad = 7
    if (mem_min != constants.mem_bot) or (mem_max != mem_top):
        bad = 10
    if (mem_min > constants.mem_bot) or (mem_max < mem_top):
        bad = 10
    if (constants.min_quarterword > 0) or (constants.max_quarterword < 127):
        bad = 11
    if (constants.min_halfword > 0) or (constants.max_halfword < 32767):
        bad = 12
    if (constants.min_quarterword < constants.min_halfword) or (constants.max_quarterword > constants.max_halfword):
        bad = 13
    if (mem_min < constants.min_halfword) or (mem_max >= constants.max_halfword)or (constants.mem_bot - mem_min > constants.max_halfword + 1):
        bad = 14
    if (constants.max_font_max < constants.min_halfword) or (constants.max_font_max > constants.max_halfword):
        bad = 15
    if font_max > constants.font_base + constants.max_font_max:
        bad = 16
    if (save_size > constants.max_halfword) or (max_strings > constants.max_halfword):
        bad = 17
    if buf_size > constants.max_halfword:
        bad = 18
    if constants.max_quarterword - constants.min_quarterword < 255:
        bad = 19
    # Check is disabled because eqtb_size's definition lead to an insanely
    # long series of dependent macros.
    # if cs_token_flag + eqtb_size > constants.max_halfword:
    #     bad = 21;
    if format_default_length > constants.file_name_size:
        bad = 31
    if 2 * constants.max_halfword < mem_top - mem_min:
        bad = 41
    if bad > 0:
        raise ValueError("Internal constants have been clobbered! Bad = {}".format(bad))


def get_strings_started_py():
    """Initialize the string pool."""
    global pool_ptr; pool_ptr = 0
    global str_ptr; str_ptr = 0
    global str_start; str_start[0] = 0
    # The first 256 strings will each be one character.
    for k in range(256):
        str_pool[pool_ptr] = k
        pool_ptr += 1
        make_string()
    # Make the null string.
    make_string()


def set_date_and_time_py():
    now = arrow.now()
    global tex_time; tex_time = now.hour * 60 + now.minute
    global day; day = now.day
    global month; month = now.month
    global year; year = now.year


def init_terminal_py():
    topenin()
    global loc
    global first
    if last > first:
        loc = first
        while loc < last and buffer[loc] == ' ':
            loc += 1
        if loc < last:
            return


def main_body_py():
    set_up_bound_variables_py()
    allocate_memory_for_arrays()
    check_for_bad_constants_py()
    # In case we quit during initialization
    global history; history = constants.fatal_error_stop
    # get_strings_started is needed always and before initialize
    get_strings_started_py()
    # Set global variables to their starting values.
    initialize()
    # Call 'primitive' for each primitive.
    init_prim(not ini_version)
    if ini_version:
        global init_str_ptr; init_str_ptr = str_ptr
        global init_pool_ptr; init_pool_ptr = pool_ptr
        set_date_and_time_py()

    print('{} {}'.format(constants.banner, '(ini)' if ini_version else ''))

    # Initialize the output routines.
    global selector; selector = constants.term_only
    global tally; tally = 0
    global term_offset; term_offset = 0
    global file_offset; file_offset = 0
    # Jobname becomes nonzero as soon as the true name is known.
    # We have jobname = 0 if and only if the log file has not been
    # opened, except for a short time just after jobname has become nonzero.
    global jobname; jobname = 0
    global name_in_progress; name_in_progress = False
    global log_opened; log_opened = False
    global output_file_name; output_file_name = 0

    # Initialize the input routines.
    # Get the first line of input and prepare to start.
    # When we begin the following code, TeX's tables may still contain garbage;
    # the strings might not even be present.
    # This is initializing some globals.
    cmdchr_initialize()
    init_terminal_py()

    global cur_input; cur_input.limit_field = last
    global first; first = last + 1

    return main_body()
