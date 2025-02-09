#include "lily.h"

#if POSIX 
    #define _GNU_SOURCE 1
    #include <sys/mman.h>
    #include <sys/random.h>
    #include <stdio.h>
    #include <unistd.h>

    u32 LILY_POSIX_PROT_READWRITE() {
        return PROT_READ | PROT_WRITE;
    }
    u32 LILY_POSIX_MAP_SHAREDANONYMOUS() {
        return MAP_SHARED | MAP_ANONYMOUS;
    }
    u32 LILY_POSIX_MREMAP_MAYMOVE() {
        return MREMAP_MAYMOVE;
    }
#endif