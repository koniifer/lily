# random number generators
1. rngs must not allocate on the heap.
2. the seed of the rng must not change (unless required by the algorithm)
3. all spec compliant rngs should implement:
> unless otherwise stated, functions can be optionally inline.<br>
> names of arguments are up to programmer discretion.<br>
> names and signature of functions must be identical to shown below.
```rust
Random := struct {
    new := fn(seed: uint): Self
    /// prepare to be deallocated
    deinit := fn(self: ^Self): void
    /// should always use a constant or randomised seed
    /// randomised seeds should always use lily.Target.getrandom()
    /// never use values from the environment
    default := fn(): Self
    /// array|slice: compile error
    /// pointer: treat as uint
    /// bool: randomise the least significant bit
    /// other: randomise
    any := fn(self: ^Self, $T: type): T
    /// clamp between min and max (inclusive)
    range := fn(self: ^Self, min: @Any(), max: @TypeOf(min)): @TypeOf(min)
    /// ^array: fill to @lenof(@ChildOf(@TypeOf(buf))) with random bytes
    /// slice: fill to buf.len with random bytes
    /// other: compile error
    fill := fn(self: ^Self, buf: @Any()): void
    /// same as fill, except fill each index with a random value rather than filling the whole buffer with random bytes
    fill_values := fn(self, ^Self, buf: @Any()): void
}
```