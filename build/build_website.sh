#!/bin/sh
export CWD=$(pwd)
WIP=$CWD/wip
rm -r $WIP
mkdir -p $WIP/html $WIP/css
cd $WIP/html
LANGUAGES="el en fr it nl pt sv"
ALL_LANGUAGES="de el en es fr it ja jp nl pl pt pt_PT pt_BR ru sv uk"
mkdir doc $ALL_LANGUAGES
SLINTDOCS=/data/DidierSpaier/slint-translations
PAGES="home HandBook oldHandBook support"
# We rebuild the whole website locally from scratch upon each update.
# But we will make a local rsync on the server html => server root
# We assume that this directory includes in ./adoc
# all .adoc files in the same hierarchy as in the wesbsite
# the stylesheet is stored in ./css
# All pages are in folders by language, not in the web site directory
# as in the website up to slint-14.1.
#LANGUAGES="de el en es fa_IR fr ia id it nl pl pt_BR pt_PT ru sv tr uk"
# The header of each page will include the list of languages in which it is available
# This is true for:
# homepage => home.html
# support => support.html
# If a page is not translated in a given language, it will be displayed in English
# (though a hard link if that works).
# The list of languages will not be included in the header of the pages only
# in Englsh, i.e. translate and ChangeLog.
# All pages include a header with links to:
# Home Documentation Download Support Translate ChangeLog
# I am unsure if I should include all unformation in the Home page or make a separate About
# as Crux https://crux.nu/Main/About
# Maybe also rename Support as Community and later write a Packages or Software page.

# PO files use the ll_TT scheme, but unless there be several locales per language,
# We store the web pages in directories named $ll
# list the per language directories we create, to store in them the English
# verson of files not available in this language.
# We first need to build the header.html files. they include a line of links,
# then a line of languages in other languages in which each page is available
# To select the languages to include we need to know in which languages
# each page has been translated. but as the support pages are built extracting
# parts of the handbook we need only to check HandBook and homepage.
# Use pocount to check the %translated, see also msgattrib.
feed_support_and_documentation() {
	# support is extracted from HandBook
	cd $SLINTDOCS/HandBook/
	msgen HandBook.pot -o en_US.HandBook.po
	langs="$(ls  *po|cut -d_ -f1)"
	header_handbook="$(echo "$langs"|sort|while read i; do echo "* link:../$i/HandBook.html[$i] "; done)"
	header_support="$(echo "$langs"|sort|while read i; do echo "* link:../$i/support.html[$i] "; done)"
	for handbookpo in $(ls *.HandBook.po); do
		ll_TT=$(echo ${handbookpo%.*.*})
		echo $ll_TT >> $WIP/languages
		ll=${ll_TT%_*}
		cp ../headers/$ll_TT.header.adoc $WIP
		echo "$header_handbook" >> $WIP/$ll_TT.header.adoc
		echo "--"  >> $WIP/$ll_TT.header.adoc
		echo >> $WIP/$ll_TT.header.adoc
		echo 'toc::[left]' >> $WIP/$ll_TT.header.adoc
		po4a-translate -M UTF-8 -m $SLINTDOCS/source/HandBook.adoc -f asciidoc -p $handbookpo -l $WIP/${ll_TT}.HandBook.part.adoc
		cat $WIP/$ll_TT.header.adoc $WIP/${ll_TT}.HandBook.part.adoc > $WIP/${ll_TT}.HandBook.adoc
		asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a copycss=$SLINTDOCS/css/slint.css -D $WIP -a doctype=book $WIP/${ll_TT}.HandBook.adoc -o $WIP/html/$ll/HandBook.html
		sed -i 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@'  $WIP/html/$ll/HandBook.html
	done
	for handbookpo in $(ls *.HandBook.po); do
		ll_TT=$(echo ${handbookpo%.*.*})
		echo $ll_TT >> $WIP/languages
		ll=${ll_TT%_*}
		cp ../headers/$ll_TT.header.adoc $WIP
		echo >> $WIP/$ll_TT.header.adoc
		echo "$header_support" >> $WIP/$ll_TT.header.adoc
		echo "--"  >> $WIP/$ll_TT.header.adoc
		echo >> $WIP/$ll_TT.header.adoc
		echo 'toc::[]' >> $WIP/$ll_TT.header.adoc
		po4a-translate -M UTF-8 -m $SLINTDOCS/source/HandBook.adoc -f asciidoc -p $handbookpo -l $WIP/${ll_TT}.HandBook.part.adoc
		sed -n "\@// Support@,\@// Acknowledgments@p" $WIP/${ll_TT}.HandBook.part.adoc|head -n -1  \
		| sed "s@// .*@[.debut]@" >> $WIP/${ll_TT}.support.part.adoc
		cat $WIP/$ll_TT.header.adoc $WIP/${ll_TT}.support.part.adoc > $WIP/${ll_TT}.support.adoc
		asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a copycss=$SLINTDOCS/css/slint.css -D $WIP $WIP/${ll_TT}.support.adoc -o $WIP/html/$ll/support.html
		sed -i 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@'  $WIP/html/$ll/support.html
	done
}
feed_homepage() {
	cd $SLINTDOCS/homepage/
	msgen ../homepage.pot -o en_US.homepage.po
	langs="$(ls  *po|cut -d_ -f1)"
	header_homepage="$(echo "$langs"|sort|while read i; do echo "* link:../$i/home.html[$i] "; done)"
	for homepagepo in $(ls *.homepage.po); do
		ll_TT=$(echo ${homepagepo%.*.*})
		ll=${ll_TT%_*}
		cp ../headers/$ll_TT.header.adoc $WIP
		echo "$header_homepage" >> $WIP/$ll_TT.header.adoc
		echo >> $WIP/$ll_TT.header.adoc
		echo "--" >> $WIP/$ll_TT.header.adoc
		echo >> $WIP/$ll_TT.header.adoc
		echo 'toc::[]' >> $WIP/$ll_TT.header.adoc
		echo >> $WIP/$ll_TT.header.adoc
		pwd
		echo "po4a-translate -M UTF-8 -m $SLINTDOCS/source/homepage.adoc -f asciidoc -p $homepagepo -l $WIP/${ll_TT}.homepage.part.adoc"
		po4a-translate -M UTF-8 -m $SLINTDOCS/source/homepage.adoc -f asciidoc -p $homepagepo -l $WIP/${ll_TT}.homepage.part.adoc
		cat $WIP/$ll_TT.header.adoc $WIP/${ll_TT}.homepage.part.adoc > $WIP/${ll_TT}.homepage.adoc
		asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a copycss=$SLINTDOCS/css/slint.css -D $WIP -a doctype=book $WIP/${ll_TT}.homepage.adoc -o $WIP/html/$ll/home.html
		sed -i 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' $WIP/html/$ll/home.html
		sleep 1
	done
}
install_the_previous_version() {
	cd $SLINTDOCS/prev
	for i in en fr ru; do
		for j in $(ls $i|grep adoc); do 
			asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a copycss=$SLINTDOCS/css/slint.css -D $WIP $i/$j -o $WIP/html/$i/${j%adoc}html
		done
	done
	cp -r media/* $WIP/html
}
feed_HandBook14_2_1() {
	cd $SLINTDOCS/HandBook14.2.1 || exit 1
	langs=$(echo "de el en es fr it ja nl pl pt pt_BR ru sv uk"|sed "s/ /\n/g")
	header_oldhandbook="$(echo "$langs"|while read i; do echo "* link:../$i/oldHandBook.html[$i] "; done)"
	for handbookadoc in $(ls *.HandBook.adoc); do
		ll_TT=$(echo ${handbookadoc%.*.*})
		echo $ll_TT >> $WIP/languages
		ll=${ll_TT%_*}
		cp ../headers/$ll_TT.header.adoc $WIP
		echo >> $WIP/$ll_TT.header.adoc
		echo "$header_oldhandbook" >> $WIP/$ll_TT.header.adoc
		echo "--" >> $WIP/$ll_TT.header.adoc
		echo >> $WIP/$ll_TT.header.adoc
		echo 'toc::[]' >> $WIP/$ll_TT.header.adoc
		cat $WIP/$ll_TT.header.adoc $ll_TT.HandBook.adoc > $WIP/${ll_TT}.oldHandBook.adoc
		if [ "$ll_TT" = "pt_BR" ]; then
			asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a copycss=$SLINTDOCS/css/slint.css -D $WIP -a doctype=book $WIP/${ll_TT}.oldHandBook.adoc -o $WIP/html/$ll_TT/oldHandBook.html
			sed -i 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@'  $WIP/html/$ll_TT/oldHandBook.html
		else
			asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a copycss=$SLINTDOCS/css/slint.css -D $WIP -a doctype=book $WIP/${ll_TT}.oldHandBook.adoc -o $WIP/html/$ll/oldHandBook.html
			sed -i 's@<p><a@<a@;s@</a></p>@</a>@;/langmen/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@'  $WIP/html/$ll/oldHandBook.html
		fi
	done
}
complete_missing_with_english() {
	for i in $ALL_LANGUAGES; do
		for j in $PAGES; do
		[ ! -f "$WIP/html/$i/${j}.html" ] && cp $WIP/html/en/${j}.html $WIP/html/$i/${j}.html
		done
	done
}

cp $CWD/htaccess/.htaccess $WIP/html
feed_homepage
feed_support_and_documentation
feed_HandBook14_2_1
complete_missing_with_english
asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a copycss=$SLINTDOCS/css/slint.css -D $WIP  $SLINTDOCS/doc/translate_slint.adoc -o $WIP/html/doc/translate_slint.html
sed -i 's@<p><a@<a@;s@</a></p>@</a>@;/"toc"/s@.*@<p></p>\n&@;/"toc"/s@.*@<p></p>\n&@' $WIP/html/doc/translate_slint.html
asciidoctor -a stylesdir=../css -a stylesheet=slint.css -a linkcss -a copycss=$SLINTDOCS/css/slint.css -D $WIP $SLINTDOCS/doc/internationalization_and_localization_of_shell_scripts.adoc -o $WIP/html/doc/internationalization_and_localization_of_shell_scripts.html
cp $SLINTDOCS/doc/shell_and_bash_scripts.html $WIP/html/doc/
sudo rsync --verbose -avP --exclude-from=$CWD/exclude -H --delete-after $CWD/wip/html/ /var/www/htdocs/
