%{
//1. **定义部分**（Definitions Section）: 定义头文件、函数、宏   
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<ctype.h>

int yylex();    //词法分析器
extern int yyparse();
FILE* yyin;
void yyerror(const char* s);  //用于处理语法错误


//符号表结构
struct symbol_table{
    char * id;
    double num;
};
struct symbol_table symbol_table[100];  //符号表结构体数组
struct symbol_table* search(char *s); //用于符号表插入插入和查询功能

%}

//定义联合体,指定yacc语义值的类型
%union{
    double val;
    struct symbol_table *s; //符号表指针
};

//声明词法符号，UMINUS用于识别负数
%token ADD MINUS 
%token TIMES DIVIDE
%token LEFTPAR RIGHTPAR
%token <val> NUMBER //为number携带属性值
%token equal
%token <s> Identifier //为标识符携带符号表

//定义算术运算符的优先级，越靠下优先级越高
%right equal    //等号的优先级最低

%left ADD MINUS
%left TIMES DIVIDE
%left LEFTPAR RIGHTPAR

%right UMINUS

//为表达式携带属性值
%type <val> expr

//**规则部分**（Rules Section）: 用户定义文法规则
%%

//用于处理多行输入，每行都是一个表达式
lines   :       lines expr ';' { printf("%f\n", $2); }
        |       lines ';'
        |
        ;

//定义了表达式的结构，包括加、减、乘、除等操作
expr    :       expr ADD expr   { $$=$1+$3; }
        |       expr MINUS expr   { $$=$1-$3; }
        |       expr TIMES expr   { $$=$1*$3; }
        |       expr DIVIDE expr   { $$=$1/$3; }
        |       LEFTPAR expr RIGHTPAR      { $$=$2;}
        |       MINUS expr %prec UMINUS   {$$=-$2;}
        |       NUMBER    {$$=$1;}
        |       Identifier equal expr { $1->num =$3; $$=$3; }
        |       Identifier   { $$=$1->num;}
        ;

%%
//**用户子程序部分**（User Subroutines Section）
// programs section

int yylex()
{
    int t;
    while(1){
        t=getchar();
        if(t==' '||t=='\t'||t=='\n'){  //忽略空格、换行、制表符
            //do noting
        }else if(isdigit(t)){  //识别多位十进制数字
            yylval.val=0;  //yylval是lex和yacc沟通的变量，赋值给识别出的单词
            while(isdigit(t)){
                yylval.val=yylval.val*10+t-'0';
                t=getchar();
            }
            ungetc(t,stdin);  //向输入输出流回退非数字字符
            return NUMBER;    //将单词类别返回给词法分析程序
            //TODO:解析多位数字返回数字类型 
        }else if(isalpha(t)||t=='_'){  //是字母或下划线，识别为标识符
            char *str =(char*)malloc(400);
            int i=0;
            while(isalpha(t)||t=='_'||isdigit(t)){
                str[i++]=t;
                t=getchar();
            }
            str[i]='\0';
            yylval.s=search(str);  //将标识符在符号表中查询和插入
            ungetc(t, stdin);
            return Identifier;
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
        }else if(t=='='){
            return equal;
        }
        //TODO:识别其他符号
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

struct symbol_table * search(char *s){
    struct symbol_table* sp;  //循环遍历
    for(sp=symbol_table;sp<&symbol_table[100];sp++){
        if(sp->id && strcmp(sp->id,s) == 0) //查询成功
            return sp;
        if(!sp->id){ //查询失败，插入
            sp->id=strdup(s); //字符串拷贝
            return sp;
        }
     }
}
void yyerror(const char* s){
    fprintf(stderr,"Parse error: %s\n",s);
    exit(1);
}