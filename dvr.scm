#! /usr/local/bin/csi -s

;; (use shell)
;; (use args)
;; (use posix)
(require-extension shell)
(require-extension args)
(require-extension posix)

(define valid-extensions
  '("flv" "mov" "mp4" "wmv" "mkv" "mov" "avi" "mpg" "swf"))

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

;;; You can print the available files with this
(define (print-videos file-paths)
  (let ((video-names 
	 (map (lambda (path) (pathname-file path))
	      file-paths)))
    (for-each (lambda (l) (print l))
	      (sort (map string-titlecase video-names) (lambda (a b) (string< a b))))))

;;; Computes how much memory all the video files are consuming
;;; on the HDD. The value returned is the total memory in GB
(define (memory-used file-paths)
  (round (/ (apply + (map file-size file-paths)) (expt 1024 3))))

;;; Available space on HDD. This is an ugly hack, but it returns
;;; the available space on the hard drive (in GB)
(define (memory-free)
  (round (string->number
	  (irregex-replace "\n"
			   (capture ("df | grep '^/dev/' | awk '{s+=$4} END {print s/1048576}'"))))))

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

;;; ########################################
;;; LEGACY CODE
;;; ########################################

;; (define file-list 
;;   (find-files "." (lambda (path) (or 
;; 				  (string-suffix? ".flv" path)
;; 				  (string-suffix? ".mp4" path)
;; 				  (string-suffix? ".wmv" path)
;; 				  (string-suffix? ".mkv" path)
;; 				  (string-suffix? ".mov" path)))))

;;; Manual, debugging version that works on PWD
;; (define file-list
;;   (find-files "."
;; 	      (lambda (path)		
;; 		(member #t (map
;; 			    (lambda (ext) (string-suffix? ext path))
;; 			    valid-extensions)))))


;;; THIS SHOULDN'T BE NEEDED...Then you sort by finding the files that
;;; are movies.  Something like this:
;; (for-each 
;;  (lambda (file) 
;;    (if (irregex-search "mkv" file) (print file))) 
;;  tmp)

;; (define (main args)
;;   (begin
;;     (if (null? args)
;; 	(define video-file-paths (file-list default-path))
;; 	(define video-file-paths (file-list (car args))))
;;     (newline)
;;     (print-videos video-file-paths)
;;     ;; Show the total space used?
;;     (printf "~%~A Videos Total. ~AGB used (~AGB free).~%~%"
;; 	     (length video-file-paths)
;; 	     (memory-used video-file-paths)
;; 	     (memory-free))))
