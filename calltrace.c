/*
 * This file contains instrumentation code needed for calltrace to work.
 * You must include this file as part of your build.
 * See README.md for details.
 */
#include <pthread.h>
#include <stdint.h>
#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>

#define CALLTRACE_BUFFER_SIZE (1024 * 1024) /* 1 MB default */
struct calltrace_rec {
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

__attribute__ ((no_instrument_function))
void __cyg_profile_func_enter (void * this_fn, void * call_site)
{
    struct calltrace_rec myrec;
    assert(pthread_mutex_lock(&loglock) == 0);
    if (enable) {
        if (nrecords > NUM_RECORDS_MAX) { 
            /* TODO: truncate file and start from beginning */
            fclose(fptr);
            fptr = NULL;
            nrecords = 0;
        }
        if (fptr == NULL) {
            int pathbuflen = 0;
            char *buf = NULL, *path = NULL;
            const char *dir = getenv("CALLTRACEDIR");
            if (dir == NULL)
                dir = "/tmp";
            pathbuflen = strlen(dir) + 100;
            path = calloc(1, pathbuflen);
            assert(path != NULL);
            snprintf(path, pathbuflen, "%s/calltrace-%u.log", dir, getpid());
            fptr = fopen(path, "w");
            assert(fptr != NULL);
            free(path); path = NULL;
            buf = (char *)malloc(CALLTRACE_BUFFER_SIZE);
            assert(buf != NULL);
            setbuffer(fptr, buf, CALLTRACE_BUFFER_SIZE);
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

__attribute__ ((no_instrument_function)) void 
__cyg_profile_func_exit (void * this_fn, void * call_site)
{
    struct calltrace_rec myrec;
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

void calltrace_flush()
{

    assert(pthread_mutex_lock(&loglock) == 0);
    if (fptr)
        fflush(fptr);
    pthread_mutex_unlock(&loglock);
}

void calltrace_enable()
{
    assert(pthread_mutex_lock(&loglock) == 0);
    enable = 1;
    pthread_mutex_unlock(&loglock);
}

void calltrace_disable()
{
    assert(pthread_mutex_lock(&loglock) == 0);
    enable = 0;
    if (fptr)
        fclose(fptr);
    fptr = NULL;
    pthread_mutex_unlock(&loglock);
}
