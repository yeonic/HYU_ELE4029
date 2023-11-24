/****************************************************/
/* File: cminus.y                                   */
/* The TINY Yacc/Bison specification file           */
/* Compiler Construction: Principles and Practice   */
/* Kenneth C. Louden                                */
/****************************************************/
%{
#define YYPARSER /* distinguishes Yacc output from other code files */

#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *
static TreeNode * savedTree; /* stores syntax tree for later return */
static int yyerror(char * message);
static int yylex(void); // added 11/2/11 to ensure no conflict with lex
%}

%token IF WHILE RETURN INT VOID
%nonassoc RPAREN
%nonassoc ELSE 
%token ID NUM
%token EQ NE LT LE GT GE LPAREN LBRACE RBRACE LCURLY RCURLY COMMA SEMI
%token ERROR 
%left PLUS MINUS 
%left TIMES OVER 
%right ASSIGN

%% /* Grammar for C- */

program             : declaration_list { savedTree = $1; } 
                    ;
declaration_list    : declaration_list declaration
                         { 
                              YYSTYPE t = $1; 
                              if (t != NULL)
                                   {
                                        while (t->sibling != NULL) t = t->sibling;
                                        t->sibling = $2; 
                                        $$ = $1; 
                                   } 
                              else $$ = $2;
                         }
                    | declaration { $$ = $1; }
                    ;
declaration         : var_declaration { $$ = $1; }
                    | fun_declaration { $$ = $1; }
                    ;
var_declaration     : type_specifier identifier SEMI
                         { 
							$$ = newTreeNode(VariableDecl);
							$$->lineno = $2->lineno;
							$$->type = $1->type;
							$$->name = $2->name;
							free($1); free($2);
                         }
                    | type_specifier identifier LBRACE number RBRACE SEMI
                         { 
							$$ = newTreeNode(VariableDecl);
							$$->lineno = $2->lineno;
							if ($1->type == Integer) $$->type = IntegerArray;
							else if ($1->type == Void) $$->type = VoidArray;
							else $$->type = None;
							$$->name = $2->name;
							$$->child[0] = $4;
							free($1); free($2);
                         }
                    ;
type_specifier      : INT  { $$ = newTreeNode(TypeSpecifier); $$->lineno = lineno; $$->type = Integer; }
                    | VOID { $$ = newTreeNode(TypeSpecifier); $$->lineno = lineno; $$->type = Void; }
                    ;
fun_declaration     : type_specifier identifier LPAREN params RPAREN compound_stmt
                         { 
						$$ = newTreeNode(FunctionDecl); 
                              $$->lineno = lineno; 
                              $$->type = $1->type;
                              $$->name = $2->name;
                              $$->child[0] = $4;
                              $$->child[1] = $6;
                         }
                    ;
params              : param_list { $$ = $1; }
                    | VOID { $$ = newTreeNode(Params); $$->lineno = lineno; $$->flag = TRUE; }
                    ;
param_list          : param_list COMMA param
                         {
                              YYSTYPE t = $1; 
                              if (t != NULL)
                              { 
                                   while (t->sibling != NULL) t = t->sibling;
                                   t->sibling = $3; 
                                   $$ = $1; 
                              } 
                              else $$ = $3;
                         }
                    | param { $$ = $1; }
                    ;
param               : type_specifier identifier
                         {
						$$ = newTreeNode(Params);
                              $$->type = $1->type;
                              $$->name = $2->name;
                              $$->lineno = $2->lineno;
                              free($1); free($2);
                         }
                    | type_specifier identifier LBRACE RBRACE
                         { 
                              $$ = newTreeNode(Params);
                              if($1->type == Integer) $$->type = IntegerArray;
                              else if($1->type == Void) $$->type = VoidArray;
                              else $$->type = None;
                              $$->name = $2->name;
                         }
                    ;
compound_stmt       : LCURLY local_declarations statement_list RCURLY
                         { 
						$$ = newTreeNode(CompoundStmt);
                              $$->child[0] = $2;
                              $$->child[1] = $3;
                         }
                    ;
local_declarations  : local_declarations var_declaration
                         {
						YYSTYPE t = $1; 
                              if (t != NULL)
                                   {
                                        while (t->sibling != NULL) t = t->sibling;
                                        t->sibling = $2; 
                                        $$ = $1; 
                                   } 
                              else $$ = $2;
                         }
                    | empty { $$ = NULL; }
                    ;
statement_list      : statement_list statement
                         { 
						YYSTYPE t = $1; 
                              if (t != NULL)
                                   {
                                        while (t->sibling != NULL) t = t->sibling;
                                        t->sibling = $2; 
                                        $$ = $1; 
                                   } 
                              else $$ = $2;
                         }
                    | empty { $$ = NULL; }
                    ;
statement			: selection_stmt { $$ = $1; }
                    | expression_stmt { $$ = $1; }
                    | compound_stmt { $$ = $1; }
                    | iteration_stmt { $$ = $1; }
                    | return_stmt { $$ = $1; }
                    ;
selection_stmt		: IF LPAREN expression RPAREN statement ELSE statement
                         {
                              $$ = newTreeNode(IfStmt);
                              $$->child[0] = $3;
                              $$->child[1] = $5;
                              $$->child[2] = $7;
                         }
                    | IF LPAREN expression RPAREN statement 
                         {
                              $$ = newTreeNode(IfStmt);
                              $$->child[0] = $3;
                              $$->child[1] = $5;
                         }
                    ;
expression_stmt     : expression SEMI { $$ = $1; }
                    | SEMI { $$ = NULL; }
                    ;
iteration_stmt      : WHILE LPAREN expression RPAREN statement
                         { 
							$$ = newTreeNode(WhileStmt);
                                   $$->child[0] = $3;
                                   $$->child[1] = $5;
                         }
                    ;
return_stmt         : RETURN SEMI 
                         { 
                              $$ = newTreeNode(ReturnStmt);
                              $$->child[0] = NULL;
                         }
                    | RETURN expression SEMI
                         { 
                              $$ = newTreeNode(ReturnStmt);
                              $$->child[0] = $2;
                         }
                    ;
expression          : var ASSIGN expression
                         { 
                              $$ = newTreeNode(AssignExpr);
                              $$->child[0] = $1;
                              $$->child[1] = $3;
                         }
                    | simple_expression { $$ = $1; }
                    ;
var                 : identifier
                         { 
						$$ = newTreeNode(VarAccessExpr);
                              $$->name = $1->name;
                         }
                    | identifier LBRACE expression RBRACE
                         {
						$$ = newTreeNode(VarAccessExpr);
                              $$->name = $1->name;
                              $$->child[0] = $3;
                         }
                    ;
simple_expression   : additive_expression relop additive_expression
                         { 
						$$ = newTreeNode(BinOpExpr);
                              $$->opcode = $2->opcode;
                              $$->child[0] = $1;
                              $$->child[1] = $3;
                         }
                    | additive_expression { $$ = $1; }
                    ;
relop               : LE { $$ = newTreeNode(Opcode); $$->lineno = lineno; $$->opcode = LE; }
                    | LT { $$ = newTreeNode(Opcode); $$->lineno = lineno; $$->opcode = LT; }
                    | GT { $$ = newTreeNode(Opcode); $$->lineno = lineno; $$->opcode = GT; }
                    | GE { $$ = newTreeNode(Opcode); $$->lineno = lineno; $$->opcode = GE; }
                    | EQ { $$ = newTreeNode(Opcode); $$->lineno = lineno; $$->opcode = EQ; }
                    | NE { $$ = newTreeNode(Opcode); $$->lineno = lineno; $$->opcode = NE; }
                    ;
additive_expression : additive_expression addop term
                    { 
                              $$ = newTreeNode(BinOpExpr);
                              $$->opcode = $2->opcode;
                              $$->child[0] = $1;
                              $$->child[1] = $3;
                    }
                    | term { $$ = $1; }
addop			: PLUS  { $$ = newTreeNode(Opcode); $$->lineno = lineno; $$->opcode = PLUS; }
                    | MINUS { $$ = newTreeNode(Opcode); $$->lineno = lineno; $$->opcode = MINUS; }
                    ;
term                : term mulop factor
                         {
                              $$ = newTreeNode(BinOpExpr);
                              $$->opcode = $2->opcode;
                              $$->child[0] = $1;
                              $$->child[1] = $3;
                         }
                    | factor { $$ = $1; }
                    ;
mulop               : TIMES { $$ = newTreeNode(Opcode); $$->lineno = lineno; $$->opcode = TIMES; }
                    | OVER  { $$ = newTreeNode(Opcode); $$->lineno = lineno; $$->opcode = OVER; }
                    ;
factor              : LPAREN expression RPAREN { $$ = $2; }
                    | var { $$ = $1; }
                    | call { $$ = $1; }
                    | number { $$ = $1; }
                    ;
call                : identifier LPAREN args RPAREN
                    { 
                         $$ = newTreeNode(CallExpr);
                         $$->name = $1->name;
                         $$->child[0] = $3;
                    }
                    ;
args                : arg_list { $$ = $1; }
                    | empty { $$ = NULL; }
                    ;
arg_list            : arg_list COMMA expression
                         {
                              YYSTYPE t = $1; 
                              if (t != NULL)
                              { 
                                   while (t->sibling != NULL) t = t->sibling;
                                   t->sibling = $3; 
                                   $$ = $1; 
                              } 
                              else $$ = $3;
                         }
                    | expression { $$ = $1; }
                    ;
identifier		: ID
                         {
                              $$ = newTreeNode(Indentifier);
                              $$->lineno = lineno;
                              $$->name = copyString(tokenString);
                         }
                    ;
number			: NUM
                         {
                              $$ = newTreeNode(ConstExpr);
                              $$->lineno = lineno;
                              $$->val = atoi(tokenString);
                         }
                    ;
empty               : { $$ = NULL;}
                    ;

%%

int yyerror(char * message)
{
	fprintf(listing,"Syntax error at line %d: %s\n",lineno,message);
	fprintf(listing,"Current token: ");
	printToken(yychar,tokenString);
	Error = TRUE;
	return 0;
}

/* yylex calls getToken to make Yacc/Bison output
 * compatible with ealier versions of the TINY scanner
 */
static int yylex(void)
{ return getToken(); }

TreeNode * parse(void)
{ 
	yyparse();
	return savedTree;
}
