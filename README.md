# Lily
an attempt at a cross-platform standard library for hblang.

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
>- hbvm
>- ableos
>- libc (links to system libc)

>[!NOTE]
`hbvm == ableos` (for now)

### Modifying build config
compiler flags are in: `./build` (at top of file)
> used for NON-CODE configuration

compile-time configuration is in: `./src/lily/lib.hb`
> used for things like toggling debug assertions, setting minimum log level, etc
## Features

### Working
- `lily.{Type, TypeOf, Kind, exit, panic, memcpy, memmove, memset}`
- `lily.log.{log, info, error, warn, debug, trace}`
- `lily.result.Result`
- `lily.alloc.{SimpleAllocator, RawAllocator}`
- `lily.collections.Vec`
- `lily.fmt.fmt_bool`
- `lily.string.{reverse, equals, clear, split_once, split, chars, count, left_trim, right_trim, trim}`
- `lily.Target.{realloc, malloc, calloc, free, getrandom}`

### In progress
- `lily.rand.SimpleRandom`

### Partially broken due to compiler
- `lily.log.print`
- `lily.fmt.format`

### Completely broken due to compiler
- `lily.log.printf`
- `lily.fmt.{format_with_str, fmt_container, fmt_optional, fmt_enum, fmt_int, fmt_float}`