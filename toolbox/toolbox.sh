#!/bin/bash
# shellcheck disable=SC1091,SC2034
# Initially written by Didier Spaier, Paris, France 2013-2022
# Public domain
if [ $UID -eq 0 ]; then
	echo "Please execute this script as a regular user, not as root."
	exit
fi
rm -f name 
DATESTAMP=$(date -u +%Y%m%d)
for i in docs po scripts tmp wip; do
	[ ! -d $i ] && "echo the directory ./$i is missing." && exit
done
ROOT=$(pwd)
TMP=$ROOT/tmp
# Possibly creates a Work In Progress directory.
# This function requests a locale from the user.
# ${LOCALE} should be an ISO 639-1 two-letters language code, followed by
# an underscore "_" and an ISO 3166 two-letters country code (but no,
# we won't go as far as checking ${LOCALE} against these standards :-)
# We accept only locales for which an UTF-8 encoding is available.
get_locale () {
	dialog --no-collapse --title " Which locale ? " \
	--inputbox "Please type the locale code in \
the form ll_TT. For instance you would type:
nl_NL for Dutch as spoken in the Netherlands
pt_BR for Brazilian Portuguese
The locale should be available in your Linux system with an UTF-8 \
encoding" 12 80 2>"$TMP"/reply2
	LOCALE="$(cat "$TMP"/reply2)"
	rm -f "$TMP"/reply2
	if [ -z "$LOCALE" ]; then
		return
	fi
	ERROR=""
	if [ "$(locale -a|grep "${LOCALE}".utf8)" = "" ]; then
		ERROR="Sorry, locale \"${LOCALE}.utf8\"  \
is not available in this Linux system."
		TITLE=" Locale unavailable "
	fi
	if [ ! "$ERROR" = "" ]; then
		dialog --title "$TITLE" --msgbox "$ERROR" 7 80
		get_locale
	fi
	PO="${LOCALE}".$(<"$ROOT"/name).po
	export PO
}
# We check that "export TEXTDOMAIN=" be set in all scripts with the same
# value. If not bail out, else write the value in ./name 
cd "$ROOT"/scripts || exit
_textdomains=$(mktemp)
rm -f "$ROOT"/bad
find . -type f|while read -r i; do
	if ! grep -q "export TEXTDOMAIN=*" "$i"; then
		_filename="$ROOT/scripts/$i"
		echo "The file  $_filename
is missing a line beginning with \"export TEXTDOMAIN=\".
Please fix it and try again."
		echo "bad" > "$TMP"/bad
	else
		grep "export TEXTDOMAIN=" "$i" >> "$_textdomains"
	fi
done
[ -s "$TMP"/bad ] && rm -f "$TMP"/bad && exit
if [ ! "$(sort "$_textdomains"|uniq|wc -l)" = 1 ] ; then
	echo "Not all scripts export the same TEXTDOMAIN. 
Please fix that then try again."
	echo "bad" > "$TMP"/bad
else
	sed 's/export TEXTDOMAIN=//' "$_textdomains" > "$ROOT"/name
	name=$(<"$ROOT"/name)
fi
[ -s  "$TMP"/bad ] && rm -f "$TMP"/bad && exit
cd "$ROOT" || exit
# Ihis function generates POT file in $ROOT/wip
# Strings to be localized are extracted from scripts in $ROOT/scripts
make_POT () {
	# --from-code=UTF-8 just in case, however improbable. Shouldn't hurt as
	# ASCII is a subset of UTF-8.
	# --foreign-user as we don't want the FSF copyright in the translations.
	# We will include in the template catalog strings extracted from files:
	# included in the ${TARGET}/source directory...
	# ... *and* listed in the lists of relevant files in ${TARGET}/files
	cd "$ROOT"/scripts || exit
	POT="$ROOT"/wip/"$name".pot
	xgettext --from-code=UTF-8 -L Shell --force-po --strict -c -n \
	--package-name="$name" --package-version="$DATESTAMP" \
	--foreign-user -d "$name" -o "$POT" "$(find . -type f)"
	cd "$ROOT" || exit
	sed -i 's/charset=CHARSET/charset=UTF-8/' "$POT"
	Result="The POT file: ${POT} has been generated"
}
# This function checks all source scripts. It warns whenever a string marked
# with *gettext is not extracted in the POT file, possibly due to a typo or
# the source script failing to comply to *gettext's requirements.
check_xtract () {
	rm -f "$TMP"/check_scripts.log
	touch "$TMP"/check_scripts.log
	POT=$ROOT/wip/"name".pot
	if [ ! -f "${POT}" ]; then
		make_POT
	fi
	rm -f "$TMP"/strings_to_be_extracted
	touch "$TMP"/strings_to_be_extracted
	( cd "$ROOT"/scripts || exit
	while read -r i; do
		grep -noHP 'gettext(?!.sh)' "$i"|sed 's/:gettext//' >> "$TMP"/strings_to_be_extracted
	done <<< "$(ls "$ROOT"/scripts)"
	)
	previous="dummy:0"
	echo $previous >> "$TMP"/strings_to_be_extracted
	errors=0
	lines=0
	while read -r line; do
		if  [ "$line" = "$previous" ]; then
			previous=$line
			((lines++))
			continue
		fi
		SCRIPT=${previous%:*}
		numline=${previous#*:}
		extracted=$(grep -c " ${SCRIPT}, line: ${numline}"$ "${POT}")
		if [ ! "${lines}" -eq "${extracted}" ]; then
			echo "In script $SCRIPT line #$numline: $lines but in POT file: $extracted" > "$TMP"/check_scripts.log
			((errors++))
		fi
		lines=1
		previous=$line
	done < "$TMP"/strings_to_be_extracted
	if [ "$errors" -eq 0 ]; then
			Result="Good, all messages from scripts in:
$ROOT/scripts
have been properly extracted in template catalog:
${POT}"
	else
		Result="$errors strings were not extracted in:
${POT}
Check the log:
$TMP/check_scripts.log"
	fi
}
# This function initializes a PO file for ${LOCALE} in $ROOT/wip.
init_PO () {
	POT=$ROOT/wip/"$name".pot
	if [ ! -f "${POT}" ]; then
		make_POT
	fi
	msginit -l "${LOCALE}".utf8 -o "$ROOT"/wip/"$PO"   \
	-i "$ROOT"/wip/"$name".pot > "$ROOT"/tmp/msginit
	echo "The PO file $ROOT/wip/${PO}
for the \"${LOCALE}\" locale has been initialized."
}
# This function checks a PO file against the POT file.
check_PO () {
	POT=$ROOT/wip/"name".pot
	if [ ! -f "${POT}" ]; then
		make_POT
	fi
	msgcmp "$ROOT"/wip/"$PO"   \
	"$POT" 2>"$TMP"/foutput2
}
# This function generates a MO file in $ROOT/wip from a PO file
# in $ROOT/wip.
format_PO () {
	echo "Results of formatting command:
	" >"$TMP"/foutput
	MO="${LOCALE}"."$name".mo
	msgfmt --strict -c -v --statistics -f \
	-o "$ROOT"/wip/"$MO" \
	"$ROOT"/po/"$PO" 2>>"$TMP"/foutput
	echo "
If the command was successful, $ROOT/wip/${MO} \
has been generated." >>"$TMP"/foutput
}
format_PO_wip () {
	echo "Results of formatting command:
	" >"$TMP"/foutput
	MO="${LOCALE}"."$name".mo
	msgfmt --strict -c -v --statistics \
	-o "$ROOT"/wip/"${MO}" \
	"$ROOT"/wip/"$PO"   2>>"$TMP"/foutput
	echo "
If the command was successful, $ROOT/wip/${MO} \
has been generated." >>"$TMP"/foutput
}
# This function updates a PO file to follow up a modification of the
# reference POT file. The new file is written in $ROOT/wip.
merge_PO () {
	POT=$ROOT/wip/"name".pot
	if [ ! -f "$POT" ]; then
		make_POT
	fi
	msgmerge --strict --no-fuzzy-matching --add-location -v -o "$ROOT"/wip/"$PO" \
	"$ROOT"/po/"$PO"   "${POT}"
	echo >> "$TMP"/foutput
	echo "The new PO file $ROOT/po/${PO} is ready to \
be updated." >>"$TMP"/foutput
}
merge_all () {
	POT=$ROOT/wip/"name".pot
	if [ ! -f "${POT}" ]; then
		make_POT
	fi
	echo > "$TMP"/foutput
	( cd "$ROOT"/po || exit
	find . -name "*po"|sed 's#..##'|while read -r i; do
	    {
		msgmerge --strict --no-fuzzy-matching -v -o "$ROOT"/wip/"$i" \
		"$ROOT"/po/"$i" "${POT}"
		} 2>>"$TMP"/foutput
		echo "done" >>"$TMP"/foutput
	done
	)
}
check_all () {
	POT=$ROOT/wip/"name".pot
	if [ ! -f "${POT}" ]; then
		make_POT
	fi
	( cd "$ROOT"/po || exit
	while read -r "i"; do
		msgcmp "$ROOT"/wip/"$i" "$POT" 2>"$ROOT"/wip/err."$i"
	done < "$(find . -name "*po")"
	)
}
# Main
while true; do
	if ! dialog --title " Slint Toolbox " \
	 --nocancel --nook --menu "Welcome to the Slackware Internationalizer Toolbox.
Navigate in this menu with the up and down arrow keys.
Press Enter to read a highlighted document.
Press Q to stop reading a document and go back to the menu.
Press Escape to quit." 0 0 14 \
"Help" "Help for using this menu" \
"Utilization" "Purpose and utilization of the toolbox" \
"Workflows" "Show tools in the context of their usage" \
"Documentation" "Internationalization and localization of shell scripts" \
"make_POT" "Generate a new POT file" \
"check_xtract" "Check proper messages' extraction from scripts" \
"init_PO" "Initialize a PO file for a given locale" \
"check_PO" "Ensure that all messages be translated in a PO file" \
"check_all" "Check all PO files" \
"format_PO" "Generate a MO file for a given locale" \
"format_PO_wip" "Generate a MO file for a given locale from $ROOT/wip" \
"merge_PO" "Update a PO file following an update of the POT file" \
"merge_all" "Update all PO files following an update of the POT file" 2> "$TMP"/reply; then
		rm -f "$TMP"/reply
		dialog --clear
		clear
		exit
	fi
	REPLY="$(cat "$TMP"/reply)"
	rm -f "$TMP"/reply
# Help
	if [ "$REPLY" = "Help" ]; then
		most docs/"$REPLY"
	fi
# Utilization
	if [ "$REPLY" = "Utilization" ]; then
		most "$ROOT"/docs/"$REPLY"
	fi
# Workflows
	if [ "$REPLY" = "Workflows" ]; then
		most "$ROOT"/docs/"$REPLY"
	fi
# Documentation
	if [ "$REPLY" = "Documentation" ]; then
		while [ -n "$REPLY" ]; do
		dialog --title " Internationalization and localization of shell scripts " \
		 --nocancel --nook --menu \
		"To go back to the main menu press Escape.
Use a mono-spaced font and an UTF-8 encoding for a proper display." 0 0 6 \
		"1_PRESENTATION" "General presentation" \
		"2_DIAGRAMS" "Processes diagrams" \
		"3_INTERNATIONALIZATION" "Internationalization process" \
		"4_LOCALIZATION" "Localization, usage and maintenance processes" \
		"5_MAINTAINERS" "Recommendations for developpers and maintainers" \
		"6_TRANSLATORS" "Recommendations for translators" \
		2>"$TMP"/reply
		REPLY="$(cat "$TMP"/reply)"
		rm -f "$TMP"/reply
		if [ -n "$REPLY" ]; then
			most "$ROOT"/docs/i18n_scripts/"$REPLY"
		fi
		done
	fi
# make_POT
	if [ "$REPLY" = "make_POT" ]; then
		make_POT
		dialog --title "Results the command $REPLY" --msgbox \
		"$Result" 0 0
	fi
# check_xtract
	if [ "$REPLY" = "check_xtract" ]; then
		check_xtract 2>erreurs
		rm -f "$TMP"/strings_to_be_extracted
		dialog --title "Results of command $REPLY $SCRIPT" --msgbox \
		"$Result"  0 0
	fi
# init_PO
	if [ "$REPLY" = "init_PO" ]; then
		get_locale
		if [ -z "$LOCALE" ]; then
			continue
		fi
		if [ -f "$ROOT"/po/"$PO" ] || [ -f "$ROOT"/wip/"$PO" ]; then
			dialog --title " PO file already exists " --msgbox \
			"There is already a PO file $PO in:
$ROOT/po
and/or in:
$ROOT/wip" 0 0
			continue
		fi
			Result="$(init_PO "$LOCALE")"
			dialog --title " Results of command $REPLY $LOCALE" --msgbox \
			"$Result"  0 0
	fi
# check_PO
	if [ "$REPLY" = "check_PO" ]; then
		get_locale
		if [ -z "$LOCALE" ]; then
			continue
		fi
		if [ ! -f "$ROOT"/wip/"$PO" ]; then
			dialog --title "No PO file to check"--msgbox \
			"There is no PO file $PO in \
			$ROOT/wip"0 0
			continue
		fi
		check_PO
		if [ -s "$TMP"/foutput1 ]; then
			dialog --title " Results of command: $REPLY $LOCALE"--msgbox "$(cat "$TMP"/foutput1)"  0 0
			rm -f "$TMP"/foutput1
		elif [ -s "$TMP"/foutput2 ]; then
			mv -f  "$TMP"/foutput2 "$TMP"/"${REPLY}"."${LOCALE}".log
			dialog \
			--title " Results of command: $REPLY $LOCALE"\
			--no-collapse --exit-label OK --msgbox \
			"$(<"$TMP"/"${REPLY}"."${LOCALE}".log)" 0 0
		else
			dialog \
			--title " Results of command: $REPLY $LOCALE"\
			--no-collapse --exit-label OK --msgbox \
			"All messages in POT file:
$POT
are translated in PO file:
$ROOT/wip/${PO}
which could now be moved to $ROOT/po" 0 0
		fi
	fi
# format_PO
	if [ "$REPLY" = "format_PO" ]; then
		get_locale
		if [ -z "$LOCALE" ]; then
			continue
		fi
		if [ ! -f "$ROOT"/po/"$PO" ]; then
			dialog --title "No PO file to format"--msgbox \
			"There is no PO file $PO to check in \
			$ROOT/po"0 0
			continue
		fi
		$REPLY "$LOCALE"
		dialog --title " Results of command: $REPLY $LOCALE"--msgbox "$(cat "$TMP"/foutput)"  0 0
	fi
# format_PO_wip
	if [ "$REPLY" = "format_PO_wip" ]; then
		get_locale
		if [ -z "$LOCALE" ]; then
			continue
		fi
		if [ ! -f "$ROOT"/wip/"$PO" ]; then
			dialog --title "No PO file to format"--msgbox \
			"There is no PO file $PO to check in \
			$ROOT/wip"0 0
			continue
		fi
		$REPLY "$LOCALE"
		dialog --title " Results of command: $REPLY $LOCALE"--msgbox "$(cat "$TMP"/foutput)"  0 0
	fi
# merge_PO
	if [ "$REPLY" = "merge_PO" ]; then
		get_locale
		if [ -z "$LOCALE" ]; then
			continue
		fi
		if [ -f "$ROOT"/wip/"$PO"   ]; then
			dialog --title "Already merged ?" --msgbox \
			"Please dispose of $ROOT/wip/${PO} before using the \"merge\" function. \
			Maybe this translation was complete and you forgot to move it to \
			$ROOT/po?" 0 0
			continue
		fi
		if [ ! -f "$ROOT"/po/"$PO" ]; then
			dialog --title "No PO file to merge"--msgbox \
			"There is no PO file $PO to merge in \
			$ROOT/po"0 0
			continue
		fi
		$REPLY "$LOCALE"
		dialog --title " Results of command: $REPLY $LOCALE"--msgbox "$(cat "$TMP"/foutput)"  0 0
		rm -f "$TMP"/foutput
	fi
# merge_all
	if [ "$REPLY" = "merge_all" ]; then
		EXISTING=$(find "$ROOT"/wip/ -name "*.po")
		if [ ! "$EXISTING" = "" ]; then
			dialog --title "Already merged ?" --msgbox \
			"Please dispose of $EXISTING before using the \"merge_all\" function." 0 0
			continue
		fi
		$REPLY
		dialog --title " Results of command: $REPLY $LOCALE"--msgbox "$(cat "$TMP"/foutput)"  0 0
		rm -f "$TMP"/foutput
	fi
# check-all
	if [ "$REPLY" = "check_all" ]; then
		$REPLY
		dialog --title " Results of command: $REPLY"--msgbox "See the results in $ROOT/wip"  0 0
	fi
# Exit
	if [ "$REPLY" = "Exit" ]; then
		dialog --clear
		rm -f "$TMP"/foutput* "$TMP"/reply* "$TMP"/*check
		clear
		echo "Thank you for having used this toolbox."
		echo
		exit
	fi
done
