#Here is the comand used to generate HandBook.pot from HandBook.adoc:
adoctopot() {
po4a-updatepo -f asciidoc -m source/${1}.adoc -M UTF-8 -p POT/${1}.pot
}
adoctopot $1
