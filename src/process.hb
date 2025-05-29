lily.{target} := @use("lib.hb")

ProcessID := fn(): type $match target.current {
	.AbleOS => return struct {
		.host_id: uint;
		.id: uint;
	},
}

$host_id_placeholder := 0

$spawn := fn(executable: []u8): ProcessID() {
	raw := target.proc_spawn(executable)
	// todo: this
	return .(host_id_placeholder, raw)
}

$fork := fn(): ProcessID() {
	raw := target.proc_fork()
	// todo: this
	return .(host_id_placeholder, raw)
}
