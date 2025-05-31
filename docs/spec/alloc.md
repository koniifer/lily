# allocators

1. all spec compliant allocators should implement:
> unless otherwise stated, functions can be optionally inline.<br>
> names of arguments are up to programmer discretion.<br>
> names and signature of functions must be identical to shown below.
> allocated blocks of memory must be aligned to @align_of(T)

```rust
Allocator := struct {
    new := fn(): Self
    /// prepare to be deallocated.
    deinit := fn(self: ^Self): void
    /// should return null on failure.
    /// should dealloc any intermediate allocations on failure.
    alloc := fn(self: ^Self, $T: type, count: uint): ?[]T
    /// same behaviour as alloc, except:
    /// must be zeroed.
    alloc_zeroed := fn(self: ^Self, $T: type, count: uint): ?[]T
    /// same behaviour as alloc, except:
    /// must move data to new allocation,
    /// must ensure the old allocation is freed at some point.
    realloc := fn(self: ^Self, $T: type, prev: []T, new_count: uint): ?[]T
    /// must dealloc or schedule the freeing of the given allocation
    dealloc := fn(self: ^Self, $T: type, prev: []T): void
}
```