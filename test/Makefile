
runtest: main
	mkdir  -p tmp
	export CALLTRACEDIR=tmp; \
	pid=`./main` && ls -l tmp/calltrace-$$pid.log && \
	../genscript.pl tmp/calltrace-$$pid.log > gdbscript && \
	echo quit >> gdbscript && \
	gdb -x gdbscript main  && \
	../parselog.pl tmp/calltrace-$$pid.log > tmp/calltrace.txt && \
	../stacks.pl tmp/calltrace.txt

main : main.c calltrace.o
	gcc -o main main.c calltrace.o -lpthread -finstrument-functions


calltrace.o : ../calltrace.c
	gcc -g -c ../calltrace.c

clean:
	rm -rf tmp gdbscript calltrace.txt *.o main shell

# Download sqlite-amalgamation package from sqlite.org,
# and move all files to this directory.
sq : shell sqlite3.o
	rm -rf tmp/
	mkdir tmp
	sqlite3 tmp/db < pop.sql
	export CALLTRACEDIR=tmp; \
	./shell tmp/db < insert.sql 
	ls -l tmp/calltrace-*.log
	../genscript.pl tmp/calltrace-*.log > gdbscript
	echo quit >> gdbscript
	gdb -x gdbscript shell
	../parselog.pl tmp/calltrace-*.log > tmp/calltrace.txt
	../stacks.pl tmp/calltrace.txt > tmp/stacks.txt
	@echo "Results in tmp/calltrace.txt and tmp/stacks.txt"
	

shell : shell.c sqlite3.o calltrace.o
	gcc -g -o shell shell.c sqlite3.o calltrace.o -lpthread -ldl

sqlite3.o : sqlite3.c sqlite3.h
	gcc -g -c -finstrument-functions sqlite3.c
