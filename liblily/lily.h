#ifndef __LILY_H_DEFINED
#define __LILY_H_DEFINED

#if defined(__unix__) || (defined(__APPLE__) && defined(__MACH__)) || defined(_POSIX_VERSION)
    #define POSIX 1
#else
    #define POSIX 0
#endif

typedef unsigned long long int lily_uint;
typedef unsigned int u32;
typedef unsigned short int u16;
typedef unsigned char u8;
typedef u8 bool;

bool is_posix() {
    return POSIX;
}

#if POSIX
    // we export these constants as functions
    // because we cant import c constants in hblang yet
    u32 LILY_POSIX_PROT_READWRITE();
    u32 LILY_POSIX_MAP_SHAREDANONYMOUS();
    u32 LILY_POSIX_MREMAP_MAYMOVE();
#endif // POSIX

#endif // __LILY_H_DEFINED