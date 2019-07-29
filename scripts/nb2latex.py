#! /usr/bin/env python

"""
Convert a Jupyter notebook to LaTeX, using the latex_envs environment
"""

################################################################################

# Module imports
from __future__ import print_function
import argparse
import subprocess
import sys

################################################################################

# Aliases and global variables
python_version_major = str(sys.version_info.major)

################################################################################

if __name__ == "__main__":

    # Set up the command-line argument processor
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('files',
                        metavar='FILE',
                        type=str,
                        nargs='*',
                        help='Jupyter notebook filename(s) to be processed')
    parser.add_argument('--kernel',
                        dest='kernel',
                        choices=['python2', 'python3'],
                        default='python' + python_version_major,
                        help='notebook execution kernel')
    parser.add_argument('--header',
                        dest='header',
                        type=str,
                        default='References',
                        help='provide the title of the bibliography section')
    parser.add_argument('--includeHeaders',
                        dest='removeHeaders',
                        action='store_false',
                        default=False,
                        help='include the headers')
    parser.add_argument('--removeHeaders',
                        dest='removeHeaders',
                        action='store_true',
                        default=False,
                        help='remove the headers')
    parser.add_argument('--includeTocRef',
                        dest='removeTocRef',
                        action='store_false',
                        default=False,
                        help='include the table of contents and references')
    parser.add_argument('--removeTocRef',
                        dest='removeTocRef',
                        action='store_true',
                        default=False,
                        help='remove the table of contents and references')
    parser.add_argument('--includeFigCaptionProcess',
                        dest='removeFigCaptionProcess',
                        action='store_false',
                        default=False,
                        help='include the figure caption process')
    parser.add_argument('--removeFigCaptionProcess',
                        dest='removeFigCaptionProcess',
                        action='store_true',
                        default=False,
                        help='remove the figure caption process')
    parser.add_argument('-v',
                        '--verbose',
                        dest='verbose',
                        action='store_true',
                        default=True,
                        help='provide verbose output')
    parser.add_argument('-q',
                        '--quiet',
                        dest='verbose',
                        action='store_false',
                        default=True,
                        help='set verbose to False')

    # Parse the command-line arguments
    options = parser.parse_args()
    
    # Process the options
    sep = '----------------'
    if options.verbose:
        print(sep)

    # Check for no specified filenames
    if len(options.files) == 0:
        parser.error("too few arguments")

    # Process the files
    result = 0
    for filename in options.files:
        cmd = ["jupyter",
               "nbconvert",
               "--to",
               "latex_with_lenvs"]

        clo = []
        if options.removeHeaders:
            clo.append('--LenvsLatexExporter.removeHeaders=True')
        if options.removeTocRef:
            clo.append('--LenvsLatexExporter.tocrefRemove=True')
        if options.removeFigCaptionProcess:
            clo.append('--LenvsLatexExporter.figcaptionProcess=False')
        cmd.extend(clo)

        cmd.append(filename)

        process = subprocess.Popen(cmd,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        this_result = process.wait()
        stdout, stderr = process.communicate()
        if options.verbose or this_result != 0:
            print(stderr, end='')
        if options.verbose:
            print(sep)
        result = max(result, this_result)

    sys.exit(result)
