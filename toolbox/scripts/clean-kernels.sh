#!/bin/sh
# shellcheck disable=SC1091,SC2034
# This script has been written from scratch and dedicated to the public
# domain by its author: Didier Spaier, Paris.
# For more information, please refer to <http://unlicense.org/>

# Propose to remove all packages kernel, kernel-source and kernel-headers
# with a version number not matching that of the running kernel.
# Then remove the iniramfs not associated to an installed kernel.
export TEXTDOMAIN=clean-kernels
if [ ! "$(id -u)" -eq 0 ]; then
	gettext "Please run this script as root."; echo
	exit
fi
. gettext.sh
LOG=/tmp/clean-boot.log
date >>$LOG
RUNNINGVERSION=$(uname -r)
FRAG='[^-]\{1,\}'
_installed=$(mktemp)
_versions=$(mktemp)
to_lower() {
	echo "$1"|tr '[:upper:]' '[:lower:]'
}
# Propose to remove stale kernel packages
(cd /var/lib/pkgtools/packages || exit
find . -type f|grep "kernel-[^-]*-[^-]*-[^-]*$"|sed 's#..##'|grep -v "$RUNNINGVERSION" >"$_installed"
if [ -s "$_installed" ]; then
	while read -r i <&3; do
		iVERSION=$(echo "$i"|sed "s/.*-\($FRAG\)-$FRAG-$FRAG$/\1/")
		if [ "$iVERSION" = "$RUNNINGVERSION" ]; then
			echo "not removing $i as it is the runnng kernel" >>$LOG
			continue
		fi
		unset ANSWER
		while [ ! "$(to_lower "$ANSWER")" = "yes" ] && [ ! "$(to_lower "$ANSWER")" = "no" ]; do
			eval_gettext "\$i is not in use. Do you want to remove it?"
			echo
			gettext "Type yes or no: "
			read -r ANSWER
			[ ! "$(to_lower "$ANSWER")" = "yes" ] && continue
			echo "spkg -d $i"
			spkg -d "$i"
		done
	done 3<"$_installed"
fi
# Then remove stale kernel-headers and kernel source packages, i.e. those
# whose version does not match that of a remaining kernel package
# List the versions of installed kernels in "$_versions"
find .|grep "kernel-[^-]*-[^-]*-[^-]*$"|sed "s/.*-\($FRAG\)-$FRAG-$FRAG$/\1/" > "$_versions"
# list installed kernel-source packages
find . -type f -name "kernel-source*"|sed 's#..##'> "$_installed"
if [ -s "$_installed" ]; then
	while read -r i <&3; do
		unset ANSWER
		VERSION=$(echo "$i"|sed "s/.*-\($FRAG\)-$FRAG-$FRAG$/\1/")
		if grep -q "$VERSION" "$_versions"; then
			echo "Not removing $i as its version matches that of an installed kernel package." >>$LOG
			continue
		fi
		while [ ! "$(to_lower "$ANSWER")" = "yes" ] && [ ! "$(to_lower "$ANSWER")" = "no" ]; do
			eval_gettext "The version of \$i does not match that of an installed kernel package."
			echo
			gettext "Do you want to remove it? Type yes or no: "
			read -r ANSWER
			[ ! "$(to_lower "$ANSWER")" = "yes" ] && continue
			echo "spkg -d $i" >>$LOG
			spkg -d "$i"
		done
	done 3<"$_installed"
fi
# list installed kernel-headers packages
find . -type f -name "kernel-headers*"|sed 's#..##'> "$_installed"
if [ -s "$_installed" ]; then
	while read -r i <&3; do
		unset ANSWER
		VERSION=$(echo "$i"|sed "s/.*-\($FRAG\)-$FRAG-$FRAG$/\1/")
		if grep -q "$VERSION" "$_versions"; then
			echo "Not removing $i as its version matches that of an installed kernel package." >>$LOG
			continue
		fi
		while [ ! "$(to_lower "$ANSWER")" = "yes" ] && [ ! "$(to_lower "$ANSWER")" = "no" ]; do
			eval_gettext "The version of \$i does not match that of an installed kernel package."
			echo
			gettext "Do you want to remove it? Type yes or no: "
			read -r ANSWER
			[ ! "$(to_lower "$ANSWER")" = "yes" ] && continue
			echo "spkg -d $i" >>$LOG
			spkg -d "$i"
		done
	done 3<"$_installed"
fi
)
# Remove the stale initramfs
(cd /boot || exit
find . -name "initramfs*img"|sed "s#..##"|while read -r i; do
	iVERSION="$(printf "%b" "${i%.img}"|sed "s#initramfs-##")"
	if ! find . -name "vmlinuz*"|grep -q "$iVERSION"; then
		rm "$i"
		eval_gettext "Stale initramfs \$i removed."
		echo
	fi
done
)
rm -f "$_installed" "$_versions"

