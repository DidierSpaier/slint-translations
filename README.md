This repository gathers source and translated files for the Slint distributon,
version 15.0

Content of the folders:
source/ internationalized shell scripts, and documents in ascidoc format.
homepage.pot and auto.pot: POT file gathering to be translated strings
extracted from source/homepage and source/auto
HandBook/, rc.S/, homepage/, auto/ contain the translations (PO files)
rc.S/, SetKeymap/ and HandBook/ contain also the POT files gathering to-be
translated strings from the files in source bearing the same name.
the files in rc.S/ are available in Transifex, see rc.S/note
All other POT and PO files are available in Crowdin.
tools/ contain all that is needed to manage the internationalizaton of
shell scripts using gettext tools.
