lily := @use("lily/lib.hb")

Allocator := lily.alloc.SimpleAllocator
Vec := lily.collections.Vec
HashMap := lily.collections.HashMap
Random := lily.rand.SimpleRandom
Result := lily.result.Result
Hasher := lily.hash.FoldHasher

// ! HashMap only works on AbleOS target (due to compiler bugs)

main := fn(argc: uint, argv: []^void): uint {
	allocator := Allocator.new()
	defer allocator.deinit()
	map := HashMap(uint, uint, Hasher, Allocator).new(&allocator)
	defer map.deinit()

	_ = map.insert(10, 20)
	ptr := map.insert(10, 30)

	good := 0

	if ptr == @unwrap(map.get_ref(10)) {
		lily.log.info("good")
		good = *ptr
		lily.print(good)
	} else {
		lily.log.error("bad")
	}

	other := map.remove(10)
	if @unwrap(other) == good {
		lily.log.info("good 2")
	} else {
		lily.log.error("bad 2")
	}

	return 0
}