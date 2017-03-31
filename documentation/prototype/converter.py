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

    def _extract_citations(self, nb):
        """
        Return a list of all the citations in the given notebook, in the order
        in which they first appear. Each citation will appear only once
        """
        citations = set()
        for cell in nb.cells:
            source = cell.source
            start = source.find('[@',0)
            while start >= 0:
                end = source.find(']',start) + 1
                citations.add(source[start:end])
                start = source.find('[@',end)
        return list(citations)

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
        for cell in nb.cells:
            source = cell.source
            for old in substitutions.keys():
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
