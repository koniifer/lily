# Lily
an attempt at a cross-platform standard library for hblang.

> [!CAUTION]
> # hblang is currently very broken
> like super broken. please don't use lily right now.<br>
> hblang is getting rewritten in zig, so soon we will have this all working again.

> [!IMPORTANT]
> all features, targets, modules, etc, are provisional and may be subject to change or deletion

use `./build -h` to see available arguments.
### supports:
- changing target
- custom linker (for native targets)
- running the executable (for native targets)
- setting output path
- dumping assembly representation
- only recompiling if either source or environment change

### To change build target
use the `-t` flag supplied in `./build`

use a target triple (i.e. `x86_64-unknown-linux-gnu`), or pick from one of these aliases:
>[!NOTE]
`hbvm == ableos` (for now)

>- hbvm
>- ableos
>- libc (links to system libc)


### Modifying build config
compiler flags are in: `./build` (at top of file)
> used for NON-CODE configuration

compile-time configuration is in: `./src/lily/lib.hb`
> used for things like toggling debug assertions, setting minimum log level, etc

# Features

features include:
- heap allocator
- system rand
- memory operations
- math operations
- string operations, including split iteration
- hasher
- hashmap
- vec (dynamic array)
- printing &  logging
- result type
- typesystem wrapper
- string formatting & interpolation