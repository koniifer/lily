.{Type, TypeOf} := @use("type.hb")
target := @use("target/lib.hb")
alloc := @use("alloc/lib.hb")
iter := @use("iter.hb")
mem := @use("mem.hb")
log := @use("log.hb")
fmt := @use("fmt.hb")

Version := struct {
	.major: uint;
	.minor: uint;
	.patch: uint;
}

$VERSION := Version.(0, 1, 0)
