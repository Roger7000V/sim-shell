#include "parser.h"

#include <stdio.h>

#include <limits.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

extern char* input;

char* copy_str(const char* src, bool rm_quot) {
    size_t len = strlen(src);
    char* dst;

    if (rm_quot) {
        len -= 2;
        dst = malloc(len + 1);
        if (dst == NULL) { return NULL; }
        strncpy(dst, src + 1, len);
    } else {
        dst = malloc(len + 1);
        if (dst == NULL) { return NULL; }
        strncpy(dst, src, len);
    }

    dst[len] = '\0';
    return dst;
}

%%{
machine sh_parser;
write data;

whitesp   = space | '\t' | '\n';
arg       = alnum+;
sing_quot = '\'' any* '\'';
doub_quot = '\"' any* '\"';
backquot  = '`' any* '`';

main := |*
    whitesp*  => { ret = WHITESP; };
    '|'       => { ret = PIPE; yylval.lexeme = ts; fbreak; };
    ';'       => { ret = SEQ; yylval.lexeme = ts; fbreak; };
    '<'       => { ret = REDIR_IN; yylval.lexeme = ts; fbreak; };
    '>'       => { ret = REDIR_OUT; yylval.lexeme = ts; fbreak; };
    arg       => { ret = ARG; yylval.lexeme = ts; fbreak; };
    sing_quot => { ret = SING_QUOT; yylval.lexeme = copy_str(ts, true); fbreak; };
    doub_quot => { ret = DOUB_QUOT; yylval.lexeme = copy_str(ts, true); fbreak; };
    backquot  => { ret = BACKQUOT; yylval.lexeme = copy_str(ts, true); fbreak; };
    whitesp*  => { ret = WHITESP; };
*|;
}%%

int yylex(YYSTYPE yylval) {
    int ret = INT_MAX;
    int cs, act;
    const char* ts;
    const char* te;

    (void) sh_parser_first_final;
    (void) sh_parser_error;
    (void) sh_parser_en_main;

%% write init;

    const char* p = input;
    const char* pe = input + strlen(input);
    const char* eof = pe;

    if (p == eof) {
        return 0;
    }

%% write exec;

    return ret == INT_MAX ? 0 : ret;
}
