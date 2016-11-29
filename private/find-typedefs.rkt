#lang racket
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

   get-type
   )

  (require
   "find-required.rkt"
   "find-defs.rkt"
   (submod typed-racket/base-env/base-types initialize)
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
   (for-template (only-in typed-racket/typed-racket do-standard-inits)
                 typed-racket/base-env/base-types
                 typed-racket/base-env/colon
                 typed-racket/rep/type-rep
                 racket/require
                 syntax/location
                 typed-racket/base-env/base-types-extra))

  ;; ===========================================================================

  (define (get-typedefs path)
    (define po (path->string (path-only path)))
    (parameterize ([current-directory po]
                   [current-load-relative-directory
                    (path->complete-path po)])
      (find-file-typedefs (path->string (file-name-from-path path)))))

  (define (find-file-typedefs path-str)
    (do-standard-inits)
    (for/fold ([acc (make-immutable-free-id-table)])
              ([path (in-list (module->typed-files path-str))])
      (syntax-object->typedefs (read-and-expand (path->string path)) acc)))

  ;; Needs more information about required/provided functions to actually work
  (define (syntax-object->typedefs stx [cur-typedefs (make-immutable-free-id-table)])
    (define (find-typedefs-help stx table)
      (syntax-parse stx
        [t:type-declaration (dict-set table #'t.id #'t.type)]
        [(x ...)
         (for/fold ([acc table])
                   ([new-stx (syntax-e #'(x ...))])
           (find-typedefs-help new-stx acc))]
        [_ table]))
    (find-typedefs-help stx cur-typedefs))

  (define (get-type type-env id)
    (cond [(dict-ref type-env id #f)]
          [(syntax-property id 'origin) (get-type type-env (syntax-property id 'origin))]
          [else #f]))

  (module+ test
    (require rackunit rackunit/text-ui)
    
    ))
