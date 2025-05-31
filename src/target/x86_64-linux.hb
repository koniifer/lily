// temporary
$page_len := fn(): uint return 4096
$pages := fn(len: uint): uint return (len + page_len() - 1) / page_len()

$sys_mmap := 9
$prot_read := 0x1
$prot_write := 0x2
$prot_exec := 0x4
$prot_none := 0x0
$map_shared := 0x1
$map_private := 0x2
$map_anonymous := 0x20
$alloc := fn(len: uint): ?^u8 @error("todo")
$alloc_zeroed := fn(len: uint): ?^u8 @error("todo")

$realloc := fn(ptr_old: ^u8, len_old: uint, len_new: uint): ?^u8 @error("todo")

$dealloc := fn(ptr: ^u8, len: uint): void @error("todo")

$memcopy := fn(dest: ^u8, src: ^u8, len: uint): void @error("todo")
$memmove := fn(dest: ^u8, src: ^u8, len: uint): void @error("todo")

$memset := fn(dest: ^u8, src: u8, len: uint): void @error("todo")
$memfill := fn(dest: ^u8, src: ^u8, count: uint, len: uint): void @error("todo")

$SYS_exit := 60
$exit := fn(code: uint): never return @syscall(SYS_exit, code)
$SYS_exit_group := 231
$exit_group := fn(code: uint): never return @syscall(SYS_exit_group, code)

$rand_fill := fn(dest: ^u8, len: uint): void @error("todo")

$proc_fork := fn(): uint @error("todo")
$proc_spawn := fn(executable: []u8): uint @error("todo")

$dt_get := fn($T: type, query: []u8): T @error("todo")

$buf_create_named := fn(name: []u8): uint @error("todo")
$buf_create := fn(): uint @error("todo")
$buf_destroy := fn(id: uint): void @error("todo")
$buf_search := fn(name: []u8): uint @error("todo")
$buf_await := fn(id: uint): void @error("todo")
$buf_read := fn(id: uint, mmap: []u8): void @error("todo")
$buf_write := fn(id: uint, mmap: []u8): void @error("todo")
