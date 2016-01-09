
calltrace is a tool that traces the execution of a program written in C
language. It can help you understand how large, undocumented, multithreaded
 C programs work.

To use:

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


See sample-output.txt to get an idea of what calltrace produces.

FAQs and Tips
=============
Q: Why not automate the process using readelf or similar tools?
A: For programs that load libraries dynamically at runtime, some symbols cannot
   be resolved till the libraries are loaded.

Q: I instrumented some libraries which are used in many executables, and they
   generate too many log files. I want to debug only one program.
A: In calltrace.c change the variable "enable" to 0. Then in the program that
   you do want to instrument, make a call to calltrace_enable() from a function
   that gets called early, say main(). Alternatively, you can run the program
   from gdb, break in main, and invoke calltrace_enable() manually. If you
   do this, remember to detach the processs from gdb, or continue to run within
   gdb. Do not quit gdb without detaching as this will kill the process.

Q: I ran a test and immediately generated stack output. I don't see some of the
   functions.
A: The log file may not be getting flushed. Try calling calltrace_flush() from
   gdb or add this function somewhere in the code.

Q: My program runs so slow that I get timeout errors.
A: Try instrumenting only part of the build at a time - files that you are most
   interested in. This will give you partial stacks, but you will have some
   data.

Q: My target system does not have perl installed. Can I still use calltrace?
A: Yes! But you will need to find a Linux/BSD machine with perl and a way to
   move files back and forth between them. In step 4 of instructions above,
   copy the log file to the perl-machine to run genscript.pl. Copy the resulting
   gdbscript back to /tmp of target machine for step 5. Then copy gdbsysms to
   /tmp of perl machine for steps 6 and 7.

Q: I don't want to/can't use /tmp. Can I use another directory?
A: Right now, you will have to manually change the paths in the scripts and
   calltrace.c. The plan is to use a special environment variable (volunteers?)
