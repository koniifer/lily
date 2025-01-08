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

### In progress
- `lily.rand.SimpleRandom`

### Partially broken due to compiler
- `lily.log.print`

### Completely broken due to compiler
- `lily.log.printf`
