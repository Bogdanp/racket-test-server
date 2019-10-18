#lang racket

(require json
         net/url
         threading
         web-server/dispatch
         web-server/http)

(define (get-numbers recipient url)
  (thread
   (λ ()
     ;; numberserver.go is designed such that 10% of all requests to it
     ;; will fail with "service unavailable" so we ignore those errors
     ;; in particular.
     (with-handlers ([(lambda (e)
                        (and (exn:fail? e)
                             (regexp-match? #rx"bad input starting" (exn-message e))))
                      void])
       (define nums
         (~> url
             (bytes->string/utf-8)
             (string->url)
             (get-pure-port)
             (read-json)
             (hash-ref 'numbers)
             (sort <)))

       (thread-send recipient '(1 2 3 4 5 6 7))))))

(define (process-numbers req)
  (define alarm
    (alarm-evt (+ (current-inexact-milliseconds) 400)))

  (define urls
    (map binding:form-value
         (~>> (request-bindings/raw req)
              (bindings-assq-all #"u"))))

  (define threads
    (for/list ([url (in-list urls)])
      (get-numbers (current-thread) url)))

  (define nums
    (let loop ([nums '()] [n 1])
      (sync
       (handle-evt
        (thread-receive-evt)
        (λ _
          (define res (thread-receive))
          (define new-nums
            (if res
                (remove-duplicates (append nums res))
                nums))
          (cond
            [(= n (length urls)) new-nums]
            [else (loop new-nums (add1 n))])))
       (handle-evt
        alarm
        (λ _ nums)))))

  (sleep 2)
  (response/output
   #:code 200
   #:mime-type #"application/json; charset=utf-8"
   (lambda (out)
     (write-json (hash 'numbers nums) out))))

(define-values (go _)
  (dispatch-rules
   [("numbers") process-numbers]))

(module+ main
  (require web-server/servlet-dispatch
           web-server/web-server)

  (define shutdown
    (serve
     #:dispatch (dispatch/servlet go)
     #:port 3000
     #:initial-connection-timeout 30))

  (displayln "Listening on port 3000")
  (with-handlers ([exn:break? (lambda _ (shutdown))])
    (sync never-evt)))
