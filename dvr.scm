#! /usr/local/bin/csi -s

(require-extension shell)
(require-extension args)
(require-extension posix)

;;; Files ending in the following extensions will be
;;; included in all operations. Add accordingly
(define valid-extensions
  '("flv" "mov" "mp4" "wmv" "mkv" "mov" "avi" "mpg" "swf"))

;;; The script expects a user-supplied target path at runtime.
;;; If no path is supplied, the following default is used. For
;;; more general audiences, this should probably be changed to "."
(define default-path "~/media/Television/")

;;; This does all the heavy lifting. It recursively scans the supplied
;;; directory, returning a list of file paths that end in any
;;; extension contained in valid-extensions. 
(define (file-list file-path)
  (find-files file-path
	      test: (lambda (path)		
		(member #t (map
			    (lambda (ext) (string-suffix? ext path))
			    valid-extensions)))))

;;; You can print the available files found with (file-list) using
;;; this procedure
(define (print-videos file-paths)
  (let ((video-names 
	 (map (lambda (path) (pathname-file path))
	      file-paths)))
    (for-each (lambda (l) (print l))
	      (sort (map string-titlecase video-names) (lambda (a b) (string< a b))))))

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

;;; This needs to be explicitly called for anything to happen
;;; at runtime. (main) is called below. 
(define (main)
  (begin
    (define myargs (command-line-arguments))
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

;;; This gets things done
(main)

;;; end of file dvr.scm
