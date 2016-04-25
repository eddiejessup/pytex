import sys
import argparse

import pytex_main


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("texname",
                        help='TeX file to be processed')
    parser.add_argument('-efm', '--efm',
                        help='efm file to use instead of program name')
    parser.add_argument('-ini', '--ini', action='store_true',
                        help='be pdfeinitex, for dumping formats; this is '
                             'implicitly true if the program name is pdfeinitex')
    parser.add_argument('-interaction', '--interaction',
                        choices=['batchmode', 'nonstopmode',
                                 'scrollmode', 'errorstopmode'],
                        help='Set interaction mode')
    parser.add_argument('-jobname', '--jobname',
                        )
    parser.add_argument('-mltex', '--mltex', action='store_true',
                        help='Enable MLTeX extensions such as charsubdef',
                        )
    parser.add_argument('-progname', '--progname',
                        help='Set program (and format) name'
                        )
    parser.add_argument('-version', '--version', action='store_true',
                        help='Output version information and exit'
                        )
    args = parser.parse_args()
    # Pass in raw argument array too for compatibility purposes
    pytex_main.main_init_py(sys.argv, args)
    pytex_main.main_body_py()

if __name__ == '__main__':
    main()
