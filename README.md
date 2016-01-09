
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

Here's a small portion of trace logs showing sqlite3 in action:
18:34:22: 7f7ff7a10700 -->                        sqlite3Strlen30
18:34:22: 7f7ff7a10700 <--                        sqlite3Strlen30
18:34:22: 7f7ff7a10700 <--                      findCreateFileMode
18:34:22: 7f7ff7a10700 -->                      robust_open
18:34:22: 7f7ff7a10700 -->                        posixOpen
18:34:22: 7f7ff7a10700 <--                        posixOpen
18:34:22: 7f7ff7a10700 <--                      robust_open
18:34:22: 7f7ff7a10700 -->                      robustFchown
18:34:22: 7f7ff7a10700 <--                      robustFchown
18:34:22: 7f7ff7a10700 -->                      fillInUnixFile
18:34:22: 7f7ff7a10700 -->                        sqlite3_uri_boolean
18:34:22: 7f7ff7a10700 -->                          sqlite3_uri_parameter
18:34:22: 7f7ff7a10700 <--                          sqlite3_uri_parameter
18:34:22: 7f7ff7a10700 <--                        sqlite3_uri_boolean
18:34:22: 7f7ff7a10700 -->                        storeLastErrno
18:34:22: 7f7ff7a10700 <--                        storeLastErrno
18:34:22: 7f7ff7a10700 -->                        verifyDbFile
18:34:22: 7f7ff7a10700 -->                          fileHasMoved
18:34:22: 7f7ff7a10700 <--                          fileHasMoved
18:34:22: 7f7ff7a10700 <--                        verifyDbFile
18:34:22: 7f7ff7a10700 <--                      fillInUnixFile
18:34:22: 7f7ff7a10700 <--                    unixOpen
18:34:22: 7f7ff7a10700 <--                  sqlite3OsOpen
18:34:22: 7f7ff7a10700 -->                  writeJournalHdr
18:34:22: 7f7ff7a10700 -->                    journalHdrOffset
18:34:22: 7f7ff7a10700 <--                    journalHdrOffset

The first field is the timestamp.
The second field the thread ID in hex. In this example, there's only one thread
(main thread), but calltrace works with multithreaded programs as well.
The next field shows whether the function is being entered (-->) or exited (<--)
.
The number of spaces show the level of call stack,
The final field is the function name.

The above logs show robust_open() calling posixOpen().

The script stacks.pl can produce sequence of stacks like:

18:34:22 7f7ff7a10700 sqlite3_step->sqlite3Step->sqlite3VdbeExec->sqlite3BtreeInsert->insertCell->sqlite3PagerWrite->pager_write->pager_open_journal->sqlite3OsOpen->unixOpen->findCreateFileMode->sqlite3Strlen30
18:34:22 7f7ff7a10700 sqlite3_step->sqlite3Step->sqlite3VdbeExec->sqlite3BtreeInsert->insertCell->sqlite3PagerWrite->pager_write->pager_open_journal->sqlite3OsOpen->unixOpen->robust_open->posixOpen
18:34:22 7f7ff7a10700 sqlite3_step->sqlite3Step->sqlite3VdbeExec->sqlite3BtreeInsert->insertCell->sqlite3PagerWrite->pager_write->pager_open_journal->sqlite3OsOpen->unixOpen->robustFchown
18:34:22 7f7ff7a10700 sqlite3_step->sqlite3Step->sqlite3VdbeExec->sqlite3BtreeInsert->insertCell->sqlite3PagerWrite->pager_write->pager_open_journal->sqlite3OsOpen->unixOpen->fillInUnixFile->sqlite3_uri_boolean->sqlite3_uri_parameter
18:34:22 7f7ff7a10700 sqlite3_step->sqlite3Step->sqlite3VdbeExec->sqlite3BtreeInsert->insertCell->sqlite3PagerWrite->pager_write->pager_open_journal->sqlite3OsOpen->unixOpen->fillInUnixFile->storeLastErrno
18:34:22 7f7ff7a10700 sqlite3_step->sqlite3Step->sqlite3VdbeExec->sqlite3BtreeInsert->insertCell->sqlite3PagerWrite->pager_write->pager_open_journal->sqlite3OsOpen->unixOpen->fillInUnixFile->verifyDbFile->fileHasMoved
18:34:22 7f7ff7a10700 sqlite3_step->sqlite3Step->sqlite3VdbeExec->sqlite3BtreeInsert->insertCell->sqlite3PagerWrite->pager_write->pager_open_journal->writeJournalHdr->journalHdrOffset
