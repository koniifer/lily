expectations := .{
	return_value: 0,
	emulate_ecalls: true,
}

lily.{alloc, collections, hash, log, mem} := @use("../../src/lib.hb")

main := fn(): uint {
	arena := alloc.Arena.new()
	defer arena.deinit()

	map := collections.HashMap(
		uint,
		void,
		alloc.Arena,
		hash.RapidHasher,
	).new(&arena)
	defer map.deinit()

	i := 0
	loop if i == 10 break else {
		v := map.insert(i, {})
		if v == null return 1
		i += 1
	}

	// working under assumption fakern output is correct
	correct := u8.[112, 255, 65, 255, 63, 255, 255, 255, 48, 116, 255, 255, 255, 106, 255, 255, 255, 107, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 12, 43, 88, 255]
	hashes := map.metadata[0..map.entries.len]

	if !mem.equals(correct[..], hashes) return 2

	loop if map.size == 0 break else {
		i -= 1
		v := map.remove(i)
		if v == null return 3
	}

	if i != 0 return 4

	return 0
}
