1. Add customlog.c to the build. Customize as needed.

2. Add gcc flag -finstrument-functions to build.

3. Load build. Run tests. This should produce /tmp/ftrace-*.log

4. On target system, run:
    readrec.pl /tmp/ftrace-NNN.log > /tmp/gdbscript

5.  Run gdb on target executable. In gdb prompt type:
    (gdb) source gdbscript.
    This will create /tmp/gdbsyms

6. Run:
    ./parse_gdbout.pl /tmp/ftrace-NNNN.log > stack.txt
    Note, parse_gdbout.pl uses /tmp/gdbsyms as input. The pathname is hardcoded.

7. stack.txt is human-readable. You can also run:
   ./stacks.pl /tmp/stack.txt to obtain list of all stacks.
