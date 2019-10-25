#lang racket/base

(require gregor
         gregor/period
         json
         plot
         racket/class
         racket/cmdline)

(define-values (filenames gc-filenames)
  (values
   (list "100qps.old.json"
         "100qps.new.json")
   (list "gc-100qps.old.json"
         "gc-100qps.new.json")))

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

(define memory-use-by-filename
  (for/hash ([filename (in-list gc-filenames)])
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
               [plot-y-far-label "memory use (kb)"]
               [plot-y-far-ticks (ticks-scale (plot-y-ticks)
                                              (invertible-function (lambda (x) (* (- x 2000) 40))
                                                                   (lambda (x) (/ (+ x 2000) 40))))])
  (plot #:width 1600
        #:height 600
        #:x-label "time"
        #:y-label "duration"
        (list
         (for/list ([(filename ps) (in-hash points-by-filename)])
           (lines ps
                  #:label filename
                  #:color (cond
                            [(regexp-match? #rx"old" filename) 13]
                            [(regexp-match? #rx"latest" filename) 2]
                            [else 0])
                  #:alpha 0.75))
         (for/list ([(filename ps) (in-hash memory-use-by-filename)])
           (lines (scale-y ps (lambda (y) (+ 2000 (/ (/ y 1000) 40))))
                  #:label filename
                  #:color (cond
                            [(regexp-match? #rx"old" filename) 13]
                            [(regexp-match? #rx"latest" filename) 2]
                            [else 0])))
         (for/list ([(filename ps) (in-hash gc-points-by-filename)])
           (points (scale-y ps (lambda (y) (+ 2000 y)))
                   #:label filename
                   #:sym 'times
                   #:size 10
                   #:color (cond
                             [(regexp-match? #rx"old" filename) 13]
                             [(regexp-match? #rx"latest" filename) 2]
                             [else 0]))))))
