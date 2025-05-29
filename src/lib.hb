.{TypeInfo, InternalKind, Kind} := @use("type.hb")
process := @use("process.hb")
target := @use("target/lib.hb")
alloc := @use("alloc/lib.hb")
iter := @use("iter.hb")
ipc := @use("ipc.hb")
mem := @use("mem.hb")
log := @use("log.hb")
fmt := @use("fmt.hb")

config := struct {
	$optimise := Optimise.Debug
	// sufficent for now. will be replaced with dynamic size later.
	$fmt_buffer_size := 256

	$_min_loglevel := fn($level: type): log.LogLevel {
		$if config.optimise < .ReleaseSafe & level.inner < .Debug return .Debug
		return level.inner
	}
	$min_loglevel := _min_loglevel(struct {
		inner := log.LogLevel.Info
	})
}

Optimise := enum {
	.Debug;
	.ReleaseSafe;
	.ReleaseFast;
}

Version := struct {
	.major: uint;
	.minor: uint;
	.patch: uint;
}

$version := Version.(0, 1, 0)

$panic := fn(context: @Any()): never {
	$if @TypeOf(context) == []u8 {
		log.error(context)
	} else $if @TypeOf(context) == void | @TypeOf(context) == @TypeOf(.()) {
	} else {
		@error("don't know what to do with this: ", @TypeOf(context))
	}
	die
}
