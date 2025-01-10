# documenting the used features of the AbleOS spec

> [!Important]
> this does not apply to all hbvm targets. it applies to ableos specifically. other hbvm targets will have different ecalls, or even no ecalls. for an example of another project using hbvm, see [depell](https://depell.mlokis.tech/) (dependency hell), a website created by mlokis, the main programmer of hblang, that runs hblang programs, in hbvm, in wasm.

## how do ecalls work?
ecalls are comprised of a series of values, with each consecutive one representing the value of a vm register from 1-255 (the 0 register is reserved). `ecall a b c` fills the first three registers with the values `a`, `b`, and `c` respectively. the ecall handler reads these values and performs a kernel operation based on them.

## how is this formatted?
all registers are followed by parethesis with their purpose. the `message` section is actually a pointer to a single location in memory, taking a single register. the following register is always the size of this message. this is omitted for brevity.<br>
`ecall register(purpose), ..., register(purpose), message_bytes:type, ..., message_bytes:type`

## more info?
read [here](https://git.ablecorp.us/AbleOS/ableos/src/branch/master/kernel/src/holeybytes/ecah.rs) for the full set of ecalls and buffer ids.

### `lily.log`:
log: `ecall 3(buf), 1(log), loglevel:u8, string:*const u8, strlen:u64`<br>
> formats and then copies `strlen` of `string` into the serial output

### `lily.Target.AbleOS`:
malloc: `ecall 3(buf), 2(mem), 0(alloc), page_count:u64, zeroed:bool=false`
> returns `Option<*mut u8>` to an available contiguous chunk of memory, sized in `4096` byte (align `8`) pages. it is undefined behaviour to use size zero.

calloc: `ecall 3(buf), 2(mem), 0(alloc), page_count:u64, zeroed:bool=true`<br>
> same as malloc, except filled with zeroes.

realloc: `ecall 3(buf), 2(mem), 7(realloc), page_count:u64, page_count_new:u64, ptr:*const u8, ptr_new:*const u8`<br>
> resizes an existing contiguous chunk of memory allocated via `malloc`, `calloc`, or `realloc`. contents remain the same. it is undefined behaviour to use size zero or a `null` pointer. returns a new `Option<*mut u8>` after resizing.

free: `ecall 3(buf), 2(mem), 1(free), page_count:u64, ptr:*const u8`<br>
> releases an existing contiguous chunk of memory allocated via `malloc`, `calloc`, or `realloc`. it is undefined behaviour to use size zero or a `null` pointer.

memcpy: `ecall 3(buf), 2(mem), 4(memcopy), size:u64, src:*const u8, dest:*const u8`<br>
> copies `size` of `src` into `dest`. `src` and `dest` must not be overlapping. it is undefined behaviour to use size zero or a `null` pointer.

memset: `ecall 3(buf), 2(mem), 5(memset), count:u64, size:u64, src:*const u8, dest:*mut u8`<br>
> consecutively copies `size` of `src` into `dest` a total of `count` times. `src` and `dest` must not be overlapping. it is undefined behaviour to use size zero or a `null` pointer.

memmove: `ecall 3(buf), 2(mem), 6(memmove), size:u64, src:*const u8, dest:*mut u8`<br>
> copies `size` of `src` into a buffer, then from the buffer into `dest`. `src` and `dest` can be overlapping. it is undefined behaviour to use size zero or a `null` pointer.

getrandom: `ecall 3(buf) 4(rand) dest:*mut u8, size:u64`
> fills `dest` with `size` bytes of random cpu entropy.

## ecall numbers (u8)
3. send a message to a buffer

## buffer ids (uint)
1. logging service
2. memory service
4. random service
