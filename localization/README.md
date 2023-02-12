The script `toolbox.sh` is used for internationalization of all shell scripts in this repository, mainly to build the POT files.

These POT files are uploaded to a translation platform (Crowdin or Transifex) used by the Slint
translators, either using the web editor of the platform or downloading the PO files for local
translation. The completed translations are downloaded in their respective directories in this
repository.

`toolbox.sh` can also be used outside Slint to manage translation of shell scripts.

* To create a POT file, the scripts should be in `scripts`. The POT file is written in `wip`.
* To check that all strings marked for extraction are extracted, the POT file should be in `wip` and the scripts in `scripts`.
* To initialize a PO file, the POT file should be in `wip` and the PO file will also be written in `wip`. 
* To check  PO files against a PO file, the POT file and the PO files should both be in `wip`
* To merge (or update) PO files after an update of the POT file, the POT file should be in `wip` and the PO file(s) in `po`. The merged PO files will be written in
* To format a PO file (build an MO or Machine Object file), the PO file should be in `po` or in `wip` depending on the function used (format_PO ot format_PO_wip).The MO file will be written in `wip`

To generate a POT file <name>.pot from <name>.adoc (used in Slint for HandBook.adoc and homepage.adoc) the following command can be used, where name=HandBook or name=homepage:
This command can be used to initialize an POT file from an asciidoc file (asciidoctor variant)
po4a-gettextize -f asciidoc -o compat=asciidoctor -m ${name}.adoc -M UTF-8  -p ${name}.pot

After an update of ${name}.adoc, update (not recreate) ${name}.pot, like this:
po4a-updatepo -M UTF-8 -m ${name}.adoc -f asciidoc -p ${name}.pot

To convert back a PO file to asciidoc format a command like this one can be used example for French as sopekn in France:
po4a-translate -f asciidoc -m HandBook.adoc -M UTF-8 -l fr_FR.${name}.adoc -p fr_FR.${name}.po
