import sys

cdef extern from "main.h":
    int main(int ac, char **av)
    int main_body()
    void parse_options(int argc, char **argv)
    int argc
    char **argv
    char *user_progname
    void usage(const char* str)
    void usagehelp(const char** message)
    void printversionandexit(const char* banner,
                             const char* copyright_holder,
                             const char* author)


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
        const char* name
    char *optarg
    int getopt_long_only(int argc, char *const *argv, const char *shortopts,
                         const option *longopts, int *longind)

cdef extern from "tex_error.h":
    unsigned char interaction_option

cdef extern from "mltex.h":
    int mltex_p

cdef extern from "tex_io.h":
    long format_default_length
    char *TEX_format_default

cdef extern:
    option[] long_options

COPYRIGHT_HOLDER = "The NTS Team (eTeX)/Han The Thanh (pdfTeX)/Elliot Marsden (PyTeX)"
AUTHOR = "Elliot Marsden"
BANNER = "This is PyTeX, Version 0.1"
PROGRAM_HELP = '''
Usage: pdfetex [OPTION]... [TEXNAME[.tex]] [COMMANDS]
   or: pdfetex [OPTION]... \\FIRST-LINE
   or: pdfetex [OPTION]... &FMT ARGS
  Run pdfeTeX on TEXNAME, usually creating TEXNAME.pdf.
  Any remaining COMMANDS are processed as pdfeTeX input, after TEXNAME is read.
  If the first line of TEXNAME is %&FMT, and FMT is an existing .fmt file,
  use it.  Else use `NAME.efmt', where NAME is the program invocation name,
  most commonly `pdfetex'.

  Alternatively, if the first non-option argument begins with a backslash,
  interpret all non-option arguments as a line of pdfeTeX input.

  Alternatively, if the first non-option argument begins with a &, the
  next word is taken as the FMT to read, overriding all else.  Any
  remaining arguments are processed as above.

  If no arguments or options are specified, prompt for input.

-efm=FMTNAME             use FMTNAME instead of program name or a %& line
-ini                     be pdfeinitex, for dumping formats; this is implicitly
                          true if the program name is `pdfeinitex'
-interaction=STRING      set interaction mode (STRING=batchmode/nonstopmode/
                          scrollmode/errorstopmode)
-jobname=STRING          set the job name to STRING
-mltex                   enable MLTeX extensions such as \\charsubdef
-progname=STRING         set program (and fmt) name to STRING
-help                    display this help and exit
-version                 output version information and exit
'''

cdef parse_options_py(int argc,  char **argv):
    cdef int option_index

    while True:
        g = getopt_long_only(argc, argv, "+", long_options, &option_index)

        if g == -1:
            # End of arguments, exit the loop.
            break

        if g == '?':  # Unknown option.
            usage(argv[0])

        assert g == 0

        global user_progname
        global dump_name
        global dump_option
        global job_name
        global interaction_option
        if long_options[option_index].name == b"progname":
            user_progname = optarg

        elif long_options[option_index].name == b"jobname":
            job_name = optarg

        elif long_options[option_index].name == b"efm":
            dump_name = optarg
            if not user_progname:
                user_progname = optarg
            dump_option = True

        elif long_options[option_index].name == b"interaction":
            # These numbers match @d's in *.ch
            if optarg == b"batchmode":
                interaction_option = 0
            elif optarg == b"nonstopmode":
                interaction_option = 1
            elif optarg == b"scrollmode":
                interaction_option = 2
            elif optarg == b"errorstopmode":
                interaction_option = 3
            else:
                raise Warning("Ignoring unknown argument `%s' to --interaction" % optarg)

        elif long_options[option_index].name == b"help":
            # The type conversion is not right here, but I think
            # we are soon going to replace this whole thing with
            # argparse, so just do nothing for now.
            # usagehelp(PROGRAM_HELP)
            pass

        elif long_options[option_index].name == b"version":
            printversionandexit(BANNER, COPYRIGHT_HOLDER, AUTHOR)
        else:
            # It was a flag; getopt has already done the assignment.
            pass


cdef main_init_py(int ac, char **av):
    global argc
    argc = ac
    global argv
    argv = av
    global interaction_option
    interaction_option = 4
    parse_options_py(ac, av)
    kpse_set_program_name(argv[0], user_progname)

    # Local variable.
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
