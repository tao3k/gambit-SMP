/* Independent qualification of the Darwin injection adapter; no Gambit code. */
#include <pthread.h>
#include <dlfcn.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
static void *entry(void *p) {return p;}
int main(void) {
  void (*arm)(int,int,int)=dlsym(RTLD_DEFAULT,"resize_test_arm");
  int (*count)(int)=dlsym(RTLD_DEFAULT,"resize_test_count");
  if (!arm || !count) return 2;
  pthread_t first,second;arm(2,1,0);
  int a=pthread_create(&first,0,entry,0),b=pthread_create(&second,0,entry,0);
  int c=a==0?pthread_join(first,0):-1;
  int creates=count(0),joins=count(1);
  printf("create_first=%d create_second=%d join_first=%d creates=%d joins=%d\n",a,b,c,creates,joins);
  arm(0,0,0);if(a==0&&c!=0)pthread_join(first,0);if(b==0)pthread_join(second,0);
  return a==0&&b==EAGAIN&&c==ESRCH&&creates==2&&joins==1?0:1;
}
