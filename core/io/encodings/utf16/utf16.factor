! Copyright (C) 2006, 2007 Daniel Ehrenberg.
! See http://factorcode.org/license.txt for BSD license.
USING: math kernel sequences sbufs vectors namespaces io.binary
io.encodings combinators splitting ;
IN: io.utf16

SYMBOL: double
SYMBOL: quad1
SYMBOL: quad2
SYMBOL: quad3
SYMBOL: ignore

: do-ignore ( -- ch state ) 0 ignore ;

: append-nums ( byte ch -- ch )
    8 shift bitor ;

: end-multibyte ( buf byte ch -- buf ch state )
    append-nums decoded ;

: begin-utf16be ( buf byte -- buf ch state )
    dup -3 shift BIN: 11011 number= [
        dup BIN: 00000100 bitand zero?
        [ BIN: 11 bitand quad1 ]
        [ drop do-ignore ] if
    ] [ double ] if ;

: handle-quad2be ( byte ch -- ch state )
    swap dup -2 shift BIN: 110111 number= [
        >r 2 shift r> BIN: 11 bitand bitor quad3
    ] [ 2drop do-ignore ] if ;

: decode-utf16be-step ( buf byte ch state -- buf ch state )
    {
        { begin [ drop begin-utf16be ] }
        { double [ end-multibyte ] }
        { quad1 [ append-nums quad2 ] }
        { quad2 [ handle-quad2be ] }
        { quad3 [ append-nums HEX: 10000 + decoded ] }
        { ignore [ 2drop push-replacement ] }
    } case ;

: decode-utf16be ( seq -- str )
    [ decode-utf16be-step ] decode ;

: handle-double ( buf byte ch -- buf ch state )
    swap dup -3 shift BIN: 11011 = [
        dup BIN: 100 bitand 0 number=
        [ BIN: 11 bitand 8 shift bitor quad2 ]
        [ 2drop push-replacement ] if
    ] [ end-multibyte ] if ;

: handle-quad3le ( buf byte ch -- buf ch state )
    swap dup -2 shift BIN: 110111 = [
        BIN: 11 bitand append-nums HEX: 10000 + decoded
    ] [ 2drop push-replacement ] if ;

: decode-utf16le-step ( buf byte ch state -- buf ch state )
    {
        { begin [ drop double ] }
        { double [ handle-double ] }
        { quad1 [ append-nums quad2 ] }
        { quad2 [ 10 shift bitor quad3 ] }
        { quad3 [ handle-quad3le ] }
    } case ;

: decode-utf16le ( seq -- str )
    [ decode-utf16le-step ] decode ;

: encode-first
    -10 shift
    dup -8 shift BIN: 11011000 bitor
    swap HEX: FF bitand ;

: encode-second
    BIN: 1111111111 bitand
    dup -8 shift BIN: 11011100 bitor
    swap BIN: 11111111 bitand ;

: char>utf16be ( char -- )
    dup HEX: FFFF > [
        HEX: 10000 -
        dup encode-first swap , ,
        encode-second swap , ,
    ] [ h>b/b , , ] if ;

: encode-utf16be ( str -- seq )
    [ [ char>utf16be ] each ] B{ } make ;

: char>utf16le ( char -- )
    dup HEX: FFFF > [
        HEX: 10000 -
        dup encode-first , ,
        encode-second , ,
    ] [ h>b/b swap , , ] if ; 

: encode-utf16le ( str -- seq )
    [ [ char>utf16le ] each ] B{ } make ;

: bom-le B{ HEX: ff HEX: fe } ; inline

: bom-be B{ HEX: fe HEX: ff } ; inline

: encode-utf16 ( str -- seq )
    encode-utf16le bom-le swap append ;

: utf16le? ( seq1 -- seq2 ? ) bom-le ?head ;

: utf16be? ( seq1 -- seq2 ? ) bom-be ?head ;

: decode-utf16 ( seq -- str )
    {
        { [ utf16le? ] [ decode-utf16le ] }
        { [ utf16be? ] [ decode-utf16be ] }
        { [ t ] [ decode-error ] }
    } cond ;

TUPLE: utf16le ;
: <utf16le> utf16le construct-delegate ;
INSTANCE: utf16le encoding-stream 

M: utf16le encode-string drop encode-utf16le ;
M: utf16le decode-step drop decode-utf16le-step ;

TUPLE: utf16be ;
: <utf16be> utf16be construct-delegate ;
INSTANCE: utf16be encoding-stream 

M: utf16be encode-string drop encode-utf16be ;
M: utf16le decode-step drop decode-utf16be-step ;