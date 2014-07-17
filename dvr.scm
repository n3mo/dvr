#! /usr/local/bin/csi -s
;;; dvr.scm --- Video file management for Chicken Scheme

;; Copyright 2013, Nicholas M. Van Horn

;; Author: Nicholas M. Van Horn <vanhorn.nm@gmail.com>
;; Keywords: dvr video scheme chicken
;; Version: 1.0

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA. (or visit http://www.gnu.org/licenses/)
;;

;;; Commentary:

;;; This program provides a simple and efficient command line
;;; interface for quickly listing and managing video files stored in
;;; nested directories on a file system. Run dvr.scm -h for
;;; information on how to use the program. For up to date information,
;;; see the github page for this program at
;;; https://github.com/n3mo/dvr 

(require-extension shell)
(require-extension args)
(require-extension posix)
(require-extension files)
(require-extension regex)
(require-extension srfi-13)

;;; Files ending in the following extensions will be
;;; included in all operations. Add accordingly
(define valid-extensions
  '("flv" "mov" "mp4" "wmv" "mkv" "mov" "avi" "mpg" "swf"))

;;; The script expects a user-supplied target path at runtime.
;;; If no path is supplied, the following default is used. For
;;; more general audiences, this should probably be changed to "."
(define default-path "~/media/Television/")

;;; Location of trash directory on this system. For now, this assumes
;;; that you're either using Mac OS X or linux...
(define trash-path
  (if (string=? "darwin" (string-downcase 
			  (car (system-information))))
	"~/.Trash/"
	"~/.local/share/Trash/files/"))

;;; This function strips operands (rather than "-" prefixed options)
;;; from the command line arguments and returns a list of all operands
(define (list-operands myargs)
  (cond
   ((null? myargs) '())
   ((string-prefix? "-" (car myargs))
    (list-operands (cdr myargs)))
   (else (cons (car myargs) (list-operands (cdr myargs))))))

;;; Given a list of file paths "filelist" and a number "num", this
;;; returns the num-th file path from the list
(define (get-file filelist num)
  (if (> num (length filelist))
      (print "Too large")
      (begin
	(define (file-by-num mylist counter)
	  (if (eq? counter num) (car mylist)
	      (file-by-num (cdr mylist) (+ counter 1))))
	(file-by-num filelist 1))))

;;; The following list contains all defined command line options
;;; available to the user. For example, (h help) makes all of the
;;; following equivalent options available at runtime: -h, -help, --h,
;;; --help. These are used by the "args" egg.
(define opts
  (list (args:make-option (p play) #:none "Play file"
			  (play-video))
	(args:make-option (d delete) #:none "Delete file(s)"
			  (delete-videos))
	(args:make-option (h help)   #:none "Help information"
			  (usage))))

;;; This procedure is called whenever the user specifies the help
;;; option at runtime OR whenever an unexpected command line option or
;;; operand is passed to this script.
(define (usage)
 (with-output-to-port (current-error-port)
   (lambda ()
     (print "Usage: dvr [directory] [options...]")
     (newline)
     (print (args:usage opts))
     (print "dvr prints a recursive list of all video files")
     (print "available in [directory]. By including the -d option,")
     (print "dvr allows for interactive deletion of video files.")
     (print "'Deleted' files are moved to the trash.\n")
     (print "dvr treats collections of related files as a single unit.")
     (print "Accompanying files (such as subtitle and info files)")
     (print "are sent to the trash as well for a given video file.\n")
     (print "Videos can be played (by the system default player) by")
     (print "including the -p option. An interface will allow for")
     (print "interactive selection for choosing videos to watch.\n")
     (print "Example 1: dvr ~/Videos")
     (print "Example 2: dvr ~/Videos -p")
     (print "Example 3: dvr ~/Videos/television -d\n")
     (print "Report bugs to vanhorn.nm at gmail.")))
 (exit 1))

;;; This does all the heavy lifting. It recursively scans the supplied
;;; directory, returning a list of file paths that end in any
;;; extension contained in valid-extensions. 
(define (file-list file-path)
  (find-files file-path
	      test: (lambda (path)		
		(member #t (map
			    (lambda (ext) (string-suffix? ext path))
			    valid-extensions)))))

;;; You can safely send videos to the trash, whereupon they can be
;;; restored later (rather than simply removing them for good with
;;; "rm"). Note that most videos I use have accompanying subtitle
;;; files, info files, etc. with shared filenames that differ only in
;;; their extension. This procedure moves all such similarly-named
;;; files to the trash for you. You only need to specify one file
;;; "video-path" to move them all.
(define (trash-video video-path)
  (let ((video-files
	 (find-files (pathname-directory video-path) 
		     test: 
		     (conc ".*" (regexp-escape
				 (pathname-file video-path)) ".*"))))
    (for-each (lambda (myfile)
		(rename-file myfile
			     (pathname-replace-directory myfile trash-path)))
	      video-files)))

;;; Play video files with default player. As of now, the system
;;; default video player is determined by the shell command "open" on
;;; OS X, and by the shell command "xdg-open" on linux.
(define (play-video)
  (begin
    (define myargs (list-operands (command-line-arguments)))
    (if (null? myargs)
	(define video-file-paths (file-list default-path))
	(define video-file-paths (file-list (car myargs))))
    (newline)
    (print-videos video-file-paths #t)
    (newline)
    (display "Enter file number to play (0 to abort): ")
    (let ((sorted-videos (sort-videos-no-path video-file-paths))
	  (target-file (string->number (read-line)))
	  (mysystem (string-downcase (car (system-information)))))
      (newline)
      (if (or (not target-file)
	      (<= target-file 0)
	      (> target-file (length video-file-paths)))
	  (begin
	    (print "Process aborted.")
	    (newline)
	    (exit 1))
	  (begin
	    (printf "Playing ~s\n"
		    (pathname-file
		     (get-file sorted-videos target-file)))
	    (if (string=? "darwin" mysystem)
		(system (conc "open "
			      (qs (normalize-pathname
				   (get-file sorted-videos target-file)))))
		(system (conc "xdg-open "
			      (qs (normalize-pathname
				   (get-file sorted-videos target-file))))))
	    (exit 0))))))

;;; This does the work on linux
;; (system (conc "xdg-open " (qs (normalize-pathname video-path))))

;;; You can print the available files found with (file-list) using
;;; this procedure. If numberp is true, each video file printed is
;;; preceded with a unique number (useful for managing files, e.g.,
;;; for interactively deleting files)
(define (print-videos file-paths #!optional (numberp #f))
  (let ((video-names 
	 (map (lambda (x) (truncate-file-name x (length file-paths)))
	      (map (lambda (path) (pathname-file path)) file-paths))))
    (if numberp
	;; Add numbering...
	(let ((filecount 0)
	      (max-width (string-length (number->string (length video-names)))))
	  (for-each
	   (lambda (l) 
	     (begin 
	       (set! filecount (+ filecount 1))
	       (display
		(conc "["
		      (string-pad (number->string filecount) max-width) "] "))
	       (print l)))
	   (sort-videos video-names)))
	;; Else don't...
	(for-each (lambda (l) (print l)) (sort-videos video-names)))))

;;; Sort video file names alphabetically
;; (define (sort-videos myvideos)
;;   (sort (map string-titlecase myvideos)
;; 	(lambda (a b) (string< a b))))
(define (sort-videos myvideos)
  (sort myvideos (lambda (a b) (string< a b))))

;;; Sort video file names IGNORING paths
;; (define (sort-videos-no-path myvideos)
;;   (sort (map string-titlecase myvideos)
;; 	(lambda (a b) (string< (pathname-file a) (pathname-file b)))))
(define (sort-videos-no-path myvideos)
  (sort myvideos (lambda (a b) (string< (pathname-file a)
					(pathname-file b))))) 


;;; Computes how much memory all the video files are consuming
;;; on the HDD. The value returned is the total memory in GB.
;;; Due to a bug (possibly in an underlying C library), the procedure
;;; (file-paths) fails on large file sizes. This procedure should be
;;; called with an exception handler.
(define (memory-used file-paths)
  (round (/ (apply + (map file-size file-paths)) (expt 1024 3))))

;;; Available space on HDD. This is an ugly hack, but it returns
;;; the available space on the hard drive (in GB). I imagine this
;;; may fail on computers with multiple (or oddly named) HDDs.
(define (memory-free)
  (round (string->number
	  (irregex-replace "\n"
			   (capture ("df | grep '^/dev/' | awk '{s+=$4} END {print s/1048576}'"))))))

;;; Delete files procedure
(define (delete-videos)
  (begin
    (define myargs (list-operands (command-line-arguments)))
    (if (null? myargs)
	(define video-file-paths (file-list default-path))
	(define video-file-paths (file-list (car myargs))))
    (newline)
    (print-videos video-file-paths #t)
    (newline)
    (display "Enter file number(s) to delete, separated by spaces (0 to abort): ")
    (let ((sorted-videos (sort-videos-no-path video-file-paths))
	  (target-files (map string->number (string-split (read-line)))))
      (newline)
      (if (memq 0 target-files)
	  (begin
	    (print "Aborted: 0 files changed")
	    (newline)
	    (exit 1))
	  (for-each 
	   (lambda (target-file)
	     (cond ((and (> target-file 0) (<= target-file (length video-file-paths)))
		    (begin
		      (printf "Moving ~s to trash\n" 
			      (pathname-file
			       (get-file sorted-videos target-file)))
		      (trash-video (get-file sorted-videos target-file))))
		   (else
		    (begin
		      (print "Aborted: 0 files changed")
		      (newline)))))
	   target-files))
      (newline)
      (exit 0))))

;;; If s is longer than len, cut it down and add ... at the end. This
;;; is taken from my string egg "s"
(define (s-truncate len s)
  (if (> (string-length s) len)
      (let ((tmp (string->list s)))
	(conc (list->string (take tmp (- len 3))) "..."))
      s))

;;; Truncate file name to a size less than the current terminal
;;; width. File names that are truncated will have ... added to the
;;; end. truncate-file-name anticipates the [1] numbering interface
;;; and augments the absolute terminal width accordingly
(define (truncate-file-name file-name num-files)
  (let-values
      (((num-rows num-cols) (terminal-size (current-output-port))))
    (s-truncate (- num-cols
		   (string-length (number->string num-files))
		   3)
		file-name)))

;;; This needs to be explicitly called for anything to happen
;;; at runtime. (main) is called below. 
(define (main)
  (begin
    (define myargs (list-operands (command-line-arguments)))
    (if (null? myargs)
	(define video-file-paths (file-list default-path))
	(define video-file-paths (file-list (car myargs))))
    (newline)
    (print-videos video-file-paths)
    ;; Show the total space used? Currently, the procedure 
    ;; (file-size) breaks on large files. The exception here
    ;; handles such situations by avoiding the call to 
    ;; (memory-used)
    (handle-exceptions exn
		       (begin
			 (display (sprintf "~%~A Videos Total (~AGB free).~%~%"
					   (length video-file-paths)
					   (memory-free))))
		       (display (sprintf "~%~A Videos Total. ~AGB used (~AGB free).~%~%"
					 (length video-file-paths)
					 (memory-used video-file-paths)
					 (memory-free))))))

;;; This gets things done. If you run this with no command line
;;; options, your available files are printed to the screen. Including
;;; options opens up other possibilities.
(receive (options operands)
    (args:parse (command-line-arguments) opts)
  (handle-exceptions exn (usage) (main)))

;;; end of file dvr.scm
