lily.{config} := @use("../lib.hb")
// temporary
$page_len := fn(): uint return 4096
$pages := fn(len: uint): uint return (len + page_len() - 1) / page_len()

$sys_mmap := 0x9
$prot_read := 0x1
$prot_write := 0x2
$map_private := 0x2
$map_anonymous := 0x20
$map_failed: ^u8 = @bit_cast(~0)
$alloc := fn(len: uint): ?^u8 {
	ptr: ^u8 = @syscall(sys_mmap, 0, len, prot_read | prot_write, map_private | map_anonymous, ~0, 0)
	$if config.optimise < .ReleaseFast {
		if ptr == map_failed return null
	}
	return ptr
}
// mmap, mremap give zeroed pages (when map_anonymous)
$alloc_zeroed := alloc

$sys_memremap := 0x19
$mremap_maymove := 0x1
$realloc := fn(ptr_old: ^u8, len_old: uint, len_new: uint): ?^u8 {
	ptr: ^u8 = @syscall(sys_memremap, ptr_old, len_old, len_new, mremap_maymove)
	$if config.optimise < .ReleaseFast {
		if ptr == map_failed return null
	}
	return ptr
}

$sys_munmap := 0xB
$dealloc := fn(ptr: ^u8, len: uint): void return @syscall(sys_munmap, ptr, len)

$memcopy := fn(dest: ^u8, src: ^u8, len: uint): void @error("todo")
$memmove := fn(dest: ^u8, src: ^u8, len: uint): void @error("todo")

$memset := fn(dest: ^u8, src: u8, len: uint): void @error("todo")
$memfill := fn(dest: ^u8, src: ^u8, count: uint, len: uint): void @error("todo")

$sys_exit := 0x3C
$exit := fn(code: uint): never return @syscall(sys_exit, code)
$sys_exit_group := 0xE7
$exit_group := fn(code: uint): never return @syscall(sys_exit_group, code)

$sys_getrandom := 0x13E
$rand_fill := fn(dest: ^u8, len: uint): void return @syscall(sys_getrandom, dest, len)

$sys_clone := 0x38
$sys_execve := 0x3B
$sig_chld := 0x11
$proc_fork := fn(): ?uint {
	pid: i32 = @syscall(sys_clone, sig_chld)
	if pid < 0 return null
	return @as(uint, @int_cast(pid))
}
// no clue if this works. expects null-terminated executable.
$proc_spawn := fn(executable: []u8): ?uint {
	pid := proc_fork()
	if pid == null return null
	if pid.? == 0 {
		argv := (?^u8).[executable.ptr, null]
		envp := (?^u8).[null]
		x: void = @syscall(sys_execve, executable.ptr, &argv[0], &envp[0])
		// if execve returns, it failed
		lily.panic(1)
	}
	return pid
}

$dt_get := fn($T: type, query: []u8): T @error("todo")

$buf_create_named := fn(name: []u8): uint @error("todo")
$buf_create := fn(): uint @error("todo")
$buf_destroy := fn(id: uint): void @error("todo")
$buf_search := fn(name: []u8): uint @error("todo")
$buf_await := fn(id: uint): void @error("todo")
$buf_read := fn(id: uint, mmap: []u8): void @error("todo")
$buf_write := fn(id: uint, mmap: []u8): void @error("todo")
