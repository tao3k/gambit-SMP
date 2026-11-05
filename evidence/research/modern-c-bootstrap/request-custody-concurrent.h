/* Separate qualification setup.o; production hook is a constant no-op. */
#define ___INCLUDED_FROM_SETUP
#define ___VERSION 409008
#include "gambit.h"
extern void gambit_request_control(int,___processor_state,___WORD);
#define ___RESIZE_REQUEST_CONTROL(e,p,t) gambit_request_control(e,p,t)
