#lang scribble/manual

@require[cs7480-util (for-label racket/base racket/contract)]

@title[#:tag "top"]{CS7480 Utilities}

@author["Ben Greenman" "Milo Davis"]

@defmodule[cs7480-util]


TODO


@defproc[(module->typed-identifiers [path path-string?]) (listof identifier?)]{
Return a list of identifiers referenced in a module that came
from another module defined with @hash-lang[] @racket[typed/racket] or @hash-lang[] @racket[typed/racket/base]}

@defproc[(module->required-identifiers [path path-string?][#:only-from only-from (or/c #f path-string? (listof path-string?))])
         (listof identifier?)]{
Return a list of identifiers referenced in a @racket[module] that are defined externally.
If @racket[#:only-from] is non-@racket[#f], the list is filtered to have only identifiers provided
by one of the @racket[#:only-from] modules.}


@defthing[definition-dict/c (free-id-table? identifier? syntax?)]{TODO}

@defproc[(file-definitions [path path-string?]) definition-dict/c]{
Parse a @racket[module] declaration from a file,
fully expand the result syntax object,
and collect a map from all identifiers to their expanded bodies.
@bold{May not work if define-values creates multiple values}}

@defproc[(syntax-object-definitions [stx syntax?]) definition-dict/c]{
Given a syntax object, create a map from identifiers to their bodies
@bold{May not work if syntax object is not fully expanded}}

@defproc[(read-and-expand [path path-string?]) syntax?]{
Parse a module and return the fully expanded syntax object}
