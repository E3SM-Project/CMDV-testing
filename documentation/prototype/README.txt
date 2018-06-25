Prerequisites
-------------
It is recommended to run the `nb2html` script under an Anaconda
environment. That will automatically install Jupyter. Other
requirements:

  * pypandoc
      - The most portable installation process, which also installs
        `pandoc-citeproc` (another requirement) is:
      - `conda install -c conda-forge pypandoc`

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

The script converter.py can convert a .ipynb file to a .html file
while converting all citations to an appropriate in-line citation
(e.g. "[1]", "[2]", etc.) and adding a References section to the end
of the HTML page. The intent is that this HTML file would be the
outward-looking HTML file for documenting the verification test.

By default, references are placed in the file ref.bib and are formatted
according to AJCC.csl, the Citation Style Language file for the
American Journal of Climate Change. Both of these filenames are
configurable, as is the title of the references section:

    $ ./converter.py --help
    usage: converter.py [-h] [-v] [-q] [--csl CSL] [--bib BIB] [--header HEADER]
                        FILE [FILE ...]

    Convert a Jupyter notebook to HTML, including the processing of citations

    positional arguments:
      FILE             Jupyter notebook filename to be processed

    optional arguments:
      -h, --help       show this help message and exit
      -v, --verbose    provide verbose output (default: False)
      -q, --quiet      set verbose to False (default: False)
      --csl CSL        specify the Citation Style Language file (default:
                       AJCC.csl)
      --bib BIB        specify the BibTeX bibliography database (default: ref.bib)
      --header HEADER  provide the title of the bibliography section (default:
                       References)

If you want to search for a new Citation Style Language file, start at
http://citationstyles.org/styles/, which points to many resources,
including the Zotero Style Repository at http://zotero.org/styles.
