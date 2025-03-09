# iterators

> [!note]
> spec tbd

```rust
iter.{Iterator, Next} := @use("lily").iter

Iterable := struct {
    next := fn(self: ^Self): Next(T)
}