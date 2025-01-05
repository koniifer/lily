# Lily
an attempt at a cross-platform standard library for hblang.<br>
use `./build -h` to see available arguments. supports:
- changing target
- custom linker (for `c_native`)
- running the executable (for `c_native`)
- setting output path
- only recompiling if either source or environment change

> [!IMPORTANT]
> all features, targets, etc, are provisional and subject to change

### To change build target
manually:
> create the file `src/lib/target/target.hb` with the contents `target := @use("c_native.hb")` (example)

automatically:
> use the `-t` flag supplied in `./build`

currently available targets:
- `c_native`
- `hbvm_ableos`

alternatively, use `./build -t c_native` (example)

### Currently "working" features
- `lily.{Type, TypeOf, Kind, exit, panic, memcpy, memmove, memset}`
- `lily.log.{log, info, error, warn, debug, trace}`
- `lily.result.Result`

### Currently "in progress" features
- `lily.rand.SimpleRandom`
- `lily.log.{print, printf}`

### Currently "broken due to compiler" features
- `lily.collections.SparseVec`
- `lily.alloc.{SimpleAllocator, RawAllocator}`
