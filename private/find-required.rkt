#lang racket/base

(provide
 module->typed-identifiers
  ;; (-> [Path-String] (Listof Identifier))
  ;; Return a list of identifiers referenced in a module that came
  ;;  from another module defined with #lang typed/racket or #lang typed/racket/base

 module->required-identifiers
  ;; (->* [Path-String] [#:only-from (U #f Path-String (Listof Path-String))] (Listof Identifier))
  ;; Return a list of identifiers referenced in a module that are defined externally.
  ;; If `#:only-from` is non-#f, the list is filtered to have only identifiers provided
  ;;  by one of the `#:only-from` modules.
)

(require
  drracket/check-syntax
  lang-file/read-lang-file
  racket/class
  racket/set
  (only-in racket/path path-only)
  (only-in racket/string string-prefix?)
  setup/collects)

;; =============================================================================

;; (-> Path-String Boolean)
(define current-path-filter (make-parameter (lambda (x) x)))

(define (module->typed-identifiers path-string)
  (define tr-cache (mutable-set))
  (define (tr-filter p)
    (or (set-member? tr-cache p)
        (and (eq? p (path->collects-relative p)) ;;bg; filter identifiers from collections
             (let ([lang (lang-file-lang p)])
               (and lang
                    (string-prefix? lang "typed/racket"))
                    (set-add! tr-cache p)
                    #t))))
  (parameterize ([current-path-filter tr-filter])
    (get-required/internal path-string)))

(define (module->required-identifiers path-string #:only-from only-from0)
  (define only-from
    (map (compose1 simplify-path path->complete-path)
         (cond
           [(path-string? only-from0) (list only-from0)]
           [(eq? #f only-from0)       (list)]
           [else                      only-from0])))
  (define (only-from-filter p)
    (member p only-from))
  (parameterize ([current-path-filter only-from-filter])
    (get-required/internal path-string)))

(define (get-required/internal path-string)
  (define annotations (new collector%))
  (define ns (make-base-namespace))
  (define-values (add-syntax done)
    (make-traversal ns #f))
  (parameterize ([current-annotations annotations]
                 [current-namespace ns]
                 [current-load-relative-directory (path->complete-path (path-only path-string))])
    (add-syntax (expand (read-lang-file path-string)))
    (done))
  (send annotations collected-identifiers))

;; Overrides the `current-annotations` parameter for check-syntax.
(define collector%
  (class (annotations-mixin object%)
    (super-new)

    (define ids
      (mutable-set))

    (define/public (collected-identifiers)
      (set->list ids))

    ;; Every non-#f syntax object is interesting
    (define/override (syncheck:find-source-object stx)
      stx)

    (define/override (syncheck:add-jump-to-definition source-obj start end id filename submods)
      (when ((current-path-filter) filename)
        (set-add! ids source-obj)))))

