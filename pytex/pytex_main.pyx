from __future__ import print_function

from libc.stdlib cimport malloc
from libc.stdio cimport fclose
from cpython.string cimport PyString_AsString

import sys
from collections import namedtuple

import arrow

cimport pytex_main
import constants


def main(av_list, args):
    argc = len(av_list)
    argv = to_cstring_array(av_list)
    main_init(argc, argv, args)
    main_body(argc, argv)


cdef char **to_cstring_array(list_str):
    cdef char **ret = <char **>malloc(len(list_str) * sizeof(char *))
    for i in range(len(list_str)):
        ret[i] = PyString_AsString(list_str[i])
    return ret


cdef main_init(int argc, char **argv, parsed_args):
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
    interaction_option = constants.interaction_option_map[parsed_args.interaction]

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


cdef main_body(int argc, char **argv):
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

    initialize_output()
    initialize_input(argc, argv)
    # TODO: Set if this is wanted as command-line switch.
    etex_version = True
    if etex_version and ini_version:
        initialize_etex()
    global global_no_new_control_sequence; global_no_new_control_sequence = True

    # If not in extended mode (do not know why this check), and any of:
    #  - not in initex mode
    #  - first line of input is an ampersand
    #  - a \%\AM format line was seen (not sure what this means)
    if not eTeX_mode and ((not ini_version) or (buffer[loc] == '&') or dump_line):
        if ini_version:
            # Erase preloaded format.
            initialize()
        open_fmt_file()
        load_fmt_file()
        fclose(fmt_file)
        global loc
        while loc < cur_input.limit_field and buffer[loc] == ' ':
            loc += 1

    if eTeX_mode:
        print("entering extended mode");
    global buffer; buffer[cur_input.limit_field] = end_line_char
    if mltex_enabled_p:
        print("MLTeX v2.2 enabled")

    # If initex without format loaded.
    if trie_not_ready:
        trie_xmalloc(trie_size)
        # Allocate and initialize font arrays.
        font_xmalloc(font_max)
        pdffont_xmalloc(font_max)
        vf_xmalloc(font_max)
        pdffont_initialize_init(font_max)
        font_initialize_init()
    global font_used
    font_used = <boolean*>malloc((font_max + 1) * sizeof(boolean))
    for i in range(constants.font_base, font_max):
        font_used[i] = False

    global selector
    if interaction == constants.interaction_option_map['batchmode']:
        selector = constants.no_print
    else:
        selector = constants.term_only

    if loc < cur_input.limit_field and cat_code(buffer[loc]) != escape:
        # \input is assumed.
        start_input_py()

    # Read values from config file.
    read_values_from_config_file()
    history = constants.spotless
    # Come to life.
    main_control()
    # Prepare for death.
    final_cleanup()
    close_files_and_terminate()


def get_nblank_ncall():
    """Get the next non-blank non-call."""
    while True:
        get_x_token_py()
        if cur_cmd != spacer:
            break


all_modes = [vmode, hmode, mmode]
non_math_modes = [vmode, hmode]


ControlMap = namedtuple('ControlMap', ('modes', 'commands', 'function'))

def append_space():
    if space_factor == 1000:
        append_normal_space()
    else:
        app_space()


def do_nothing():
    pass


def report_illegal_case():
    raise Exception('Invalid command')


def make_hrule():
    tail_append(scan_rule_spec())
    # Disable baselineskip calculations.
    global prev_depth; prev_depth = ignore_depth


def make_vrule_from_m():
    tail_append(scan_rule_spec())


def make_vrule():
    make_vrule_from_m()
    global space_factor; space_factor = 1000

def start_new_save_level_simple_group():
    # If a left brace occurs in the middle of a page or paragraph, it simply
    # introduces a new level of grouping, and the matching right brace will not have
    # such a drastic effect. Such grouping affects neither the mode nor the
    # current list.
    new_save_level(simple_group)


def begin_a_group():
    new_save_level(semi_simple_group)


def end_a_group():
    if cur_group == semi_simple_group:
       # Pop the top level off the save stack.
        unsave()
    else:
        raise Exception('Current group code is wrong')


def move():
    scan_dimen(False, False, False)
    # If operand of current command is relax (I think)
    if cur_chr == 0:
        context_code = cur_val
    else:
        context_code = -cur_val
    # `scan_box` verifies that a `make_box` command comes next,
    # then calls `begin_box`.
    scan_box(context_code)


def handle_leader_ship():
    context_code = leader_flag - a_leaders + cur_chr
    scan_box(context_code)


def begin_new_box():
    begin_box(box_context=0)


def start_paragraph():
    new_graf(indented=cur_chr > 0)


def backup_and_start_paragraph():
    back_input()
    new_graf(indented=True)


def end_paragraph_from_v():
    normal_paragraph()
    if cur_list.mode_field > 0:
        build_page()


def end_paragraph_from_h():
    if align_state < 0:
        raise Exception('Alignment did not end properly')
    # This takes us to the enclosing `MODE_FIELD`, if `MODE_FIELD` > 0
    end_graf()
    if cur_list.mode_field == vmode:
        build_page()


control_maps = (
    ControlMap(modes=(hmode,), commands=(spacer,), function=append_space),
    ControlMap(modes=(hmode, mmode), commands=(ex_space,), function=append_normal_space),

    ControlMap(modes=all_modes, commands=(relax,), function=do_nothing),
    ControlMap(modes=[vmode, mmode], commands=(spacer,), function=do_nothing),
    ControlMap(modes=[mmode], commands=(no_boundary,), function=do_nothing),

    ControlMap(modes=[vmode], commands=(vmove, vadjust, ital_corr), function=report_illegal_case),
    ControlMap(modes=[hmode], commands=(hmove,), function=report_illegal_case),
    ControlMap(modes=[mmode], commands=(hmove,), function=report_illegal_case),
    ControlMap(modes=all_modes, commands=(last_item, mac_param), function=report_illegal_case),
    ControlMap(modes=non_math_modes, commands=(eq_no,), function=report_illegal_case),

    # The user has probably gotten into or out of math mode by mistake.
    # Insert a dollar sign and rescan the current token.
    ControlMap(modes=non_math_modes,
               commands=(sup_mark, sub_mark, math_char_num, math_given,
                         math_comp, delim_num, left_right, above, radical,
                         math_style, math_choice, vcenter, non_script, mkern,
                         limit_switch, mskip, math_accent),
               function=insert_dollar_sign),

    # Cases that build boxes and lists.

    ControlMap(modes=[vmode], commands=[hrule], function=make_hrule),
    ControlMap(modes=[hmode], commands=[vrule], function=make_vrule),
    ControlMap(modes=[mmode], commands=[vrule], function=make_vrule_from_m),

    ControlMap(modes=[vmode], commands=[vskip], function=append_glue),
    ControlMap(modes=[hmode, mmode], commands=[hskip], function=append_glue),
    ControlMap(modes=[mmode], commands=[mskip], function=append_glue),

    ControlMap(modes=all_modes, commands=[kern], function=append_kern),
    ControlMap(modes=[mmode], commands=[mkern], function=append_kern),

    # Many of the actions related to box-making are triggered by the appearance
    # of braces in the input. For example, when the user says `\hbox to 100pt{< hlist >}' in vertical mode,
    # the information about the box size (100pt) is put onto `save_stack`
    # with a level boundary word just above it, and `cur_group = adjusted_hbox_group`;
    # we enter restricted horizontal mode to process the hlist. The right
    # brace causes `save_stack` to be restored to its former state,
    # at which time the information about the box size is again
    # available; a box is packaged and we leave restricted horizontal
    # mode, appending the new box to the current list of the enclosing mode
    # (in this case to the current list of vertical mode), followed by any
    # vertical adjustments that were removed from the box by `hpack`.

    ControlMap(modes=non_math_modes, commands=[left_brace], function=start_new_save_level_simple_group),
    # The routine for a `right_brace` character branches into many subcases,
    # since a variety of things may happen, depending on `cur_group`. Some
    # types of groups are not supposed to be ended by a right brace.
    ControlMap(modes=all_modes, commands=[right_brace], function=handle_right_brace),
    ControlMap(modes=all_modes, commands=[begin_group], function=begin_a_group),
    ControlMap(modes=all_modes, commands=[end_group], function=end_a_group),

    ControlMap(modes=[vmode], commands=[hmove], function=move),
    ControlMap(modes=[hmode, mmode], commands=[vmove], function=move),

    ControlMap(modes=all_modes, commands=[leader_ship], function=handle_leader_ship),
    ControlMap(modes=all_modes, commands=[make_box], function=begin_new_box),
    ControlMap(modes=[vmode], commands=[start_par], function=start_paragraph),
    ControlMap(modes=[vmode],
               commands=[letter, other_char, char_num, char_given, math_shift,
                         un_hbox, vrule, accent, discretionary, hskip, valign,
                         ex_space, no_boundary],
               function=backup_and_start_paragraph),
    ControlMap(modes=[hmode, mmode], commands=[start_par], function=indent_in_hmode),

    # A paragraph ends at a `par_end` command, or when in horizontal mode
    # and we reach the right brace of vertical mode routines.
    ControlMap(modes=[vmode], commands=[par_end], function=end_paragraph_from_v),
    ControlMap(modes=[hmode], commands=[par_end], function=end_paragraph_from_h),
    ControlMap(modes=[hmode], commands=[stop, vskip, hrule, un_vbox, halign],
               function=head_for_vmode),
)


def get_x_token_py():
    """Set cur_cmd, cur_chr, cur_tok, and expand macros."""
    while True:
        get_next()
        if cur_cmd <= max_command:
            break
        expand()
    global cur_tok
    if cur_cs == 0:
        cur_tok = (cur_cmd * 256) + cur_chr
    else:
        cur_tok = cs_token_flag + cur_cs


def main_control():
    get_x_token_py()
    while True:
        mode = abs(cur_list.mode_field)
        if mode == hmode and cur_cmd in [letter, other_char, char_given]:
            handle_main_loop()
            continue
        elif mode == hmode and cur_cmd == char_num:
            scan_char_num()
            global cur_chr; cur_chr = cur_val
            handle_main_loop()
            continue
        elif mode == hmode and cur_cmd == no_boundary:
            get_x_token_py()
            if cur_cmd in [letter, other_char, char_given, char_num]:
                global cancel_boundary; cancel_boundary = True
            continue
        elif mode in all_modes and cur_cmd == ignore_spaces:
            get_nblank_ncall()
            continue
        elif mode == vmode and cur_cmd == stop:
            if its_all_over():
                # This is the only way out.
                return
        else:
            for modes, commands, function in control_maps:
                if mode in modes and cur_cmd in commands:
                    function()
                    break
            else:
                handle_easy_cases()
        get_x_token_py()


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


def initialize_output():
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


cdef init_terminal_py(int argc, char **argv):
    topenin(argc, argv)
    global loc
    loc = first
    while loc < last and buffer[loc] == ' ':
        loc += 1


cdef initialize_input(int argc, char **argv):
    # Initialize the input routines.
    # Get the first line of input and prepare to start.
    # When we begin the following code, TeX's tables may still contain garbage;
    # the strings might not even be present.
    # This is initializing some globals.
    cmdchr_initialize()
    init_terminal_py(argc, argv)
    global cur_input; cur_input.limit_field = last
    global first; first = last + 1

def initialize_etex():
    # In extended mode there are additional primitive commands.
    # The distinction between these two modes of operation initially takes
    # place when an eINITEX starts without reading a format file.
    # Later, the values of all eTeX state variables are inherited when
    # eVIRTEX or eINITEX reads a format file.
    global global_no_new_control_sequence; global_no_new_control_sequence = False
    # Generate eTeX primitives.
    init_etex_prim()
    # This next line is disabled because it messed up the terminal
    # position for reading the input file. Disable until we get to parsing
    # the file name and can hopefully do it way better.
    # global loc; loc += 1
    # Initialize variables for eTeX mode. This over-rides values set already
    # in initialize().
    global eTeX_mode; eTeX_mode = 1
    global max_reg_num; max_reg_num = constants.max_reg_num_etex
    global max_reg_help_line; max_reg_help_line = constants.max_reg_help_line_etex


def char_index_to_string(char_index):
    return chr(str_pool[char_index])

def string_index_to_string(string_index):
    char_indexes = range(str_start[string_index], str_start[string_index + 1])
    char_strings = (char_index_to_string(char_index)
                    for char_index in char_indexes)
    return ''.join(char_strings)


def start_input_py():
    # Set cur_name to desired file name.
    scan_file_name()
    pack_file_name(cur_name, cur_area, cur_ext)
    # Set up cur_file and new level of input.
    begin_file_reading()
    # Tell open_input we are \input.
    global tex_input_type; tex_input_type = 1
    # Kpathsea tries all the various ways to get the file.
    open_input(&input_file[cur_input.index_field],
               kpse_tex_format, constants.FOPEN_RBIN_MODE)
    # At this point name_of_file contains the actual name.
    # Extract cur_area, cur_name, and cur_ext from it.
    global name_in_progress; name_in_progress = True
    begin_name()
    global stop_at_space; stop_at_space = False
    for i in range(name_length):
        more_name(name_of_file[i + 1])
    global stop_at_space; stop_at_space = True
    end_name()
    global name_in_progress; name_in_progress = False

    cur_input.name_field = make_name_string()
    global source_filename_stack; source_filename_stack[in_open] = cur_input.name_field
    global full_source_filename_stack; full_source_filename_stack[in_open] = make_full_name_string()
    global jobname
    if jobname == 0:
        jobname = getjobname()
        # open_log_file doesn't `show_context`,
        # so limit and loc needn't be set to meaningful values yet.
        open_log_file()

    filename = string_index_to_string(full_source_filename_stack[in_open])
    print('({}'.format(filename), end='')
    global open_parens; open_parens += 1
    cur_input.state_field = new_line

    # Read the first line of the new file.
    # If the file is empty, it is considered to contain a single blank line.
    global line; line = 1
    # Next line was guarded by if(). [I don't know what that means.]
    input_line(input_file[cur_input.index_field])
    # In the C source we now do `firm_up_the_line`, but for normal usage
    # this does nothing except the following one line:
    cur_input.limit_field = last
    global buffer; buffer[cur_input.limit_field] = end_line_char
    global first; first = cur_input.limit_field + 1
    global loc; loc = cur_input.start_field
