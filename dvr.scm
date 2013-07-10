#! /usr/local/bin/csi -s

(require-extension shell)
(require-extension args)
(require-extension posix)
(require-extension files)

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
 (list (args:make-option (d delete) #:none "Delete file(s)"
         (delete-videos))
       (args:make-option (h help)   #:none "Help information"
         (usage))))


;; ;;; This is a temporary place holder for the deletion functionality I
;; ;;; plan to add...
;; (define (delete-files)
;;   (print "File deleted! (not really)")
;;   (exit 0))

;;; This procedure is called whenever the user specifies the help
;;; option at runtime OR whenever an unexpected command line option or
;;; operand is passed to this script.
(define (usage)
 (with-output-to-port (current-error-port)
   (lambda ()
     (print "Usage: " (car (argv)) " [directory] [options...]")
     (newline)
     (print (args:usage opts))
     (print "Report bugs to nemo1211 at gmail.")))
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
;;; (video-path) to move them all.
(define (trash-video video-path)
  (let ((wild-files (pathname-replace-extension video-path "*")))
    (system (conc "mv " wild-files " " trash-path))))

;;; You can print the available files found with (file-list) using
;;; this procedure. If numberp is true, each video file printed is
;;; preceded with a unique number (useful for managing files, e.g.,
;;; for interactively deleting files)
(define (print-videos file-paths #!optional (numberp #f))
  (let ((video-names 
	 (map (lambda (path) (pathname-file path))
	      file-paths)))
    (if numberp
	;; Add numbering...
	(let ((filecount 0))
	  (for-each
	   (lambda (l) 
	     (begin 
	       (set! filecount (+ filecount 1))
	       (display (conc "[" filecount "] "))
	       (print l)))
	   (sort-videos video-names)))
	;; Else don't...
	(for-each (lambda (l) (print l)) (sort-videos video-names)))))

;;; Sort video file names alphabetically
(define (sort-videos myvideos)
  (sort (map string-titlecase myvideos)
	(lambda (a b) (string< a b))))

;;; Sort video file names IGNORING paths
(define (sort-videos-no-path myvideos)
  (sort (map string-titlecase myvideos)
	(lambda (a b) (string< (pathname-file a) (pathname-file b)))))


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
    (display "Enter number of file to delete (0 to abort): ")
    (let ((sorted-videos (sort-videos-no-path video-file-paths))
	  (target-file (string->number (read-line))))
      (newline)
      (printf "Moving ~s to trash\n\n" 
	      (pathname-file
	       (get-file sorted-videos target-file)))
      (if (eq? target-file 0)
	  (begin
	    (print "Aborted: 0 files changed")
	    (exit 1))
	  (trash-video (get-file sorted-videos target-file)))
      (exit 0))))


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

;;; This gets things done
;; (main)


;;; end of file dvr.scm
