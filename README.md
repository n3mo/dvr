dvr
===

A tool for quickly listing and managing video files spread across a file system. The program quickly searches (recursively) for any video files within a specified file system. The resulting list is printed to the terminal in sorted order, followed by summary statistics (the number of files found, their total size, and the remaining available space on the HDD).

By including one of several options, you can also manage your video library. Currently, this includes two options: playing videos and trashing videos. An interactive interface allows for quick selection of videos, allowing for easy selection of multiple files for deletion.

Videos selected for play are opened by the default video player on your system. This functionality is supported on linux and OS X.

Files can also be quickly moved to the trash. When trashing videos, the program also trashes files in the same directory with the same name but different extensions. This allows the user to trash all subtitle and related info files along with the video file in one easy step.

Performance is fast on my relatively old linux machine (approximately 0.061 seconds of real time using a compiled version on around 100 videos spread across 100+ directories). It seems to scale well, but expect poor performance if you, say, target your entire home directory containing many hundreds of gigs spread across hundreds or thousands of directories. 

Installation
============

Prerequisites
-------------

Currently, this software is not bundled as a self-contained package. Thus, you will need [Chicken Scheme](http://www.call-cc.org/) installed on your system. This software was developed and tested on Chicken 4.8.0 and 4.7.0.6. Your mileage may vary on other versions. 

Additionally, you will need the following [Eggs](http://wiki.call-cc.org/eggs) installed:
* shell
* args

dvr also uses the following Units:
* posix
* regex
* files

Interpreted
-----------
Installation is simple once Chicken is properly installed:

1. Clone the git repository into a directory of your choice
2. Ensure that the file dvr.scm is executable (chmod +x dvr.scm)

Compiled
--------
For better performance, you should consider compiling the script to a binary executable. To do so, first follow the installation steps above, then compile the script with

`csc dvr.scm -o dvr`

The resulting executable "dvr" should be placed somewhere on your PATH.

Usage
=====
Assuming you have compiled to the file "dvr", usage is as follows (if you would rather use the raw scheme file, simply replace "dvr" with "dvr.scm" in the following snippets:

The expected syntax is `dvr /path/to/videos`

If the optional path is unspecified, the default path "~/media/Television" is used.

To interactively select video files to watch, use the play option:

`dvr ~/Videos -p`

To interactively trash video files (and their related subtitle & info files), use the delete option:

`dvr /path/to/videos -d`

You will then be prompted to select one or more files by number (separate multiple file numbers by spaces). Enter 0 (zero) to abort the trashing process.

You can see help information at any time with

`dvr -h`
