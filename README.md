# Lily
an attempt at a cross-platform standard library for hblang.<br>
use `./build help` to see available build commands.

> [!IMPORTANT]
> all features, targets, etc, are provisional and subject to change

### To change build target
> [!CAUTION]
> this is currently unsupported the `./build` script.

set `target` in `src/lib/lib.hb`, choose one of:
- `target_c_native` `(TARGET=x86_64-unknown-linux-gnu) or similar`
- `target_hbvm_ableos` `(TARGET=unknown-virt-unknown)`

## Currently "working" features
- `std.vec.Vec`
- `std.alloc.{SimpleAllocator, RawAllocator}`
- `std.{Type, Kind, exit}`