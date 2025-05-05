# Toggl-Invoicer, A Contractor Style Monthly Invoice Generator for Toggl

This is a monthly style invoice generator for contractors who use
[Toggl](https://toggl.com) to track their time.

When I started using [Toggl](https://toggl.com), I looked around at similar
projects to this one had done, and none of them quite fit what I was looking
for, so I decided to roll my own.  I wanted something that would generate a
LaTeX style invoice which could be manually edited or adjusted, then compiled
the invoice to a PDF which could be sent to clients.   Dockerizing the whole
thing was the easiest way to avoid requiring a massive set of texlive
dependencies to be installed.

## Dependencies

Toggl-Invoicer runs in a docker container that includes all of its
dependencies.  A wrapper script is installed as "toggle-invoicer" that runs the
command inside docker.  Because of this, the only thing you need is docker.

A Makefile is included ot build the image and install/uninstall the wrapper
script. You need "make" in order to use that.  You could install the wrapper
script by hand as well.

## Installation

Either run ```make build```, or, pull mschout/toggl-invoicer:latest from docker
hub to get the docker image.

1. You should edit the CLI wrapper script in ```bin/toggl-invoicer-wrapper```
   to reflect where you would like to store your invoices as well as where your
   ```config.ini``` is.  I use Dropbox to sync my invoices and config across my
   machines, so the default paths use Dropbox.

2. Copy ```config.ini``` to the location you specified in the wrapper script
   and edit it accordingly.  At a minimum, you must set your
   [Toggl](https://toggl.com) API key.

3. Either copy the ```bin/toggl-invoice-wrapper``` to a location in your $PATH
   of your choosing, or, run ```make install``` to install it to
   /usr/local/bin.

## Usage

The wrapper script mounts your config file and invoices directory into the
docker container when it runs.  Because of this, you should not use the
```--invoice-dir``` option when running from the wrapper script.  The usage
here assumes the wrapper script is in use.

All commands include a ```--help``` option that explains their usage.

## Environment Variables

The wrapper script recognizes the following Environment Variables:

### `TOGGL_INVOICE_TEMPLATE`

If set and is the path to a file, this will be used as the XeLaTeX template
that your invoice will be generated from, instead of `template.tex` from this
distribution.

E.g.:

```
TOGGL_INVOICE_TEMPLATE=$HOME/etc/toggl/custom-template.tex
```

### `CONFIG_FILE`

The path to `config.ini` on your system.

### `INVOICE_DIR`

The path where invoices will ge stored.

## Example Usage

### Generate a new invoice for the current month

```
toggl-invoicer generate
```

You can also generate the PDF file at the same time by passing the `--compile`
command line argument:

```
toggle-invoicer generate --compile
```

### Generate a new invoice for a specific month

You can generate an invoice for a specific month using YYYY-MM syntax to
specify the month name.

```
toggl-invoicer generate 2018-02
```

### Override the Invoice Number

The default is to generate the next invoice number in the sequence where the
invoice number is the current year and a three digit sequence number.  If you
want to generate a specific invoice number you can use the
```--invoice-number``` option

```
toggl-invoicer generate --invoice-number 123456
```

### Compile a .tex Invoice to PDF

You only need to provide the invoice number for the invoice to compile.  The
PDF will saved in the same directory as the .tex file.

```
toggl-invoicer compile 2018001
```
