# About Slint {#_about_slint}

Slint is an easy-to-use, versatile, blind-friendly Linux distribution for 64-bit computers. Slint is based on Slackware and borrows tools from Salix. Maintainer: Didier Spaier.

# Features {#_features}

-   Slint is a stable distribution. However, accessibility software is regularly updated, others may be updated on a case by case basis.

-   The included software, among which the MATÉ and LXQt desktops (with XFCE installed on-demand), cover most needs. Many others are available in repositories maintained by Salix and Slackware that are fully compatible with Slint.

-   Slint can be used in console and graphical modes and can be switched between these modes without restarting. It is even possible to launch several graphical environments and switch between them.

-   Easy-to-use tools facilitate system administration and software package management. Updates are fully automatic, under user control.

-   By default, a compressed swap space in RAM allows doubling the usable memory.

-   Slint can be installed on any 64-bit machine with at least 2G of memory, and 30G available on any medium including USB keys, without secure boot.

-   If installed on USB media Slint is portable from one computer to another. The media can be fully encrypted.

# Installation {#_installation}

The installation program, in text mode, is fully accessible for blind people using a screen reader or Braille display, and proceeds by questions and answers with online help and integrated documentation. Two partitioning modes are available:

-   Manual: the user chooses the file system (btrfs, ext4 or xfs) and the media can be shared with other systems.

-   Automatic: The file system is then btrfs and the media dedicated to Slint.

The btrfs file system is configured with subvolumes instead of separate partitions. It allows to divide by 2 the space occupied on the media, to take snapshots and is well adapted to SSD, NVMe and USB sticks.

# Links {#_links}

-   [Web site](https://slint.fr)

-   [Main repository](http://slackware.uk/slint/x86_64/slint-15.0/)

-   [ChangeLog](http://slackware.uk/slint/x86_64/slint-15.0/ChangeLog.txt)
