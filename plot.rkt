#lang racket/base

(require gregor
         gregor/period
         json
         plot
         racket/class
         racket/cmdline)
#;
(define filenames
  (list "results-flawed-old.json"
        "results-flawed-new.json"))

#;
(define filenames
  (list "results-old.json"
        "results-new.json"))


(define filenames
  (list "results-old-200.json"
        "results-new-200.json"))

(define points-by-filename
  (for/hash ([filename (in-list filenames)])
    (define data
      (sort
       (with-input-from-file filename
         (lambda _
           (let loop ([data null])
             (define data-line (read-json))
             (cond
               [(eof-object? data-line) data]
               [else (loop (cons data-line data))]))))
       string-ci<?
       #:key (lambda (d)
               (hash-ref d 'timestamp))))

    (define first-moment (iso8601->moment (hash-ref (car data) 'timestamp)))
    (define points
      (for/list ([data-point (in-list data)])
        (list (milliseconds-between
               first-moment
               (iso8601->moment (hash-ref data-point 'timestamp)))
              ;; latency is provided in nanos
              (/ (hash-ref data-point 'latency) 1000000))))

    (values filename points)))

(plot #:width 1600
      #:height 600
      #:x-label "time"
      #:y-label "duration"
      (for/list ([(filename ps) (in-hash points-by-filename)])
          (lines ps
                 #:label filename
                 #:color (if (regexp-match? #rx"old" filename) 1 2))))