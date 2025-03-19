lily.{target} := @use("lib.hb")

ProcessID := fn(): type {
	$match target.current() {
		.AbleOS => return struct {
			.host_id: uint;
			.id: uint;
		},
	}
}

$HOST_ID_PLACEHOLDER := 0

$spawn := fn(executable: []u8): ProcessID() {
	raw := target.proc_spawn(executable)
	// todo: this
	return .(HOST_ID_PLACEHOLDER, raw)
}

$fork := fn(): ProcessID() {
	raw := target.proc_fork()
	// todo: this
	return .(HOST_ID_PLACEHOLDER, raw)
}
