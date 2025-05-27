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
	$DEBUG := true
	$MIN_LOGLEVEL := log.LogLevel.Info
	// sufficent for now.
	$FMT_BUFFER_SIZE := 256

	$min_loglevel := fn(): log.LogLevel {
		$if config.DEBUG & config.MIN_LOGLEVEL < .Debug return .Debug
		return config.MIN_LOGLEVEL
	}
}

Version := struct {
	.major: uint;
	.minor: uint;
	.patch: uint;
}

$VERSION := Version.(0, 1, 0)
