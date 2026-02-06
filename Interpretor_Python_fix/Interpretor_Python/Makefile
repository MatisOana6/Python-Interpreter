parser: lex.yy.c y.tab.c
	gcc -g interpreter.c lex.yy.c y.tab.c -o parser -lfl
	
lex.yy.c: interpreter.l
	lex $<

y.tab.c y.tab.h: interpreter.y
	yacc -d -v -t $<
