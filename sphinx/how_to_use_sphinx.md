Get Sphinx by doing:

```bash
pip install Sphinx
```

To make documentation:

```
sphinx-apidoc -PMefTF -A "Stephen Harding" -V 1.0 -R 1.0 -o docs ../firescout_vis
```

in the directory where the package is.

Then make the following changes to the `conf.py` file in the `docs` folder:

Change this:

```python
# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#sys.path.insert(0, os.path.abspath('.'))
```

to

```python
# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
sys.path.insert(0, os.path.abspath('..'))
```

To enable automatic references change this in the conf.py:

```python
# The reST default role (used for this markup: `text`) to use for all
# documents.
#default_role = None
```

to this:

```
# The reST default role (used for this markup: `text`) to use for all
# documents.
default_role = 'py:obj'
```

Set this to fix TOC overflow:

```python
# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
html_theme_options = {'stickysidebar': True}
```

(see [the docs](http://www.sphinx-doc.org/en/1.4.9/markup/inline.html#xref-syntax))

you can build and set conf options:

```bash
sphinx-build -D html_theme=classic -D default_role=py:obj . _build/html
```
