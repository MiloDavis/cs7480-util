#lang racket

;; Tools for expanding & normalizing syntax objects

(provide
 ;; (-> Path-String (Free-Id-Table Syntax))
 ;; Parse a module declaration from a file,
 ;;  fully expand the result syntax object,
 ;;  collect & return a map from all identifiers to their expanded bodies.
 ;; May not work if define-values creates multiple values
 file-definitions
 
 ;; (-> Path-String Syntax)
 ;; Parse a module and return the fully expanded syntax object
 read-and-expand

 ;; (-> Syntax (Free-Id-Table Syntax))
 ;; Given a syntax object, create a map from identifiers to their bodies
 ;; May not work if syntax object is not fully expanded
 syntax-object-definitions
 
)

(require
  syntax/parse
  syntax/id-table
  lang-file/read-lang-file
)

;; =============================================================================

(define (file-definitions path-str)
  (syntax-object-definitions (read-and-expand path-str)))

(define (read-and-expand path-str)
  (parameterize ([current-namespace (make-base-namespace)]
                 [current-directory (path-only path-str)]
                 [current-load-relative-directory
                  (path->complete-path (path-only path-str))])
    (expand (read-lang-file (file-name-from-path path-str)))))

(define (syntax-object-definitions stx)
  (define definitions (make-free-id-table))
  (define (get-definitions-help stx)
    (syntax-parse stx
      #:literals (define-values)
      ((define-values (vars ...) bodies ...)
       (for ((v (syntax-e #'(vars ...)))
             (body (in-list (syntax-e #'(bodies ...)))))
         (dict-set! definitions v body)))
      ((x ...)
       (for-each get-definitions-help (syntax-e #'(x ...))))
      (_ void)))
  (get-definitions-help stx)
  definitions)

;; =============================================================================

(module+ test
  (require rackunit)

  ;; TODO

)
