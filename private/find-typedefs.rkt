#lang racket

;; WARNING: this module is not in good shape. The tests are not passing.

(begin-for-syntax

  ;; EVERY USE OF `parse-type` NEEDS TO HAPPEN IN THIS FILE.

  ;; 2016-08-02: we don't know how to successfully call Typed Racket's `parse-type`
  ;;  except inside a `begin-for-syntax` after calling `(do-standard-inits)` and
  ;;  with the right magic words of Typed Racket requires.

  (provide
   get-typedefs
   ;; (-> Path-String (Free-Id-Table Type))
   ;;bg: idk, sounds like this is doing what `find-file-typedefs` should be doing

   find-file-typedefs
   ;; (-> Path-String (Free-Id-Table Type))
   ;; Parse a module declaration from a file,
   ;;  fully expand the module,
   ;;  collect & return a map from exported identifiers to their types.

   find-typedefs
   ;; (-> Syntax (Free-Id-Table Type))
   ;; Parse a syntax object for all type declarations.
   ;; Return a map from identifiers to their (parsed) types.

   typed-vector-introducer?
   ;; (-> Type Boolean)
   ;; Returns true if the argument type has a Vector in a positive position.

   )

  (require
   "find-defs.rkt"
   (submod typed-racket/base-env/base-types initialize)
   racket/match
   racket/dict
   racket/path
   syntax/parse
   syntax/id-table
   typed-racket/base-env/base-structs
   typed-racket/env/mvar-env
   typed-racket/env/tvar-env
   typed-racket/env/type-alias-env
   typed-racket/private/parse-type
   typed-racket/rep/type-rep
   typed-racket/typecheck/internal-forms
   typed-racket/types/numeric-tower
   typed-racket/types/resolve
   typed-racket/types/subtype
   typed-racket/types/union
   typed-racket/utils/tc-utils
   (only-in typed-racket/base-env/base-types-extra ->)
   (for-template (only-in typed-racket/typed-racket do-standard-inits)
                 typed-racket/base-env/base-types
                 typed-racket/base-env/colon
                 (except-in typed-racket/rep/type-rep Un)
                 racket/require
                 syntax/location))

  ;; ===========================================================================

  (define (get-typedefs path)
    (parameterize ([current-directory (path-only path)]
                   [current-load-relative-directory
                    (path->complete-path (path-only path))])
      (find-file-typedefs (file-name-from-path path))))

  (define (find-file-typedefs path-str)
    (parameterize ([current-namespace (make-base-namespace )])
      (do-standard-inits)
      (find-typedefs (read-and-expand path-str))))

  ;; (require typed-racket/private/parse-type)
  ;; Needs more information about required/provided functions to actually work
  (define (find-typedefs stx)
    (define typedefs (make-free-id-table))
    (define (find-typedefs-help stx)
      (syntax-parse stx
        (t:type-declaration
         (dict-set! typedefs #'t.id (parse-type #'t.type)))
        ((x ...)
         (for-each find-typedefs-help (syntax-e #'(x ...))))
        (_
         (void))))
    (find-typedefs-help stx)
    typedefs)

  ;; TODO: works for values return, case lambda, and pairs/lists
  (define (typed-vector-introducer? type)
    #t                                  ; TODO start extracting types again
    #;(match type
      [(Function: arrs)
       (match (car arrs)
         [(arr: _ (Values: (list (Result: cod _ _))) _ _ _)
          (subtype cod (parse-type #'VectorTop))]
         [_ (error "not an arity")])]
      [_ (subtype type (parse-type #'VectorTop))]))

  #;(module+ test
       (require rackunit rackunit/text-ui)
       (define-test-suite test-types

         ;; This makes me doubt that this procedure should return
         (test-false "parse Natural" (typed-vector-introducer? (parse-type #'Natural)))
         (test-true "parse Vectorof Natural" (typed-vector-introducer? (parse-type #'(Vectorof Natural))))
         (test-true "typed vector introducer 1"
                    (typed-vector-introducer? (parse-type #'(-> (Vectorof Natural)
                                                                (Vectorof Natural)))))
         (test-false "typed vector introducer 2"
                     (typed-vector-introducer? (parse-type #'(-> (Vectorof Natural) Integer))))
         )
       (void (run-tests test-types))
       ))
