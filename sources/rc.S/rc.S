#!/bin/sh
# shellcheck disable=SC1091,SC2034
# rc.S:  Basic system initialization.
# Modification of the file assumed to have been written by Patrick .J. Volkerding found in:
# http://ftp.slackware.com/pub/slackware/slackware-15.0/source/installer/sources/initrd/skeleton_initrd.tar.gz
# heavily modified by Didier Spaier didieratslintdotfr for the Slint Linux distribution.

# Version included in slint64-15.0-6.iso

# Any /etc/mtab that exists here is old, so we start with a new one:
#/bin/rm -f /etc/mtab /etc/mtab~ /etc/mtab.tmp && /bin/touch /etc/mtab

# Add (fake) entry for / to /etc/mtab:
#/sbin/mount -f -w /dev/initramfs / -t tmpfs 1> /dev/null


if [ ! -e /proc/mounts ]; then
  /sbin/mount -v proc /proc -t proc 1> /dev/null
fi
if ! grep -q "^sysfs" /proc/mounts; then
  /sbin/mount -v sysfs /sys -t sysfs 1> /dev/null
fi

# Activate swap:
/sbin/swapon -a 1> /dev/null

# Mount the efivars files system if the system booted in EFI mode. This
# will allow to include in the GRUB # boot menu a boot entry to go to
# the firmware setup menu.
[ -d /sys/firmware/efi/efivars ] && mount -t efivarfs none /sys/firmware/efi/efivars

if [ -x /sbin/ldconfig ]; then
  /sbin/ldconfig 1> /dev/null
fi

# We source /sbin/functions after having mounted /proc and /sys to avoid hamrless erreor messages
# But before exporting TEXTDOMAIN as the TEXTDOMAIN of /sbin/functions is "auto"
. /sbin/functions
export TEXTDOMAIN=rc.S
. gettext.sh
. /sbin/SeTlocales

# System logger (mostly to eat annoying messages):
/sbin/syslogd 2> /dev/null
sleep 1
/sbin/klogd -c 3 1> /dev/null

# Try to load the loop module:
modprobe loop 1> /dev/null 2> /dev/null

# Run udev:
/bin/bash /etc/rc.d/rc.udev start
unset SYNTH
if grep -q speakup.synth /proc/cmdline; then
	SYNTH=$(sed "s@.*speakup[-_]synth=\([[:alpha:]]\{1,\}\).*@\1@" /proc/cmdline)
	[ "$SYNTH" ] && [ ! "$SYNTH" = "soft" ] && modprobe speakup_"$SYNTH" && touch /tmp/noespeakup
fi
sleep 1
# espeakup initialization. This was done in previous versions just before running
# /sbin/probe_sound_cards but there is no need to wait. 
# If a hard synth is set in the command line no need to start espeakup.
# This could be done runnig "rc.espeakup start", but not knowing yet if espeakup will be really used,
# instead case occuring espeakup will be started by /sbin/probe_sound_cards.
if  [ ! -f /tmp/noespeakup ]; then
	modprobe speakup_soft
	echo "soft" > /sys/accessibility/speakup/synth
	sleep 1
	echo 1 > /sys/accessibility/speakup/soft/direct
fi
sleep 1
# brltty is included in the initrd so that it be started by udev when applicable.
# We mount the ISO so we can install the packages we need in the initrd
mkdir -p /ISO
mkdir -p /INSTALLER
mounttheiso
sh /etc/rc.d/rc.swapinzram start
echo "Adding some packages to the installer..."
SUBDIR=slint
[ -d "$ISO"/installer ] && SUBDIR=installer
sleep 2
	spkg -i -qq \
	"$ISO"/$SUBDIR/aaa_glibc-solibs-*.txz \
	"$ISO"/$SUBDIR/aaa_libraries-*.txz \
	"$ISO"/$SUBDIR/acl-*txz \
    "$ISO"/$SUBDIR/alsa-lib*txz \
	"$ISO"/$SUBDIR/brotli*txz \
	"$ISO"/$SUBDIR/bzip2*txz \
	"$ISO"/$SUBDIR/c-ares*.t?z \
	"$ISO"/$SUBDIR/ca-certificates*.t?z \
	"$ISO"/$SUBDIR/coreutils*txz \
	"$ISO"/$SUBDIR/curl*.t?z \
	"$ISO"/$SUBDIR/cyrus-sasl*.t?z \
	"$ISO"/$SUBDIR/dialog-*.t?z \
	"$ISO"/$SUBDIR/dracut*txz \
	"$ISO"/$SUBDIR/efibootmgr*.txz \
	"$ISO"/$SUBDIR/espeak-ng*.txz \
	"$ISO"/$SUBDIR/expat*.t?z \
	"$ISO"/$SUBDIR/file-*txz \
	"$ISO"/$SUBDIR/findutils*.t?z \
	"$ISO"/$SUBDIR/flac*.t?z \
	"$ISO"/$SUBDIR/gc-*txz \
	"$ISO"/$SUBDIR/gnupg-1*txz \
	"$ISO"/$SUBDIR/gpm*txz \
	"$ISO"/$SUBDIR/json-c*txz \
	"$ISO"/$SUBDIR/kbd*.t?z \
	"$ISO"/$SUBDIR/libassuan*.t?z \
	"$ISO"/$SUBDIR/libgpg-error*.t?z \
	"$ISO"/$SUBDIR/liblouis-*.t?z \
	"$ISO"/$SUBDIR/libnl3*.t?z \
	"$ISO"/$SUBDIR/libogg-*.t?z \
	"$ISO"/$SUBDIR/libpsl-*.t?z \
	"$ISO"/$SUBDIR/libsndfile*.t?z \
	"$ISO"/$SUBDIR/libssh2-*.t?z \
	"$ISO"/$SUBDIR/libtirpc*.t?z \
	"$ISO"/$SUBDIR/libunistring*txz \
	"$ISO"/$SUBDIR/libvorbis*.t?z \
	"$ISO"/$SUBDIR/libyaml*.t?z \
	"$ISO"/$SUBDIR/most*.t?z \
	"$ISO"/$SUBDIR/nano*txz \
	"$ISO"/$SUBDIR/ncurses*txz \
	"$ISO"/$SUBDIR/net-tools*.t?z \
	"$ISO"/$SUBDIR/nghttp2*.t?z \
	"$ISO"/$SUBDIR/openssl-solibs-*txz \
	"$ISO"/$SUBDIR/opus-1*txz \
	"$ISO"/$SUBDIR/orc-0*.t?z \
	"$ISO"/$SUBDIR/pam-1*.t?z \
	"$ISO"/$SUBDIR/pcaudiolib*txz \
	"$ISO"/$SUBDIR/pcre2*.t?z \
	"$ISO"/$SUBDIR/slang-*.t?z \
	"$ISO"/$SUBDIR/slapt-get*.t?z \
	"$ISO"/$SUBDIR/slint-scripts*txz \
	"$ISO"/$SUBDIR/sonic*txz \
	"$ISO"/$SUBDIR/tar*.t?z \
	"$ISO"/$SUBDIR/tree-1*.txz \
	"$ISO"/$SUBDIR/util-linux*txz \
	"$ISO"/$SUBDIR/wireless_tools*.t?z \
	"$ISO"/$SUBDIR/wpa_supplicant-nogui*.t?z \
	"$ISO"/$SUBDIR/zlib*.t?z
# We need /usr/lib64/libgpgme.so.11.25.0 from the gpgme package to make
# slapt-get happy
tar -xJf "$ISO"/$SUBDIR/gpgme-1*.txz usr/lib64/libgpgme.so.11.25.0
# We need libdbus-1.so.3 from the dbus package to make wpa_passphrase and
# wpa_supplicat happy
tar -xJf "$ISO"/$SUBDIR/dbus-1*.txz usr/lib64/libdbus-1.so.3.19.13	
ldconfig
# Remove from alsa-utils and util-linux the utilities that we do not need at
# all least if they lack dependencies.
rm -f \
/usr/bin/alsabat \
/usr/bin/alsaloop \
/usr/bin/axfer \
/usr/bin/setpriv \
/usr/sbin/dnsmasq
# We do not need the python lib pylibmount.so shipped in util-linux.
# Actually we do not need /usr/lib/python2.7 at all.  
rm -rf /usr/lib64/python2.7
# brltty is included in the initrd so that it be started by udev when applicable.
# Start brltty if it has not yet been started by udev
NBPROC="$(ps -C brltty --noheaders|wc -l)"
if [ "$NBPROC" = "0" ]; then
	echo "starting brltty"
	/bin/brltty
sleep 2
fi

touch /.today
/bin/sh /sbin/fakedate

if [ -x /etc/rc.d/rc.inet1 ]; then
  /bin/sh /etc/rc.d/rc.inet1
fi

/bin/sh /etc/rc.d/rc.font

# Don't automatically blank the screen, or it will go black during the install
# process when stray keystrokes might be dangerous:
/bin/setterm -blank 0

TMP=/var/log/setup/tmp
if [ ! -d $TMP ]; then
 mkdir -p $TMP
fi

TMP=/var/log/setup/tmp

kbd_stored="$(cat /tmp/Pkeymap)"
kbd=${kbd_stored%.*}
#SavedLANG=$LANG
#LANG=en_US.utf8
ll_TT=${LANG%.*}
SeTFonts
PutFonts
set_voice () {
	locale="$1"
	rawlocale=${locale%.utf8}
	lang=$(echo "$rawlocale" |cut -d_ -f1)
	country=$(echo "$rawlocale" |cut -d_ -f2|tr "[:upper:]" "[:lower:]")
	if [ "$lang" = gl ]; then
		# Not supported by espeak yet, but pt should be fine enough, better
		# than English anyway
		# Comment above from Debian. We don't propose gv in Slint yet, but
		# maybe later ?
		lang=pt
	fi

	if grep -qr "^language $lang-$country$" /usr/share/espeak-ng-data/lang; then
		VOICE="$lang-$country"
	elif grep -qr "^language $lang$" /usr/share/espeak-ng-data/lang; then
		VOICE="$lang"
	else
		VOICE=en
	fi
	echo $VOICE > /tmp/speech
}
sh /etc/rc.d/rc.alsa 2>/tmp/error.alsa 1>out.alsa
set_voice "$LANG"
# Probe the sound cards as in Debian
# We will do it, regardless or espeakup could be used or not
# TODO: internationalize and localize the messages from /sbin/probe_sound_cards
sh /sbin/probe_sound_cards
sleep 2
# If a working sound card has been found, its id has been written in
# /tmp/alsacard, else /tmp/noespeakup has been written
sleep 2
clear
# Get a network connection early, to allow ssh-ing into the installer.
# wired
# Start dropbear ssh server (only if a configured interface is present):
# /etc/rc.d/rc.dropbear start
# Fake login:  (fooled ya! ;^)
#
if [ ! -f /tmp/noespeakup ]; then
	gettext  "This installer has speech and Braille device support in order
to be accessible to visually impaired users. To have speech turned on
during installation type S, then press [Enter]. Else, just press Enter.
"
	clear_stdin
	read -r sound
	if [ ! "$sound" = "s" ] && [ ! "$sound" = "S" ]; then
		PID=$(ps -C espeakup --noheaders -o pid)
		kill -s 9 "$PID"
		sleep 1
		touch /tmp/noespeakup
	else
		# I assume that people owning a hard synthesizer already know the speakup keybord shosrtcuts.
		clear
		gettext  "To display keyboard shortcuts for reviewing the screen with speech
press R, then press [Enter],
Else, just press [Enter]: "
		clear_stdin
		read -r ANSWER
		if [ "$ANSWER" = "R" ] ||  [ "$ANSWER" = "r" ]; then
			clear
			w3m -o confirm_qq=false /Speakup
		fi
	fi
fi
INITLANG=$LANG
TITLE=$(gettext "LANGUAGE TO USE DURING INSTALLATION")
dialog --visit-items --no-tags --no-cancel --nook --title "$TITLE" --default-item "$INITLANG" --menu \
"$(eval_gettext "Please select the language to use for installation.")" 0 0 0 \
en_US.utf8 "$(gettext "English (USA)")" \
nl_NL.utf8 "$(gettext "Dutch")" \
fr_FR.utf8 "$(gettext "French")" \
de_DE.utf8 "$(gettext "German")" \
el_GR.utf8 "$(gettext "Greek")" \
it_IT.utf8 "$(gettext "Italian")" \
pt_PT.utf8 "$(gettext "Portuguese (Portugal)")" \
ru_RU.utf8 "$(gettext "Russian")" \
sv_SE.utf8 "$(gettext "Swedish")" \
 2> /tmp/.SlintInstallationLANG
	mycmd="$?"
	if [ "$mycmd" -ne 0 ]; then
	echo "$INITLANG" > /tmp/.SlintInstallationLANG
fi
LANG=$(cat /tmp/.SlintInstallationLANG)
ll_TT=${LANG%.*}
SeTlocales
SeTKeymap
SeTFonts
PutFonts
if [ ! -f /tmp/noespeakup ] && [ ! "$INITLANG" = "$LANG" ]; then
	PID=$(ps -C espeakup --noheaders -o pid)
	kill -s 9 "$PID"
	sleep 1
	set_voice "$LANG"
	ALSA_CARD=$(cat /tmp/alsacard)
	ALSA_CARD=$ALSA_CARD /usr/bin/espeakup -V "$(cat /tmp/speech)" >> /tmp/espeakup.log 2>&1
	echo "ALSA_CARD=$ALSA_CARD /usr/bin/espeakup -V $(cat /tmp/speech)" >> /tmp/report
fi
clear

eval_gettext "<OPTION TO LOAD SUPPORT FOR ANOTHER KEYBOARD>

If you are not using a \"\$kbd\" keyboard map, you may load another one now.
To select a different keyboard map, please enter 1 now.
To continue using the \"\$kbd\" keyboard map, just hit [Enter]."
echo
echo
gettext "Enter 1 to select a keyboard map: "
clear_stdin
read -r ONE
if [ "$ONE" = "1" ]; then
  /sbin/SeTkeymap
fi
clear
. /etc/profile

Version="$(cat /tmp/isoversion)"

eval_gettext "Welcome to the Slint installer! (version \${Version})

You may now type (without the quotes):

'doc' to know the features and usage of the installer.
'start' to start the installation.

The installer can prepare the drive where Slint will be installed,
creating the the needed partitions. If you prefer you can do it yourself
using command line utilities available in the installer, then type 'start'
when done. You can also leave the installer and use a tool like gparted
to do that then start the installer again.

We recommend that you type 'doc' first in this case, or if you want to
encrypt the root Slint partition.
When you finish reading this menu will be displayed again.
"
