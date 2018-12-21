Prerequisites
-------------
It is recommended to run the `nb2html` script under an Anaconda
environment. That will automatically install Jupyter. Other
requirements:

  * pypandoc
      - The most portable installation process, which also installs
        `pandoc-citeproc` (another requirement) is:
      - `conda install -c conda-forge pypandoc`

  * matplotlib

  * netcdf4

Using Citations in a Jupyter Notebook
-------------------------------------
It is possible to cite references from a BibTeX .bib file within a
Jupyter notebook using markdown of the following forms:

    [@bibtex_key]
    [@bibtex_key1; @bibtex_key2]
    [see @bibtex_key]
    [@bibtex_key, pp. 12-34]
    [see @bibtex_key, pp. 123-456]
    @bibtex_key
    [-@bibtex_key]

The script nb2html can convert a .ipynb file to a .html file while
converting all citations to an appropriate in-line citation
(e.g. "[1]", "[2]", etc.) and adding a References section to the end
of the HTML page. The intent is that this HTML file would be the
outward-looking HTML file for documenting the verification test.

By default, references are placed in the file ref.bib and are formatted
according to AJCC.csl, the Citation Style Language file for the
American Journal of Climate Change. Both of these filenames are
configurable, as is the title of the references section:

    $ ./nb2html --help
    usage: nb2html [-h] [--kernel {python2,python3}] [-t TIMEOUT]
                   [--header HEADER] [-b BIB] [--csl CSL] [--list-csl]
                   [--list-csl-path] [--replace-csl-path CSL_PATH]
                   [--prepend-csl-path CSL_PATH] [--append-csl-path CSL_PATH]
                   [--debug] [-v] [-q]
                   [FILE [FILE ...]]

    Convert a Jupyter notebook to HTML, by executing the notebook and then
    processing any references to publications to generate citations in the text
    and a bibliography section at the end of the notebook

    positional arguments:
      FILE                  Jupyter notebook filename(s) to be processed (default:
                            None)

    optional arguments:
      -h, --help            show this help message and exit
      --kernel {python2,python3}
                            notebook execution kernel (default: python3)
      -t TIMEOUT, --timeout TIMEOUT
                            defines maximum time (in seconds) each notebook cell
                            is allowed to run (default: 30)
      --header HEADER       provide the title of the bibliography section
                            (default: References)
      -b BIB, --bib BIB     specify the BibTeX bibliography database (default:
                            ref.bib)
      --csl CSL             specify the Citation Style Language file (default:
                            Climate.csl)
      --list-csl            list the available CSL files and exit (default: False)
      --list-csl-path       list the CSL path names and exit (default: False)
      --replace-csl-path CSL_PATH
                            replace the list of CSL path names (default: ['.',
                            '/Development/CMDV-testing/scripts/CSL'])
      --prepend-csl-path CSL_PATH
                            prepend a comma-separated list of path names to the
                            CSL path name list (default: None)
      --append-csl-path CSL_PATH
                            append a comma-separated list of path names to the CSL
                            path name list (default: None)
      --debug               provide full stack trace for errors (default: False)
      -v, --verbose         provide verbose output (default: False)
      -q, --quiet           set verbose to False (default: False)

If you want to search for a new Citation Style Language file, start at
http://citationstyles.org/styles/, which points to many resources,
including the Zotero Style Repository at http://zotero.org/styles.
