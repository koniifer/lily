# Lily
an attempt at a cross-platform standard library for hblang.<br>
use `./build -h` to see available arguments. supports:
- changing target
- custom linker (for `c_native`)
- running the executable (for `c_native`)

> [!IMPORTANT]
> all features, targets, etc, are provisional and subject to change

### To change build target
create the file `src/lib/target/target.hb` with the contents `target := @use("c_native.hb")` (example)<br>
currently available targets:
- `c_native`
- `hbvm_ableos`

alternatively, use `./build -t c_native` (example)

## Currently "working" features
- `std.vec.Vec`
- `std.alloc.{SimpleAllocator, RawAllocator}`
- `std.{Type, Kind, exit}`