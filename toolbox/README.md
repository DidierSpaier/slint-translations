The script `toolbox.sh` is used for internationalization of all shell scripts in this repository, mainly to build the POT files.

These POT files are uploaded to a translation platform used by the Slint
translators, either using the web editor of the platform or downloading the PO
files for local translation then uploading the edited PO file.

`toolbox.sh` can also be used outside Slint to manage translation of shell scripts.

* To create a POT file, the scripts should be in `scripts`. The POT file is written in `wip`.
* To check that all strings marked for extraction are extracted, the POT file should be in `wip`
  and the scripts in `scripts`.
* To initialize a PO file, the POT file should be in `wip` and the PO file will also be written
  in `wip`. 
* To check  PO files against a POT file, the POT file and the PO files should both be in `wip`
* To merge (or update) PO files after an update of the POT file, the POT file should be in `wip`
  and the PO file(s) in `po`. The merged PO files will be written in
* To format a PO file (build an MO or Machine Object file), the PO file should be in `po` or in
  `wip` depending on the function used (format_PO or format_PO_wip).The MO file will be written
  in `wip`

To generate a POT file <name>.pot from <name>.adoc (used in Slint for HandBook.adoc
and homepage.adoc) the following command can be used, where name=HandBook or name=homepage:
po4a-gettextize -f asciidoc -o compat=asciidoctor -m ${name}.adoc -M UTF-8  -p ${name}.po
This command can be used to initialize an POT file from an asciidoc file (asciidoctor variant)
