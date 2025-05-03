#!/bin/sh
# shellcheck disable=SC1091,SC2034
# We remove all packages kernel, kernel-source and kernel headers that are
# with a version number not equal to that of the running kernel
TEXTDOMAIN=slint-scripts
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
to_lower() {
	echo "$1"|tr '[:upper:]' '[:lower:]'
}
(cd /var/lib/pkgtools/packages || exit
INSTALLED=$(find . -type f|grep "kernel-[^-]*-[^-]*-[^-]*$"|sed 's#..##'|grep -v "$RUNNINGVERSION")
echo "$INSTALLED" > "$_installed"
while read -r i <&3; do
	iVERSION=$(echo "$i"|sed "s/.*-\($FRAG\)-$FRAG-$FRAG$/\1/")
	if [ "$iVERSION" = "$RUNNINGVERSION" ]; then
		echo "not removing $i as it is the runnng kernel" >>$LOG
		continue
	fi
	while [ ! "$(to_lower "$ANSWER")" = "yes" ] && [ ! "$(to_lower "$ANSWER")" = "no" ]; do
		eval_gettext "The kernel \$i is not in use. Do you want to remove it?"
		echo
		gettext "Type yes or no: "
		read -r ANSWER
		[ ! "$(to_lower "$ANSWER")" = "yes" ] && continue
		echo "spkg -d $i"
#		spkg -d "$i"
		# Also remove kernel-headers and kernel source at the same version
		j=$(echo "$i"|sed 's#kernel#kernel-source#')
#		[ -f "$j" ] && echo "spkg -d $i" >>$LOG && spkg -d "$j"
		[ -f "kernel-source-${iVERSION}*" ] && echo "spkg -d $i"
		j=$(echo "$i"|sed 's#kernel#kernel-headers#')
		[ -f "$j" ] && echo "spkg -d $i" >>$LOG && spkg -d "$j"
		[ -f "$j" ] && echo "spkg -d $i"
	done
done 3<"$_installed"
)
# Remove the stale initramfs
(cd /boot || exit
find . -name "initramfs*img"|sed "s#..##"|while read -r i; do
	iVERSION="$(printf "%b" "${i%.img}"|sed "s#initramfs-##")"
	if ! find . -name "vmlinuz*"|grep -q "$iVERSION"; then
#		rm "$i"
		echo "stale initramfs /boot/$i removed"
	fi
done
)

