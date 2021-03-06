from libc.stdio cimport FILE
from libcpp.vector cimport vector


ctypedef long int integer
ctypedef int boolean
ctypedef integer str_number
ctypedef unsigned char packed_ASCII_code
ctypedef unsigned char ASCII_code
ctypedef int halfword
ctypedef unsigned char quarterword
ctypedef halfword pointer
ctypedef unsigned char eight_bits
ctypedef unsigned char group_code
ctypedef integer scaled
ctypedef unsigned char small_number

cdef extern from "main.h":
    void topenin(int argc, char **argv)
    void allocate_memory_for_arrays()
    void initialize()
    void init_prim(int noninit)
    void init_etex_prim()
    void final_cleanup()
    char *user_progname
    long mem_top
    long mem_min
    long mem_max

cdef extern from "mainio.h":
    int tex_input_type
    boolean open_input(FILE** file_ptr, int format, const char *mode)

cdef extern from "control.h":
    boolean its_all_over()
    void handle_main_loop()
    void handle_easy_cases()
    void append_normal_space()
    void handle_right_brace()
    void delete_last()
    boolean cancel_boundary

cdef extern from "align.h":
    void init_align()
    void do_endv()
    integer align_state

cdef extern from "exten.h":
    int shell_enabled_p

cdef extern from "eqtb.h":
    memory_word *eqtb
    long end_line_char
    long cat_code(ASCII_code)
    int every_job

cdef extern from "etex.h":
    halfword max_reg_num
    char *max_reg_help_line
    unsigned char eTeX_mode
    int eTeX_state_base

cdef extern from "dump.h":
    boolean open_fmt_file()
    boolean load_fmt_file()
    FILE *fmt_file
    char *dump_name
    boolean dump_line

cdef extern from "types.h":
    struct in_state_record:
        quarterword state_field,
        quarterword index_field,
        halfword start_field,
        halfword loc_field,
        halfword limit_field,
        halfword name_field,
    struct list_state_record:
        int mode_field,
        pointer head_field,
        pointer tail_field,
        pointer eTeX_aux_field,
        int pg_field,
        int ml_field,
    struct U:
        integer CINT
    struct memory_word:
        U u

cdef extern from "math.h":
    pointer new_math(scaled w, small_number s)

cdef extern from "mathbuild.h":
    void init_math()
    void start_eq_no()
    void scan_math(pointer p)
    void insert_dollar_sign()

cdef extern from "buildpage.h":
    void build_page()

cdef extern from "box.h":
    void scan_box(int box_context)
    void begin_box(int box_context)
    void append_glue()
    void unpackage()
    void append_italic_correction()
    void append_discretionary()
    int leader_flag

cdef extern from "glue.h":
    void app_space()
    void append_glue()
    int a_leaders

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
    boolean global_no_new_control_sequence
    const int hash_prime

cdef extern from "insert.h":
    void begin_insert_or_adjust()

cdef extern from "kern.h":
    void append_kern()
    pointer new_kern(scaled w)

cdef extern from "nest.h":
    void tail_append(pointer)
    list_state_record cur_list
    int hmode, vmode, mmode, ignore_depth, prev_depth

cdef extern from "save.h":
    void new_save_level(group_code c)
    void unsave()
    pointer scan_rule_spec()
    integer cur_val
    group_code simple_group, semi_simple_group, math_shift_group
    group_code cur_group

cdef extern from "scan.h":
    void scan_char_num()
    pointer scan_rule_spec()
    void scan_dimen(boolean mu, boolean inf, boolean shortcut)
    # Value returned by numeric scanners.
    integer cur_val

cdef extern from "par.h":
    void new_graf(boolean indented)
    void head_for_vmode()
    void normal_paragraph()
    void indent_in_hmode()
    void end_graf()

cdef extern from "penalty.h":
    void append_penalty()

cdef extern from "mark.h":
    void make_mark()

cdef extern from "cmdchr.h":
    void cmdchr_initialize()
    void begin_token_list(pointer p, quarterword t)
    # Put the token just scanned back into the input stream to be read again.
    void back_input()
    FILE **input_file
    in_state_record cur_input
    # Number of lines in the buffer, minus one.
    unsigned int in_open
    # Number of open text files.
    unsigned int open_parens
    # Current line number in the current source file.
    integer line
    int escape, new_line, every_job_text, spacer, letter, other_char, char_given
    int char_num, no_boundary, ignore_spaces, stop, relax, ex_space, space_factor
    int eq_no, last_item, mac_param
    int hmove, vmove, vadjust, ital_corr, max_command, cur_tok, cur_cs
    int sup_mark, sub_mark, math_char_num, math_given, math_comp, delim_num
    int left_right, above, radical, math_style, math_choice, vcenter
    int non_script, mkern, limit_switch, mskip, math_accent
    int hrule, vrule, hskip, vskip, kern
    int left_brace, right_brace, begin_group, end_group
    int leader_ship, make_box, start_par, par_end
    int math_shift, un_hbox, un_vbox, accent, discretionary, valign, halign
    int INSERT_CODE, mark, break_penalty, remove_item, endv, end_cs_name
    int car_ret, tab_mark, no_align, omit
    # Current command set by `get_next`.
    eight_bits cur_cmd
    # Operand of current command.
    halfword cur_chr

cdef extern from "tokens.h":
    void get_next()
    void expand()

cdef extern from "tokenlist.h":
    int cs_token_flag

cdef extern from "tex_string.h":
    str_number search_string(str_number)
    # Maximum number of strings.
    long max_strings
    # Number of strings available after format loaded.
    long strings_free
    # The minimum number of characters that should be available.
    long string_vacancies
    long pool_size
    long pool_free
    packed_ASCII_code *str_pool
    long *str_start
    long pool_ptr
    long str_ptr
    long init_pool_ptr
    long init_str_ptr
    long make_string()

cdef extern from "tex_math.h":
    pointer new_noad()
    int nucleus(int)

cdef extern from "trie.h":
    long trie_size
    boolean trie_not_ready
    void trie_xmalloc(integer size)

cdef extern from "tex_io.h":
    void scan_file_name()
    void pack_file_name(str_number name, str_number area, str_number ext)
    void begin_file_reading()
    void begin_name()
    void end_name()
    boolean more_name(ASCII_code c)
    str_number make_name_string()
    str_number make_full_name_string()
    str_number getjobname()
    void open_log_file()
    boolean input_line(FILE *f)
    void close_files_and_terminate()
    vector[str_number] source_filename_stack
    str_number *full_source_filename_stack
    ASCII_code *name_of_file
    unsigned int name_length
    str_number cur_name
    str_number cur_area
    str_number cur_ext
    long format_default_length
    char *TEX_format_default
    # Lines of characters being read.
    ASCII_code *buffer
    unsigned int first
    unsigned int last
    unsigned int loc
    # If a file name is being scanned.
    int name_in_progress
    # Whether more_name should return False for space.
    int stop_at_space
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
    unsigned char interaction
    unsigned char history

cdef extern from "print.h":
    void print_initialize()
    long max_print_line
    unsigned char selector
    int tally
    unsigned int term_offset
    unsigned int file_offset

cdef extern from "mltex.h":
    boolean mltex_enabled_p

cdef extern from "font.h":
    void font_xmalloc(integer font_max)
    void font_initialize_init()
    void make_accent()
    boolean *font_used

cdef extern from "pdffont.h":
    void pdffont_xmalloc(integer font_max)
    void pdffont_initialize_init(integer font_max)

cdef extern from "vf.h":
    void vf_xmalloc(integer font_max)

cdef extern from "pdfxref.h":
    long obj_tab_size

cdef extern from "pdfbasic.h":
    void read_values_from_config_file()
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

cdef extern from "kpathsea/tex-file.h":
    enum kpse_file_format_type:
        kpse_tex_format

cdef extern:
    option[] long_options
