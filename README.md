
calltrace is a tool that traces the execution of a program written in C
language. It can help you understand how large, undocumented, multithreaded
C programs work. calltrace uses gcc's -finstrument-functions switch to log
functions as they are entered and exited. Various scripts then generate
human-readable output from the log files. See sample-output.txt to get an idea
of what calltrace produces.

To use:

1. Add calltrace.c to the build. Customize as needed.

2. Add gcc flag -finstrument-functions to build. Also add -g and turn off
   optimizations (-O0).

3. Set environment variable CALLTRACEDIR. If this variable is not set, /tmp is
   used.

4. Run your program. This should produce $CALLTRACEDIR/calltrace-PID.log,
   where PID is the process-id of the process.
   Note, the instrumented program will experience significant slowdown.

5. On the target system, run:
    genscript.pl $CALLTRACEDIR/calltrace-PID.log > gdbscript

6.  Run gdb on target executable. In gdb prompt type:
    (gdb) source gdbscript
    This will create $CALLTRACEDIR/gdbsyms

7. Run:
    ./parselog.pl $CALLTRACEDIR/calltrace-PID.log > calltrace.txt
    Note, parselog.pl uses $CALLTRACEDIR/gdbsyms as input.
    The pathname is hardcoded.

8. calltrace.txt is human-readable. You can also run:
   ./stacks.pl calltrace.txt to obtain list of all stacks.



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
   /tmp of perl machine for steps 6 and 7. (If CALLTRACEDIR is set, use that
   directory instead of /tmp)

Q: Does it work with C++?

A: Yes, but you might hit this problem:
   https://gcc.gnu.org/bugzilla/show_bug.cgi?id=49718
   To workaround, compile calltrace.c using gcc (not g++), then link
   calltrace.o to C++ binaries using g++.

