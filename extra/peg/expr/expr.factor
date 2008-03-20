! Copyright (C) 2008 Chris Double.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel arrays strings math.parser sequences
peg peg.ebnf peg.parsers memoize math ;
IN: peg.expr

: operator-fold ( lhs seq -- value )
 #! Perform a fold of a lhs, followed by a sequence of pairs being
 #! { operator rhs } in to a tree structure of the correct precedence.
 swap [ first2 swap call ] reduce ;

<EBNF

times    = ("*") [[ drop [ * ] ]]
divide   = ("/") [[ drop [ / ] ]]
add      = ("+") [[ drop [ + ] ]]
subtract = ("-") [[ drop [ - ] ]]

digit    = "0" | "1" | "2" | "3" | "4" |
           "5" | "6" | "7" | "8" | "9" 
number   = ((digit)+) [[ concat string>number ]]

value    = number | ("(" expr ")") [[ second ]] 
product = (value ((times | divide) value)*) [[ first2 operator-fold ]]
sum = (product ((add | subtract) product)*) [[ first2 operator-fold ]]
expr = sum
EBNF>

: eval-expr ( string -- number )
  expr parse parse-result-ast ;