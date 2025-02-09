alloc := fn(size: uint): ?^u8 @import("malloc")
alloc_zeroed := fn(size: uint): ?^u8 @import("calloc")
realloc_c := fn(ptr: ^u8, size: uint): ?^u8 @import("realloc")
dealloc_c := fn(ptr: ^u8): void @import("free")
memmove := fn(dest: ^u8, src: ^u8, size: uint): void @import()
memcopy := fn(dest: ^u8, src: ^u8, size: uint): void @import("memcpy")
memset := fn(dest: ^u8, src: u8, size: uint): void @import()
exit := fn(code: int): void @import()
printf_str := fn(str0: ^u8, strlen: uint, str1: ^u8): void @import("printf")
getrandom := fn(dest: ^u8, size: uint): void @import()
fork := fn(): uint @import()

$realloc := fn(ptr: ^u8, size: uint, size_new: uint): ?^u8 {
	return realloc_c(ptr, size)
}

$dealloc := fn(ptr: ^u8, size: uint): void {
	return dealloc_c(ptr)
}
// temp
$page_size := fn(): uint {
	return 4096
}
// also temp
$calculate_pages := fn(size: uint): uint {
	return (size + page_size() - 1) / page_size()
}

// mmap := fn(ptr: ?^u8, len: uint, prot: u32, flags: u32, fd: u32, offset: uint): ?^u8 @import()
// munmap := fn(ptr: ^u8, len: uint): void @import()
// mremap := fn(ptr: ^u8, old_len: uint, new_len: uint, flags: u32): ?^u8 @import()
// getpagesize := fn(): u32 @import()
// LILY_POSIX_PROT_READWRITE := fn(): u32 @import()
// LILY_POSIX_MAP_SHAREDANONYMOUS := fn(): u32 @import()
// LILY_POSIX_MREMAP_MAYMOVE := fn(): u32 @import()

// causes segfault. nice.
// $alloc := fn(len: uint): ?^u8 return mmap(
// 	null,
// 	len,
// 	LILY_POSIX_PROT_READWRITE(),
// 	LILY_POSIX_MAP_SHARED(),
// 	-1,
// 	0,
// )

// alloc := alloc_zeroed

// $alloc_zeroed := fn(len: uint): ?^u8 return mmap(
// 	null,
// 	len,
// 	LILY_POSIX_PROT_READWRITE(),
// 	LILY_POSIX_MAP_SHAREDANONYMOUS(),
// 	-1,
// 	0,
// )

// $realloc := fn(ptr: ^u8, len: uint, len_new: uint): ?^u8 return mremap(
// 	ptr,
// 	len,
// 	len_new,
// 	LILY_POSIX_MREMAP_MAYMOVE(),
// )

// $dealloc := fn(ptr: ^u8, len: uint): void munmap(ptr, len)

// $page_size := fn(): uint return getpagesize()
// $calculate_pages := fn(size: uint): uint {
// 	return (size + page_size() - 1) / page_size()
// }