Version := struct {
	.major: uint;
	.minor: uint;
	.patch: uint;
}

$VERSION := Version.(0, 1, 0)

target := @use("target/lib.hb")
iter := @use("iter.hb")
mem := @use("mem.hb")
log := @use("log.hb")
