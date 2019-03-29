Using the latex_env Package
---------------------------

This directory is to help familiarize users with the
`jupyter_latex_envs` package.  It first takes you through the steps of
creating a conda environment that supports the package and provides
instructions for familiarizing yourself with the capabilities of the
package.


Steps for installing the `jupyter_latex_envs` package
-----------------------------------------------------

The following steps work for Python 3, and have not been tested for
Python 2.  Here, we assume `conda` is set up to create Python 3
environments by default.

1. **Create a conda environment** If you already have a conda
   environment you would like to enhance, you can use that one and
   just add the new capabilities to it.  If not, run

     `$ conda create --name latex_env`

   You can choose whatever name you like.  If your `conda` package is
   set up to default to Python 2, use

     `$ conda create --name latex_env python=3`

2. **Activate the conda environment**  Wether you created a new
   environment or are using an existing one, make sure you are running
   the environment you want to use:

     `$ source activate latex_env`

   Note that on Unix systems, the period (`.`) is an alias for
   `source`.

3. **Make sure you are using the latest `pip`** We are going to use
   `pip` to install `jupyter_latex_envs` and it is a good idea to
   ensure `pip` is up-to-date:

     `(latex_env) $ pip install --upgrade pip`

4. **Install `jupyter_latex_envs`**:

     `(latex_env) $ pip install jupyter_latex_envs`

5. **Install the Jupyter Notebook extension**  This copies the
   appropriate files into the Jupyter `nbextension` directory:

     `(latex_env) $ jupyter nbextension install --py latex_envs --user`

6. **Enable the Jupyter Notebook extension** This enables the
   extension to Jupyter and alters how Jupyter behaves.  In this case,
   it adds buttons to the Jupyter toolbar and adds some auto-
   completions when typing within a markdown cell:

     `(latex_env) $ jupyter nbextension enable latex_envs --user --py`


Steps for using the `jupyter_latex_envs` package
------------------------------------------------

7. **Run the Jupyter Notebook**  start up the Jupyter Notebook:

     `(latex_env) $ jupyter notebook`

   and enter your password if required.  

8. **Choose the test notebook** Click on the notebook named `LaTeX Env
   Test.ipynb`.  You should see three new buttons in the toolbar, for
   refreshing, reading the bibliography file, and toggling a
   configuration toolbar.

9. **Familiarize youself the package** Observe how the notebook
   behaves when it is first opened.  Double-click on the markdown
   cells to see the markdown text and observe how they are rendered
   when you hit shift-return.  Modify the contents of cells and
   experiment with the buttons.  See

     https://rawgit.com/jfbercher/jupyter_latex_envs/master/src/latex_envs/static/doc/latex_env_doc.html

   for documentation.
