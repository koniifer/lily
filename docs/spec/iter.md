# iterators
## spec to-be-defined

## proposed spec:

```rust
.{IterNext, Iterator} := @use("lily").iter

Iterable := struct {
    // ! required
    // IterNext == struct { finished: bool, val: T }
    next := fn(self: ^Self): IterNext(T)
    into_iter := fn(self: Self): Iterator(Self)
    // ! proposed
    // addition of these two would allow for cheap implementation of `skip`, and `nth` in lily.iter.Iterator
    peek := fn(self: ^Self): IterNext(T)
    advance := fn(self: ^Self, n: uint): IterNext(T)
    // ! proposed (waiting on compiler)
    iter := fn(self: ^Self): Iterator(^Self)
}