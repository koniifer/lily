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
	loop if src + @size_of(uint) > end break else {
		@as(^uint, @bit_cast(dest)).* = @as(^uint, @bit_cast(src)).*
		dest += @size_of(uint)
		src += @size_of(uint)
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
	total_size := count * len
	if count <= 8 {
		end := dest + total_size
		loop if dest >= end break else {
			memcopy(dest, src, len)
			dest += len
		}
		return
	}

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
// note to self: the last zero needs to be there
// i guess the registers are getting clobbered / used
// probably need to do that for other syscalls too...
$rand_fill := fn(dest: ^u8, len: uint): void return @syscall(sys_getrandom, dest, len, 0)
