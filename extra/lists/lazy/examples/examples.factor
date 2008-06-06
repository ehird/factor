! Rewritten by Matthew Willis, July 2006
! Copyright (C) 2004 Chris Double.
! See http://factorcode.org/license.txt for BSD license.

USING: lists.lazy math kernel sequences quotations ;
IN: lists.lazy.examples

: naturals 0 lfrom ;
: positives 1 lfrom ;
: evens 0 [ 2 + ] lfrom-by ;
: odds 1 lfrom [ 2 mod 1 = ] lfilter ;
: powers-of-2 1 [ 2 * ] lfrom-by ;
: ones 1 [ ] lfrom-by ;
: squares naturals [ dup * ] lazy-map ;
: first-five-squares 5 squares ltake list>array ;