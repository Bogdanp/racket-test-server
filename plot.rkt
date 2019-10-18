#lang racket/base

(require gregor
         gregor/period
         json
         plot
         racket/class
         racket/cmdline)
#;
(define-values (filenames gc-filenames)
  (values
   (list "results-flawed-old.json"
         "results-flawed-new.json")
   (list)))

#;
(define-values (filenames gc-filenames)
  (values
   (list "results-old.json"
        "results-new.json")
   (list)))

#;
(define-values (filenames gc-filenames)
  (values
   (list "results-old-200.json"
         "results-new-200.json")
   (list)))

#;
(define-values (filenames gc-filenames)
  (values
   (list "results-2s.100qps.old.json"
         "results-2s.100qps.new.json")
   (list)))

(define-values (filenames gc-filenames)
  (values
   (list "results-2s.100qps.old.json"
         "results-2s.100qps.gc.new.json")
   (list "gc-2s.100qps.gc.old.json"
         "gc-2s.100qps.gc.new.json")))

(define (load-dataset filename)
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

(define points-by-filename
  (for/hash ([filename (in-list filenames)])
    (define data (load-dataset filename))
    (define first-moment (iso8601->moment (hash-ref (car data) 'timestamp)))
    (define points
      (for/list ([data-point (in-list data)])
        (list (milliseconds-between
               first-moment
               (iso8601->moment (hash-ref data-point 'timestamp)))
              ;; latency is provided in nanos
              (/ (hash-ref data-point 'latency) 1000000))))

    (values filename points)))

(define gc-points-by-filename
  (for/hash ([filename (in-list gc-filenames)])
    (define data (load-dataset filename))
    (define first-moment (iso8601->moment (hash-ref (car data) 'timestamp)))
    (define points
      (for/list ([data-point (in-list data)])
        (list (milliseconds-between
               first-moment
               (iso8601->moment (hash-ref data-point 'timestamp)))
              (/ (hash-ref data-point 'duration) 1000))))

    (values filename points)))

(define (scale-y points by)
  (for/list ([point (in-list points)])
    (list (car point)
          (by (cadr point)))))

(plot-new-window? #t)
(parameterize ([plot-pen-color-map 'tab20]
               [plot-y-far-label "gc duration"]
               [plot-y-far-ticks (ticks-scale (plot-y-ticks)
                                              (invertible-function (lambda (x) (- x 2000))
                                                                   (lambda (x) (+ x 2000))))])
  (plot #:width 1600
        #:height 600
        #:x-label "time"
        #:y-label "duration"
        (list
         (for/list ([(filename ps) (in-hash points-by-filename)])
           (lines ps
                  #:label filename
                  #:color (if (regexp-match? #rx"old" filename) 6 4)
                  #:alpha 0.75))
         (for/list ([(filename ps) (in-hash gc-points-by-filename)])
           (points (scale-y ps (lambda (y) (+ 2000 y)))
                   #:label filename
                   #:sym 'times
                   #:size 10
                   #:color (if (regexp-match? #rx"old" filename) 13 0))))))
