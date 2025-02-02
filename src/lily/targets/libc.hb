alloc := fn(size: uint): ?^u8 @import("malloc")
alloc_zeroed := fn(size: uint): ?^u8 @import("calloc")
realloc_c := fn(ptr: ^u8, size: uint): ?^u8 @import("realloc")
dealloc_c := fn(ptr: ^u8): void @import("free")
memmove := fn(dest: ^u8, src: ^u8, size: uint): void @import()
memcopy := fn(dest: ^u8, src: ^u8, size: uint): void @import()
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