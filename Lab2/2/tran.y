%{
//头部，定义头文件、函数、宏    
#include<stdio.h>
#include<stdlib.h>
#include<string.h> 

#ifndef YYSTYPE
#define YYSTYPE char*
#endif

int yylex();    //词法分析器
extern int yyparse();  //语法分析器
FILE* yyin;

void yyerror(const char* s);  //用于处理语法错误
%}

//声明词法符号，UMINUS用于识别负数
%token ADD MINUS 
%token TIMES DIVIDE
%token LEFTPAR RIGHTPAR
%token NUMBER

//注意先后定义的优先级区别
%left ADD MINUS
%left TIMES DIVIDE
%left LEFTPAR RIGHTPAR

%right UMINUS


%%

//用于处理多行输入，每行都是一个表达式
lines   :       lines expr ';' { printf("%s\n", $2); }
        |       lines ';'
        |
        ;

//定义了表达式的结构，包括加、减、乘、除等操作
expr    :      expr ADD expr  { $$ = (char*)malloc(400); strcpy($$,$1); strcat($$,$3); strcat($$,"+ "); }
        |      expr MINUS expr  { $$ = (char*)malloc(400); strcpy($$,$1); strcat($$,$3); strcat($$,"- "); }
        |      expr TIMES expr  { $$ = (char*)malloc(400); strcpy($$,$1); strcat($$,$3); strcat($$,"* "); }
        |      expr DIVIDE expr  { $$ = (char*)malloc(400); strcpy($$,$1); strcat($$,$3);strcat($$,"/ "); }
        |      LEFTPAR expr RIGHTPAR   { $$ = $2; }
        |      MINUS  expr %prec UMINUS  {$$ = (char*)malloc(400); strcpy($$,"-"); strcat($$,$2); }
        |      NUMBER         { $$ = (char*)malloc(400); strcpy($$,$1); strcat($$," ");}
        ;
%%

// programs section

int yylex()
{
    char t;
    while(1){
        t=getchar();
        if(t==' '||t=='\t'||t=='\n'){
            //do noting
        }else if(isdigit(t)){
            int i=0;
            char *str=(char *)malloc(100 * sizeof(char));
            while(isdigit(t)){
                str[i++]=t;
                t=getchar();
            }
            str[i]='\0';
            yylval=str;
            ungetc(t,stdin);
            return NUMBER;
            //TODO:解析多位数字返回数字类型 
        }else if(t=='+'){
            return ADD;
        }else if(t=='-'){
            return MINUS;
        }else if(t=='*'){
            return TIMES;
        }else if(t=='/'){
            return DIVIDE;
        }else if(t=='('){
            return LEFTPAR;
        }else if(t==')'){
            return RIGHTPAR;
        }//TODO:识别其他符号
        else{
            return t;
        }        
    }

    return getchar();
}

int main(void)
{
    yyin=stdin;
    do{
        yyparse();
    }while(!feof(yyin));
    return 0;
}
void yyerror(const char* s){
    fprintf(stderr,"Parse error: %s\n",s);
    exit(1);
}