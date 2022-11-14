#!/bin/sh
# rc.S:  Basic system initialization.
# Modified from the one found in:
# http://ftp.slackware.com/pub/slackware/slackware-15.0/source/installer/sources/initrd/skeleton_initrd.tar.gz
# Assumed to have been written initially by Patrick .J. Volkerding
# Changes post Slint15-beta3
# Drop using dropbear
# Drop unused code as us udev is aways used

# Any /etc/mtab that exists here is old, so we start with a new one:
/bin/rm -f /etc/mtab{,~,.tmp} && /bin/touch /etc/mtab

# Add (fake) entry for / to /etc/mtab:
/sbin/mount -f -w /dev/initramfs / -t tmpfs 1> /dev/null

# Mount /proc:
/sbin/mount -v proc /proc -t proc 1> /dev/null

# Mount sysfs next:
/sbin/mount -v sysfs /sys -t sysfs 1> /dev/null

# Activate swap:
/sbin/swapon -a 1> /dev/null

# Mount the efivars files system if the system booted in EFI mode. This
# will allow to include in the GRUB # boot menu a boot entry to go to
# the firmware setup menu.
[ -d sys/firmware/efi/efivars ] && mount -t efivarfs none /sys/firmware/efi/efivars

if [ -x /sbin/ldconfig ]; then
  /sbin/ldconfig 1> /dev/null
fi

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

# Added as in slint64-5.0beta.iso

sleep 8
# I assume that we can install all packages we need in the initrd now
# brltty is included in the initrd so that it be started by udev when
# applicable.
# We mount the ISO so we can add the ackages we need to this initrd
mkdir -p /ISO
mkdir -p /INSTALLER
. /sbin/functions
mounttheiso
sh /etc/rc.d/rc.swapinzram start

echo "installing kernel-firmware. Please wait..."
spkg -i -qq $ISO/slint/kernel-firmware*txz

#End additions as in slint64-5.0beta.iso
export TEXTDOMAIN=rc.S
sleep 1

# Start brltty if it has not yet been started by udev - Didier Spaier
NBPROC="`ps -C brltty --noheaders|wc -l`"
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

kbd_stored="`cat /tmp/Pkeymap`"
kbd=${kbd_stored%.*}
#SavedLANG=$LANG
#LANG=en_US.utf8
ll_TT=${LANG%.*}
SeTFonts
PutFonts
set_voice () {
	locale="$1"
	rawlocale=${locale%.utf8}
	lang=$(echo $rawlocale |cut -d_ -f1)
	country=$(echo $rawlocale |cut -d_ -f2|tr A-Z a-z)
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
# speakup initialization.
# If a hard synth is set in the command line (how do I provide this ability
# with grub?) no need to start espeakup.
if ! grep -q speakup /proc/cmdline; then
	modprobe speakup_soft
	echo "soft" > /sys/accessibility/speakup/synth
	sleep 1
	# chmod 666 not needed in the installer, we are root.
	# chmod 666 /sys/accessibility/speakup/soft/*
	echo 1 > /sys/accessibility/speakup/soft/direct
else
	touch /tmp/noespeakup
fi
# End speakup initialization
# Mostly from Debian
if [ ! -f /tmp/noespeakup ]; then
	set_voice $LANG
	# Probe the sound cards as in Debian
	sh /sbin/probe_sound_cards
	sleep 2
fi
# If a working sound card has been found, its id has been written in
# /tmp/alsacard, else /tmp/noespeakup has been written
if [ ! -f /tmp/noespeakup ]; then
	sleep 2
	clear
	read -N 10000000 -t 0.01
	gettext  "This installer has speech and Braille device support in order
to be accessible to visually impaired users. To have speech turned on
during installation type S, then press [Enter]. Else, just press Enter.
"
	read sound
	if [ ! "$sound" = "s" ] && [ ! "$sound" = "S" ]; then
		PID=$(ps -C espeakup --noheaders -o pid)
		kill -s 9 $PID
		sleep 1
		touch /tmp/noespeakup
	fi
fi
clear

if [ ! -f /tmp/noespeakup ] || grep -q speakup /proc/cmdline; then
	gettext  "To display keyboard shortcuts for reviewing the screen with speech
press R, then press [Enter],
Else, just press [Enter]: "
	read ANSWER
	if [ "$ANSWER" = "R" ] ||  [ "$ANSWER" = "r" ]; then
		clear
		/bin/less /Speakup
		read
	fi
fi
clear
INITLANG=$LANG
TITLE=$(gettext "LANGUAGE TO USE DURING INSTALLATION")
dialog --visit-items --no-tags --no-cancel --nook --title "$TITLE" --default-item "$INITLANG" --menu \
"$(eval_gettext "Please select the language to use for installation.")" 0 0 0 \
en_US.utf8 "$(gettext "English (USA)")" \
nl_NL.utf8 "$(gettext "Dutch")" \
fr_FR.utf8 "$(gettext "French")" \
el_GR.utf8 "$(gettext "Greek")" \
it_IT.utf8 "$(gettext "Italian")" \
pt_PT.utf8 "$(gettext "Portuguese (Portugal)")" \
sv_SE.utf8 "$(gettext "Swedish")" \
 2> /tmp/.SlintInstallationLANG
if [ $? -ne 0 ]; then
	echo $INITLANG > /tmp/.SlintInstallationLANG
fi
LANG=$(cat /tmp/.SlintInstallationLANG)
ll_TT=${LANG%.*}
SeTlocales
SeTKeymap
SeTFonts
PutFonts
if [ ! -f /tmp/noespeakup ] && [ ! "$INITLANG" = "$LANG" ]; then
	PID=$(ps -C espeakup --noheaders -o pid)
	kill -s 9 $PID
	sleep 1
	set_voice $LANG
	ALSA_CARD=$(cat /tmp/alsacard)
	ALSA_CARD=$ALSA_CARD /usr/bin/espeakup -V $(cat /tmp/speech) >> /tmp/espeakup.log 2>&1
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
read ONE
if [ "$ONE" = "1" ]; then
  /sbin/SeTkeymap
fi
clear
. /etc/profile


# Fake login:  (fooled ya! ;^)
#
Version=15.0
GCOUNTMIN=50

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
