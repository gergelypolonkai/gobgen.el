# GobGen

Generate boilerplate code for a GObject descendant in Emacs.

## Usage

1. Execute `M-x gobgen`
2. Specify a class name in snake_case
3. Specify a parent class name in snake_case
3. If the guessed prefixes are not OK, fix them
4. Check GLib >= 2.38 if you are building for new(ish) GLib
   versions. This puts some optimalizations in the code, like makes
   use of macros like `g_object_get_private`
5. Check Has private members if you want to add a private struct to
   your object

## Installation

1. Clone this repository and add it to your `load-path`
2. `(require 'gobgen)`

## Contributing

If you have a feature idea or find a bug, feel free to issue a pull
request. If you need any help with the code, find me on Matrix
as
[@gergely.polonkai.eu](https://riot.im/app/#/user/@gergely:polonkai.eu)

## Credits

This package is heavily based on Gustavo Sverzut
Barieri’s
[gobject-class.el](https://www.emacswiki.org/emacs/gobject-class.el).

## Future plans

There are tons of features I plan, here is a brief list:

* Properties
* Signals
* Pre-define methods, virtual or not
* Add GTK-Doc blocks for for the generated code
* Widget specialization
** Standalone with custom `render()` method
** Composite
** Templated composite, that should also create a `GtkBuilder`
   template
* Add some help text for fields
* GLib requirement check (if 2.38 is turned on)
* Possibly add a `GET_PRIV` macro for 2.38+

## Requirements

`gobgen.el` depends only on the Emacs widget library.

Tested on Emacs 24.3 and 25.1, please report if you succeed (or fail)
on other versions!
