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

$memcopy := fn(dest: ^u8, src: ^u8, len: uint): void {
	end := src + len
	loop if src + 8 >= end break else {
		@as(^uint, @bit_cast(dest)).* = @as(^uint, @bit_cast(src)).*
		dest += 8
		src += 8
	}
	loop if src >= end break else {
		dest.* = src.*
		src += 1
		dest += 1
	}
}
$memmove := fn(dest: ^u8, src: ^u8, len: uint): void {
	if lily.mem.overlaps(dest[0..len], src[0..len]) {
		buf: ^u8 = @syscall(sys_mmap, 0, len, prot_read | prot_write, map_private | map_anonymous, ~0, 0)
		$if config.optimise < .ReleaseFast {
			// todo: error msg
			if buf == map_failed lily.panic(1)
		}
		memcopy(buf, src, len)
		memcopy(dest, buf, len)
		dealloc(buf, len)
	} else {
		memcopy(dest, src, len)
	}
}

$memset := fn(dest: ^u8, src: u8, len: uint): void {
	if len <= 8 {
		end := dest + len
		loop if dest >= end break else {
			dest.* = src
			dest += 1
		}
		return
	}

	dest.* = src
	copied := 1
	loop if copied >= len break else {
		copy_size := 0
		if copied > len - copied {
			copy_size = len - copied
		} else copy_size = copied
		memcopy(dest + copied, dest, copy_size)
		copied += copy_size
	}
}
$memfill := fn(dest: ^u8, src: ^u8, count: uint, len: uint): void {
	if count <= 8 {
		end := dest + count * len
		loop if dest >= end break else {
			memcopy(dest, src, len)
			dest += len
		}
		return
	}

	total_size := count * len
	memcopy(dest, src, len)
	copied := len

	loop if copied >= total_size break else {
		copy_size := 0
		if copied > total_size - copied {
			copy_size = total_size - copied
		} else copy_size = copied
		memcopy(dest + copied, dest, copy_size)
		copied += copy_size
	}
}

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
		// todo: error msg
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
