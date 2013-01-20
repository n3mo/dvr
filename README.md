dvr
===

A tool for quickly listing and managing video files spread across a file system. The program quickly searches (recursively) for any video files within a specified file system. The resulting list is printed to the terminal in sorted order, followed by summary statistics (the number of files found, their total size, and the remaining available space on the HDD).

Installation
============

Prerequisites
-------------

Currently, this software is not bundled as a self-contained package. Thus, you will need [Chicken Scheme](http://www.call-cc.org/) installed on your system. This software was developed and tested on Chicken 4.8.0 and 4.7.0.6. Your mileage may vary on other versions. 

Additionally, you will need the following [Eggs](http://wiki.call-cc.org/eggs) installed:
* shell
* args
* posix

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
