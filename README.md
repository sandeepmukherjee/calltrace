
calltrace is a tool that traces the execution of a program written in C
language.
calltrace can work with large, multi-threaded programs. To use:

1. Add calltrace.c to the build. Customize as needed.

2. Add gcc flag -finstrument-functions to build. Also add -g and turn off
   optimizations (-O0).

3. Load build. Run tests. This should produce /tmp/calltrace-PID.log, where 
   PID is the process-id of the process.
   Note, the instrumented program will experience significant slowdown.

4. On the target system, run:
    genscript.pl /tmp/calltrace-PID.log > /tmp/gdbscript

5.  Run gdb on target executable. In gdb prompt type:
    (gdb) source gdbscript.
    This will create /tmp/gdbsyms

6. Run:
    ./parselog.pl /tmp/calltrace-PID.log > calltrace.txt
    Note, parselog.pl uses /tmp/gdbsyms as input. The pathname is hardcoded.

7. calltrace.txt is human-readable. You can also run:
   ./stacks.pl calltrace.txt to obtain list of all stacks.

