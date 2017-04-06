#! /usr/bin/env python

import nbconvert
import nbformat
import os
import pypandoc
import sys

from traitlets import Unicode
from traitlets.config import Config
from urllib import urlopen

HTMLExporter        = nbconvert.HTMLExporter
Preprocessor        = nbconvert.preprocessors.Preprocessor
ExecutePreprocessor = nbconvert.preprocessors.ExecutePreprocessor
FilesWriter         = nbconvert.writers.FilesWriter
NotebookNode        = nbformat.notebooknode.NotebookNode

########################################################################

def print_notebook(nb):
    numcells = len(nb.cells)
    for c in range(numcells):
        output = "%d: %s" % (c, str(nb.cells[c]))
        output = output.encode('ascii', 'ignore')
        if len(output) > 160:
            output = output[:157] + "..."
        print(output)

########################################################################

class AddCitationsPreprocessor(Preprocessor):
    """
    An nbconvert.preprocessors.Preprocessor class that adds citations to a
    Jupyter notebook. In the notebook, citations should be indicated with
    `[@bibtex_key]` syntax, where @bibtex_key refers to a BibTeX key to a
    bibliographic entry in a .bib file. This class has the following
    configurable attributes:

        bibliography - The name of the BibTeX bibliography file (default
                       "ref.bib")
        csl          - The name of the Citation Style Language file (default
                       "AJCC.csl")
        header       - The name of the bibliography section appended to the end
                       of the notebook (default "References")

    This preprocessor converts each citation instance with the appropriate text
    for the citation as defined by the CSL file. It also adds two cells to the
    end of the notebook: a header, defaulting to "References", and a list of all
    of the cited references. In addition, any empty cells are removed from the
    notebook.
    """

    bibliography = Unicode(u'ref.bib',
                           help='Name of the BibTeX bibliography file',
                           config=True)
    csl          = Unicode(u'AJCC.csl',
                           help='Name of the Citation Style Language file',
                           config=True)
    header       = Unicode(u'References',
                           help='Header name for the references section',
                           config=True)

    def _is_cell_empty(self, cell):
        """
        Return True if the given cell is empty
        """
        if cell.cell_type == u'code':
            if cell.source == u'':
                return True
        return False

    def _clear_empty_cells(self, nb):
        """
        Remove any empty cells from the given notebook
        """
        new_list = []
        for cell in nb.cells:
            if not self._is_cell_empty(cell):
                new_list.append(cell)
        nb.cells = new_list

    def _is_index_in_ranges(self, index, ranges):
        """
        Return True if the given index in with any of the given ranges
        """
        for range in ranges:
            if index >= range[0] and index < range[1]:
                return True
        return False

    def _extract_citations(self, nb):
        """
        Return a list of all the citations in the given notebook, in the order
        in which they first appear. Each citation will appear only once
        """
        citations = []
        for cell in nb.cells:
            ranges = []
            source = cell.source
            start = source.find('@',0)
            end = 0
            while start >= 0:
                if start == 0 or source[start-1] in ['[',' ','-']:
                    index = source.rfind('[',end,start)
                    if not (index == -1 or self._is_index_in_ranges(index, ranges)):
                        start = index
                        end = source.find(']',start) + 1
                    else:
                        end1 = source.find(' ', start)
                        end2 = source.find(',', start)
                        end3 = source.find('.', start)
                        if end1 == -1: end1 = len(source)
                        if end2 == -1: end2 = len(source)
                        if end3 == -1: end3 = len(source)
                        end = min(end1, end2, end3)
                    citation = source[start:end]
                    if citation not in citations:
                        citations.append(citation)
                    ranges.append((start,end))
                else:
                    end = start + 1
                start = source.find('@',end)
        print "citations =", citations
        return list(citations)

    """
    I am supposed to support citations [see @Haidvogel1997, pp. 509--511] with
    both a prefix and suffix. And finally, a double citation with prefixes and
    suffixes [see @Boer, p. 12,780; also @Washington1986, ch. 2].
    """

    def _process_citations(self, nb):
        """
        Query the given notebook, and return a dictionary of substitutions and a
        string representing the formatted references in HTML. The substitution
        dictionary consist of keys that represent the citation keys
        ([@bibtex_key]) and values that represent the corresponding citation
        text, formatted according to the preprocessor's CSL file. The
        substitution dictionary returned by this method is suitable as input to
        the _substitute_citations() method, and the references returned by this
        method is suitable as input to the _add_references() method.
        """
        # Build a markdown text field with citations only
        citations = self._extract_citations(nb)
        body = ""
        for citation in citations:
            body += citation + "\n\n"

        # Run the markdown text through pandoc with the pandoc-citeproc filter
        filters = ['pandoc-citeproc']
        extra_args = ['--bibliography="%s"' % self.bibliography,
                      '--csl="%s"' % self.csl]
        body = pypandoc.convert_text(body,
                                     'html',
                                     'md',
                                     filters=filters,
                                     extra_args=extra_args)
        body = body.split('\n')

        # Extract the citation substitutions and the references section from the
        # resulting HTML text
        substitutions = {}
        num_citations = len(citations)
        if num_citations > 0:
            for i in range(num_citations):
                substitutions[citations[i]] = body[i][26:-11]
            references = "\n<p></p>\n".join(body[num_citations:])
        else:
            references = ""
        return (substitutions, references)

    def _substitute_citations(self, nb, substitutions):
        """
        Given a substitutions dictionary, as provided by the
        _process_citations() method, substitute the formatted citation text for
        every instance of a citation key found in the notebook.
        """
        keys = substitutions.keys()
        # As we loop over the substitution keys, we want to process [@key]
        # before @key, which sorting and reversing will ensure
        keys.sort()
        keys.reverse()
        for cell in nb.cells:
            source = cell.source
            for old in keys:
                new = substitutions[old]
                source = source.replace(old, new)
            cell.source = source

    def _add_references(self, nb, references):
        """
        Add a references header cell and a references text cell to the end of
        the notebook. If references in the empty string, do nothing. If a
        references section already exists in the notebook, overwrite the
        existing references text cell.
        """
        if references:
            header_text = u'## ' + self.header
            if nb.cells[-2].source == header_text:
                nb.cells[-1].source = references
            else:
                new_cells = [NotebookNode({u'source': header_text,
                                           u'cell_type': u'markdown',
                                           u'metadata': {}}),
                             NotebookNode({u'source': references,
                                           u'cell_type': u'markdown',
                                           u'metadata': {}})]
                nb.cells.extend(new_cells)

    def preprocess(self, nb, resources):
        """
        Preprocess the given notebook by removing all empty cells, substituting
        all citation keys with citation text formatted according to the CSL
        file, and adding a references section to the end of the notebook.
        """
        self._clear_empty_cells(nb)
        (subs, refs) = self._process_citations(nb)
        self._substitute_citations(nb, subs)
        self._add_references(nb, refs)
        #print
        #print "Preprocessed Notebook"
        #print_notebook(nb)
        return (nb, resources)

########################################################################

def convert(filename):
    # Open the Jupyter notebook and print it
    (basename, ext) = os.path.splitext(filename)
    response = urlopen(filename).read().decode()
    print "Reading", filename
    notebook = nbformat.reads(response, as_version=4)
    #print "Original Notebook"
    #print_notebook(notebook)

    # Configure the HTMLExporter to use the preprocessors
    c = Config()
    c.HTMLExporter.preprocessors = [#ExecutePreprocessor(),
                                    AddCitationsPreprocessor()]

    # Convert the notebook to HTML
    html_exporter = HTMLExporter(config=c)
    print "Converting", filename
    (body, resources) = html_exporter.from_notebook_node(notebook)

    # Output
    writer = FilesWriter()
    print "Writing %s.html" % basename
    writer.write(body, resources, notebook_name=basename)

########################################################################

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print "usage: converter.py FILE"
        sys.exit(-1)
    filename = sys.argv[1]
    convert(filename)
