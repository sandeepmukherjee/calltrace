// THIS IS WORK IN PROGRESS
// TODO: Rename to something better.
//
#include <pthread.h>
#include <stdint.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>

#define FTRACE_BUFFER_SIZE (1024 * 1024) /* 1 MB default */
struct fnrec {
    uint64_t type;
    uint64_t this_fn;
    uint64_t call_site;
    uint64_t timestamp;
    uint64_t pid;
    uint64_t tid;
};

static int enable = 1;
static FILE *fptr = NULL;
static uint64_t nrecords = 0;
static pthread_mutex_t loglock = PTHREAD_MUTEX_INITIALIZER;
#define NUM_RECORDS_MAX 200000

__attribute__ ((no_instrument_function)) void __cyg_profile_func_enter (void * this_fn, void * call_site)
{
    struct fnrec myrec;
    assert(pthread_mutex_lock(&loglock) == 0);
    if (enable) {
        if (nrecords > NUM_RECORDS_MAX) {
            fclose(fptr);
            fptr = NULL;
            nrecords = 0;
        }
        if (fptr == NULL) {
            char path[2000];
            char *buf = NULL;
            sprintf(path, "/tmp/ftrace-%u.log", getpid());
            fptr = fopen(path, "w");
            assert(fptr != NULL);
            buf = (char *)malloc(FTRACE_BUFFER_SIZE);
            assert(buf != NULL);
            setbuffer(fptr, buf, FTRACE_BUFFER_SIZE);
        }
        myrec.type = 0x1;
        myrec.this_fn = (uint64_t)this_fn;
        myrec.call_site = (uint64_t)call_site;
        myrec.timestamp = (uint64_t) time(NULL);
        myrec.tid = (uint64_t)pthread_self();
        myrec.pid = (uint64_t)getpid();
        fwrite((void *)&myrec, sizeof(myrec), 1, fptr);
        nrecords++;
    }
    pthread_mutex_unlock(&loglock);
}

__attribute__ ((no_instrument_function)) void __cyg_profile_func_exit (void * this_fn, void * call_site)
{
    struct fnrec myrec;
    assert(pthread_mutex_lock(&loglock) == 0);
    if (enable && fptr != NULL) {
        myrec.type = 0x2;
        myrec.this_fn = (uint64_t)this_fn;
        myrec.call_site = (uint64_t)call_site;
        myrec.timestamp = (uint64_t) time(NULL);
        myrec.tid = (uint64_t)pthread_self();
        myrec.pid = (uint64_t)getpid();
        fwrite((void *)&myrec, sizeof(myrec), 1, fptr);
        nrecords++;
    }
    pthread_mutex_unlock(&loglock);
}

void ftrace_flush()
{

    assert(pthread_mutex_lock(&loglock) == 0);
    if (fptr)
        fflush(fptr);
    pthread_mutex_unlock(&loglock);
}

void ftrace_enable()
{
    assert(pthread_mutex_lock(&loglock) == 0);
    enable = 1;
    pthread_mutex_unlock(&loglock);
}
void ftrace_disable()
{
    assert(pthread_mutex_lock(&loglock) == 0);
    enable = 0;
    pthread_mutex_unlock(&loglock);
}
