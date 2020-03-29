%{

/* Declarations section */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#define MAX_STR_CONST 1024
#define LOW_PRINTABLE_ASCII_DEC 32
#define HIGH_PRINTABLE_ASCII_DEC 126

char string_buf[MAX_STR_CONST];
char *string_buf_ptr;
 
		   
void showToken(char *);
void error_handler();
void handle_u_esc_seq();
void strToUpper(char* str);

int comment_line_count=1;

%}

%x OneLineComment MultipleLinesComment STRING

%option yylineno
%option noyywrap

digit		([0-9])
digits		({digit}+)
letter		([a-zA-Z])
letters		({letter}+) 
whitespace	([\t\n\r ])

ID   		((_({letter}|{digit})+)|({letter})({letter}|{digit})*)
BIN_INT		(0b)([01])+
OCT_INT		(0o)([0-7])+
DEC_INT		{digits}
HEX_INT		(0x)[a-fA-F0-9]+

DEC_REAL	(({DEC_INT}?(\.)({DEC_INT}))|({DEC_INT}(\.)({DEC_INT})?)([Ee][\+\-]{DEC_INT})?)
HEX_FP		(0x)([a-fA-F0-9]+)([pP])[\-+](0|[1-9][0-9]*)

TYPE		(Int|Double|Float|UInt|Bool|String|Character)
VAR			(var)
LET			(let)
FUNC		(func)
IMPORT		(import)
NIL			(nil)
WHILE		(while)
IF			(if)
ELSE		(else)
RETURN		(return)
SC			[;]
COMMA		[,]
LPAREN		[(]
RPAREN		[)]
LBRACE		[{]
RBRACE		[}]
LBRACKET	[[]
RBRACKET	[]]
ASSIGN		[=]
RELOP		(=<|=>|<|>|=!|==)
LOGOP		(&&|[|][|])
BINOP		([+]|[-]|[*]|[/]|[%])
TRUE		(true)
FALSE		(false)
ARROW		(->)
COLON		[:]
ESCSEQ		(\\u\{([a-fA-F0-9]){1,6}\})
not_hex		((([a-fA-F0-9])*([^a-fA-F0-9\}])+([a-fA-F0-9])*)*)
BAD_ESCSEQ	(\\u\{((([^\}]){7,})|({not_hex}))\})


%%

{BIN_INT}		showToken("BIN_INT");
{OCT_INT}		showToken("OCT_INT");
{DEC_INT}		showToken("DEC_INT");
{HEX_INT}		showToken("HEX_INT");
{DEC_REAL}    	showToken("DEC_REAL");
{HEX_FP}		showToken("HEX_FP");
{TYPE}		    showToken("TYPE");
{VAR}		    showToken("VAR");
{LET}		    showToken("LET");
{FUNC}		    showToken("FUNC");
{IMPORT}	    showToken("IMPORT");
{NIL}		    showToken("NIL");
{WHILE}		    showToken("WHILE");
{IF}		    showToken("IF");
{ELSE}		    showToken("ELSE");
{RETURN}	    showToken("RETURN");
{SC}		    showToken("SC");
{COMMA}		    showToken("COMMA");
{LPAREN}	    showToken("LPAREN");
{RPAREN}	    showToken("RPAREN");
{LBRACE}	    showToken("LBRACE");
{RBRACE}	    showToken("RBRACE");
{LBRACKET}	    showToken("LBRACKET");
{RBRACKET}	    showToken("RBRACKET");
{ASSIGN}	    showToken("ASSIGN");
{RELOP}		    showToken("RELOP");
{LOGOP}		    showToken("LOGOP");
{BINOP}		    showToken("BINOP");
{TRUE}		    showToken("TRUE");
{FALSE}		    showToken("FALSE");
{ARROW}		    showToken("ARROW");
{COLON}		    showToken("COLON");

"/*"                        {  
								BEGIN(MultipleLinesComment);
							}							

<MultipleLinesComment>("\n"|"\r\n"|"\r")  comment_line_count++;
<MultipleLinesComment>"*/"  {
								printf("%d COMMENT %d\n",yylineno,comment_line_count);
								BEGIN(INITIAL);
							}
<MultipleLinesComment,OneLineComment>"/*"	{	printf ("Warning nested comment\n");	exit(0);	} 
<MultipleLinesComment><<EOF>> 				{	printf ("Error unclosed comment\n");	exit(0);	}
<MultipleLinesComment>.		
					

"//"                        BEGIN(OneLineComment);

<OneLineComment>("\n"|"\r\n"|"\r") {							
								printf("%d COMMENT %d\n",yylineno,1);
								BEGIN(INITIAL);
                            }
<OneLineComment><<EOF>> {							
								printf("%d COMMENT %d\n",yylineno,1);
								BEGIN(INITIAL);
                            }

								
<OneLineComment>.						
	
			
						
\"                      {  	string_buf_ptr = string_buf; BEGIN(STRING); }
							
<STRING>\n        		{		printf("Error unclosed string\n"); 	 exit(0);		}
						

<STRING>\"  			{	
							*string_buf_ptr = '\0';
                            printf("%d STRING %s\n",yylineno,string_buf);
							
                            BEGIN(INITIAL);
                        }
<STRING>\\n 			*string_buf_ptr++ = '\n';
<STRING>\\t  			*string_buf_ptr++ = '\t';
<STRING>\\r		 	 	*string_buf_ptr++ = '\r';
<STRING>\\				*string_buf_ptr++ = '\\' ;
<STRING>\\\" 	 		*string_buf_ptr++ = '\"'; 


<STRING>({ESCSEQ}) 		{ 	handle_u_esc_seq();		}
<STRING>({BAD_ESCSEQ}) 	{ 	printf("Error undefined escape sequence u\n");	 exit(0);	}
					
<STRING>\\.				{	printf("Error undefined escape sequence %s\n",yytext+1); exit(0);	}				

<STRING>[^\\\n\"]+      {
								char *yptr = yytext;

								while ( *yptr ){
								*string_buf_ptr++ = *yptr++;
								}
						}
		
						
{ID}          showToken("ID");
{whitespace}	;	

.				error_handler();


%%

void showToken(char * name)
{	
	if(strcmp(name,"BIN_INT")==0) {
		int dec_num=(int)strtol(yytext+2, NULL, 2);
		printf("%d %s %d\n", yylineno, name, dec_num);
		return;
	}
	if(strcmp(name,"OCT_INT")==0){
	
		int dec_num=(int)strtol(yytext+2, NULL, 8);
		printf("%d %s %d\n", yylineno, name,dec_num);
		return;
	}
	if(strcmp(name,"HEX_INT")==0){
		
		strToUpper(yytext);
		int dec_num=(int)strtol(yytext+2, NULL, 16);
		printf("%d %s %d\n", yylineno, name, dec_num);
		return;
	}
	printf("%d %s %s\n", yylineno, name, yytext);
	
}

void error_handler(){
	printf("Error %s\n",yytext);
	exit(0);
}

void handle_u_esc_seq(){
	yytext[yyleng-1]='\0'; 
	int dec_num=(int)strtol(yytext+3, NULL, 16);
	if (dec_num > HIGH_PRINTABLE_ASCII_DEC || dec_num < LOW_PRINTABLE_ASCII_DEC){ 
		printf("Error undefined escape sequence u\n");
		exit(0);
		
	}
	*string_buf_ptr++ = (char)(dec_num);
}
void strToUpper(char* str){
	char* ptr=str;
	while (*ptr){
		*ptr++=toupper(*ptr);
		
	}
	
}













