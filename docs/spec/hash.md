# hashers
1. hashers must not allocate on the heap.
2. all spec compliant hashers should implement:
> unless otherwise stated, functions can be optionally inline.<br>
> names of arguments are up to programmer discretion.<br>
> names and signature of functions must be identical to shown below.
```rust
Hasher := struct {
    new := fn(seed: SeedType): Self
    /// prepare to be deallocated
    deinit := fn(self: ^Self): void
    /// should always use a constant or randomised seed
    /// randomised seeds should (for now) use lily.Target.getrandom()
    /// never use values from the environment
    default := fn(): Self
    /// pointers: treat as uint
    /// slices: read bytes and hash
    /// other: hash bytes directly
    write := fn(self: ^Self, any: @Any()): void
    /// should not reset the state of the hasher
    finish := fn(self: ^Self): uint
    reset := fn(self: ^Self): void
}
```