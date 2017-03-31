#! /usr/bin/env python

########################################################################

def extract_styles(fname):
    """
    Extract the first <style> block found in HTML data after the specified start
    index. Returns a tuple of starting and ending indexes.

    Arguments:
        fname     Input file name

    Output:
        A list of strings that represent HTML describing the style specified
        within fname
    """
    html = open(fname, 'r').readlines()
    output = []
    start  = 0
    end    = 0
    while True:
        try:
            start = html.index('<style type="text/css">\n', end)
            end   = len(html)
            for i in range(start, end):
                if '</style>' in html[i]:
                    end = i+1
                    break
            if end == len(html):
                print('Error: Improperly specified style in HTML file "%s"' %
                      fname)
                break
            output.extend(html[start:end])
        except ValueError:
            break
    return output

########################################################################

def extract_references(fname):
    """
    Extract the 'References' section from an HTML file that has been generated
    by pandoc using the pandoc-citeproc filter, including styles.

    Arguments:
        fname    Input filename

    Output:
        A list of strings that represent HTML that contains a References section
    """
    html = open(fname,'r').readlines()
    output = []
    try:
        index = html.index('<div id="refs" class="references">\n')
        output.extend(html[index:])
    except ValueError:
        print('Error: References not found in HTML file "%s"' % fname)
    return output

########################################################################

def construct_refs_html(sname, rname):
    output = extract_styles(sname)
    output.extend(extract_references(rname))
    open("refs.html", "w").writelines(output)

########################################################################

def construct_html_notebook(sname, rname, oname):
    endline = '\n'
    output = ['<!DOCTYPE html>\n',
              '<html>\n',
              '<head><meta charset="utf-8" />\n',
              '<title>SWTC1</title>\n',
              '\n',
              '<script src="https://cdnjs.cloudflare.com/ajax/libs/require.js/2.1.10/require.min.js"></script>\n',
              '<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min.js"></script>\n']
    output.extend(extract_styles(sname))
    output.extend(['\n',
                   '<!-- Custom stylesheet, it must be in the same directory as the html file -->\n',
                   '<link rel="stylesheet" href="custom.css">\n',
                   '\n',
                   '<!-- Loading mathjax macro -->\n',
                   '<!-- Load mathjax -->\n',
                   '    <script src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML"></script>\n',
                   '    <!-- MathJax configuration -->\n',
                   '    <script type="text/x-mathjax-config">\n',
                   '    MathJax.Hub.Config({\n',
                   '        tex2jax: {\n',
                   r'            inlineMath: [ ["$","$"], ["\\(","\\)"] ],' + endline,
                   r'            displayMath: [ ["$$","$$"], ["\\[","\\]"] ],' + endline,
                   '            processEscapes: true,\n',
                   '            processEnvironments: true\n',
                   '        },\n',
                   '        // Center justify equations in code and markdown cells. Elsewhere\n',
                   '        // we use CSS to left justify single line equations in code cells.\n',
                   '        displayAlign: "center",\n',
                   '        "HTML-CSS": {\n',
                   '            styles: {".MathJax_Display": {"margin": 0}},\n',
                   '            linebreaks: { automatic: true }\n',
                   '        }\n',
                   '    });\n',
                   '    </script>\n',
                   '    <!-- End of mathjax configuration --></head>\n',
                   '<body>\n',
                   '  <div tabindex="-1" id="notebook" class="border-box-sizing">\n',
                   '    <div class="container" id="notebook-container">\n',
                   '\n',
                   '<div class="cell border-box-sizing text_cell rendered">\n',
                   '<div class="prompt input_prompt">\n',
                   '</div>\n',
                   '<div class="inner_cell">\n',
                   '<div class="text_cell_render border-box-sizing rendered_html">\n',
                   ])
    body = open(rname, 'r').readlines()
    index = body.index('<div id="refs" class="references">\n')
    output.extend(body[0:index])
    output.extend(['</div>\n',
                   '</div>\n',
                   '</div>\n',
                   '</body>\n',
                   '</html>\n'])
    open(oname, 'w').writelines(output)

########################################################################

def plot_geopotential(time=0):
    """
    Plot the geopotential in the file swtc1/movies/swtc11.nc

    Arguments:
        time    Time index to be plotted
    """
    import netCDF4
    import matplotlib.pyplot as plt
    swtc1 = netCDF4.Dataset("swtc1/movies/swtc11.nc", "r")
    times = swtc1.variables["time"][:]
    lat   = swtc1.variables["lat"][:]
    lon   = swtc1.variables["lon"][:]
    geop  = swtc1.variables["geop"][:,0,:,:]
    fig, ax  = plt.subplots(1, 1, figsize=(10,4.5))
    contours = ax.contourf(lon, lat, geop[time])
    cbar     = fig.colorbar(contours)
    ax.set_title("Geopotential at t = %d days" % times[time])
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_aspect("equal")

########################################################################

