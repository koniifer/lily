.{target, config, fmt} := @use("lib.hb")

LogLevel := enum {
	.Error;
	.Warn;
	.Info;
	.Debug;
	.Trace;
}

$log := fn(level: LogLevel, str: []u8): void {
	if level > config.min_loglevel() {
		return
	}
	$match target.current() {
		.AbleOS => return @ecall(3, 1, target.LogEcall.(level, str.ptr, str.len), @size_of(target.LogEcall)),
		_ => @error("target does not support logging"),
	}
}

$error := fn(message: []u8): void return log(.Error, message)
$warn := fn(message: []u8): void return log(.Warn, message)
$info := fn(message: []u8): void return log(.Info, message)
$debug := fn(message: []u8): void return log(.Debug, message)
$trace := fn(message: []u8): void return log(.Trace, message)

fmt_buffer: [config.FMT_BUFFER_SIZE]u8 = idk

print := fn(any: @Any()): void {
	len := fmt.format(fmt_buffer[..], any)
	$match target.current() {
		.AbleOS => info(fmt_buffer[..len]),
		_ => @error("target does not support logging"),
	}
}
