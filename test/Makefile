
runtest: main
	pid=`./main` && ls -l /tmp/calltrace-$$pid.log && \
	../genscript.pl /tmp/calltrace-$$pid.log > gdbscript && \
	echo quit >> gdbscript && \
	gdb -x gdbscript main  && \
	../parselog.pl /tmp/calltrace-$$pid.log > calltrace.txt && \
	rm  /tmp/calltrace-$$pid.log
	../stacks.pl calltrace.txt

main : main.c calltrace.o
	gcc -o main main.c calltrace.o -lpthread -finstrument-functions


calltrace.o : ../calltrace.c
	gcc -g -c ../calltrace.c

clean:
	rm -f gdbscript calltrace.txt *.o main shell

# Need to download sqlite for these
sq : 
	sqlite3 db < pop.sql
	shell db < insert.sql

shell : shell.c sqlite3.o calltrace.o
	gcc -g -o shell shell.c sqlite3.o calltrace.o -lpthread -ldl

sqlite3.o : sqlite3.c sqlite3.h
	gcc -g -c -finstrument-functions sqlite3.c
