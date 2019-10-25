#lang racket/base

(require gregor
         gregor/period
         json
         plot
         racket/class
         racket/cmdline)

(define filenames
  (list "gc-slowloris.old.json"
        "gc-slowloris.new.json"))

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
  (for/hash ([filename (in-list filenames)])
    (define data (load-dataset filename))
    (define first-moment (iso8601->moment (hash-ref (car data) 'timestamp)))
    (define points
      (for/list ([data-point (in-list data)])
        (list (milliseconds-between
               first-moment
               (iso8601->moment (hash-ref data-point 'timestamp)))
              (/ (hash-ref data-point 'duration) 1000))))

    (values filename points)))

(define memory-use-by-filename
  (for/hash ([filename (in-list filenames)])
    (define data (load-dataset filename))
    (define first-moment (iso8601->moment (hash-ref (car data) 'timestamp)))
    (define points
      (for/list ([data-point (in-list data)])
        (list (milliseconds-between
               first-moment
               (iso8601->moment (hash-ref data-point 'timestamp)))
              (hash-ref data-point 'before))))

    (values filename points)))

(define (scale-y points by)
  (for/list ([point (in-list points)])
    (list (car point)
          (by (cadr point)))))

(parameterize ([plot-new-window? #t]
               [plot-pen-color-map 'tab20]
               [plot-y-far-label "memory use (mb)"]
               [plot-y-far-ticks (ticks-scale (plot-y-ticks)
                                              (invertible-function (lambda (x) (* x 1))
                                                                   (lambda (x) (/ x 1))))])
  (plot #:width 1600
        #:height 600
        #:x-label "time"
        #:y-label "gc duration (ms)"
        (list
         (for/list ([(filename ps) (in-hash memory-use-by-filename)])
           (lines (scale-y ps (lambda (y) (/ (/ y 1024 1024) 1)))
                  #:label filename
                  #:color (cond
                            [(regexp-match? #rx"old" filename) 13]
                            [else 0])))
         (for/list ([(filename ps) (in-hash gc-points-by-filename)])
           (points ps
                   #:label filename
                   #:sym 'times
                   #:size 10
                   #:color (cond
                             [(regexp-match? #rx"old" filename) 13]
                             [else 0]))))))
