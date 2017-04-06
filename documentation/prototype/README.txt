Prerequisites
-------------
  * Jupyter
  * LaTeX
  * Pandoc   http://pandoc.org/installing.html
  * Pandoc-citeproc

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

Currently, references are placed in the file ref.bib and are formatted
according to AJCC.csl, the Citation Style Language file for the
American Journal of Climate Change. Both of these filenames are
supposed to be configurable, but this has not been tested yet.
