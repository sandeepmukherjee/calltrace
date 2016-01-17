
#include <pthread.h>
#include <stdio.h>

void func3()
{
    fprintf(stderr, "In %s\n", __FUNCTION__);
}

void func2()
{
    fprintf(stderr, "In %s\n", __FUNCTION__);
    func3();
}
static void *func1(void *arg)
{
    sleep(rand() % 7);
    func2();
    fprintf(stderr, "Thread %x done\n", pthread_self());
}

int main()
{
    pthread_t tids[5];
    int i;
    printf("%d\n", getpid());

    for (i=0; i<5; i++)
        pthread_create(&tids[i], NULL, func1, NULL);

    for (i=0; i<5; i++)
        pthread_join(tids[i], NULL);

    calltrace_disable();
    return 0;
}
