This repository gathers all files involved in translation of shell scripts and
documents provided in the Slint distribution and its website https://slint.fr

Readers not accustomed with internationalization and localization can read:
https://slint.fr/doc/internationalization_and_localization_of_shell_scripts.html 

For Slint the `po4a` application is used to process documents in asciidoc
format and the Crowdin platform https://crowdin.com/project/slint is used by
translators to download and upload the PO files and optionally translate
on-line.
The translation manager can use the `crowdin` client application to to manage
the files transfers from/to the Crowdin platform.

Content of the main directories:
* `configuration`: configuration files for `po4a` and the `crowdin` client
  application.
* `po`: POT and PO files
* `toolbox`: helpers for translation of shell scripts. 
* `sources`: internationalized shell scripts, and documents in asciidoc format,
   to be translated.
* `translations`: translations of documents in `sources`, in the same formats. 

All shell scripts from which text strings are extracted and gathered in a
single POT file are stored in a sub-directory of `sources`, like slint-scripts
for slint-scripts.pot. Instead there is only one document in asciidoc format  
in `sources` of which text strings are extracted in POT file.
For each POT file there is a sub-directory under `po` gathering the POT file
and the corresponding PO files, and sub-directories under `sources` and
`translations` with the same name.

When running `po4a` the path to the configuration file should be given as
argument of the command. For instance to update the translations of HandBook
after an update of its associated PO files, one would type from here:
po4a --no-update configuration/HandBook.cfg
The paths in the configuration file are relative to the directory from which
`po4a` is run, not from where the configuration file is stored.

When running `crowdin` the path to the configuration file should be given
as argument of the -c or --config= option. For instance to download all
translations (in PO format) of files mentioned in configuration/crowdin.yml
one would type from here:
crowdin download translations -c configuration/crowdin.yml
The paths in the configuration file are relative to the variable "base-paths"
in crowdin.yml, itself relative to the directory from which `crowdin` is run,
not from where the configuration file is stored.

Recommendation: if Crowdin holds the PO files, only use `po4a` to build a POT
file from a source file and convert PO files to the source file's format, not
to write or up update the PO files: Crowdin writes the initial PO files from
the POT file, and updates them when the POT file is updated.
So, at step 8 below always run `po4` with the --no-update option.

We will describe below the processes involved for providing translations to be
included in the Slint installer, Slint systems and the website https://slint.fr

Upon creation of a new source file:
1. If the source file is a shell script, its writer identify the text strings
   to be translated and marking them as such in the script itself. This step
   is not necessary if the source file is a document in asciidoc format.
2. The translation manager stores the source file in the relevant sub-directory
   of the `sources` directory.
3. The translation manager converts the source file to a POT file and stores
   it in the relevant sub-directory of the `po` directory. The conversion is
   done, depending on the format of the source file:
   . In case of a shell script running `xgettext`, directly or through the 
     script `toolbox.sh` provided in the `toolbox` directory.
   . In case of an document in asciidoc format, running command like 
     po4a-gettextize -f asciidoc -o compat=asciidoctor -m ${name}.adoc -M UTF-8  -p ${name}.po
     or alternatively run "po4a ${name}.cfg" with this content in ${name}.cfg:
     [po4a_langs]  # Empty section, no translations, just create .pot
	 [po4a_paths] ${name}.pot
	 [type: asciidoc] ${name}.adoc opt:"compat=asciidoctor"
	 [options] --master-charset UTF-8
	 The value $name above being for instance HandBook or homepage.
4. The translation manager up uploads the POT file to Crowdin using the
   `crowdin` client application.
5. Crowdin automatically creates the PO files.
6. The translator either translate directly in Crowdin, or download the PO
   file, translate it using a PO editor then upload the edited PO file to
   Crowdin.
7. The translation manager downloads the translations in PO format using
   `crowdin` to the relevant sub-directory of the `po` directory.
   The crowdin.ymlf configuration file being stored in ./confuguration
   this comand can be used:
   crowdin download trhanslations -c=./configuration/crowdin.yml
8. The translation manager converts the PO file to a translated file that will
   be stored in the relevant sub-directory of the `translations` directory. 
   The conversion is done, depending on the format of the source file:
   . In case of a shell script running `msgfmt`, directly or using the
     script `toolbox.sh` provided in the `localisation_toolbox` directory.
     In this case the translation in the MO format.
   . In case of an document in asciidoc format, running `po4a` with as argument
     the relevant configuration file in the `configuration` folder and the
     --no-update option.
     In this case the translation is in the asciidoc format, that will be
     later converted to html with the `asciidoc` or `asciidoctor` application.
9. How the translations are used depends on the translation unit:
   . The translations of `slint-scripts` are included in a Slint package also
     named slint-scripts.
   . The translations of `auto`, `rc.S` and `SeTkeymap` are included in the
     Slint installer.
   . The translations of `HandBook`, `homepage` `news` and of the articles
     included in `wiki` are converted to html by the script build_website.sh
     available in https://github.com/DidierSpaier/slint-website that then
     uploads them to the https://slint.fr web site
   . The translations of `HandBook` are also converted to html by the script
     slint-docs.SlackBuild that builds the slint-doc package to install in
     the system the translated HandBook, allowing to read it off line.

In case of an update of an already translated source file:
. at step 4 the updated POT file is uploaded by the translation manager,
. at step 5 Crowdin automatically updates existing PO files accordingly,
. at step 6 the translators edit them as need be, adding or editing translated
  text strings.
