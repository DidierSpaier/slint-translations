This repository gathers source and translated files for the Slint distribution, version 15.0.

Content of the folders:
* `localization`: all that is needed to manage the internationalization of shell scripts using gettext tools.
* `sources`: internationalized shell scripts, and documents in asciidoc format, in sub-directories. The sub-directories auto, rc.S, SeTkeymap and slints-scripts contain shell scripts from which messages are are extracted using `localization/toolbox.sh` to build POT (portables object templates) files. The sub-directories `Handbook` and `homepage` contain files in asciidoc format, processed by the application po4a to build the POT files. The sub-directory `HandBook14.2.1` contain sources that are frozen, but used to include the HandBook for Slint-14.2.1 in the Slint website https://slint.fr 
* `auto`, `HandBook`, `homepage`, `rc.S`, `SeTkeymap`, `slint-scripts` and the sub-directories of `wiki` contain the POT files built from the sources files in sub-directories of `sources` bearing the same names. Al but SeTkeymap (translated in Transifex) are sent to the Crowdin platform. These directories also contain the translation files in PO format downloaded from the platform.

