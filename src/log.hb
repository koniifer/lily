.{target, config, fmt} := @use("lib.hb")

LogLevel := enum {
	.Error;
	.Warn;
	.Info;
	.Debug;
	.Trace;
}

$log := fn(level: LogLevel, str: []u8): void {
	if level > config.min_loglevel {
		return
	}
	$match target.current {
		.AbleOS => return @ecall(3, 1, target.LogEcall.(level, str.ptr, str.len), @size_of(target.LogEcall)),
		_ => @error("target does not support logging"),
	}
}

// type here used as workaround for comptime (and lack of inlining)
$log_builder := fn($level: type): type {
	$if level.inner > config.min_loglevel {
		return fn(message: []u8): void {
		}
	} else {
		return fn(message: []u8): void $match target.current {
			.AbleOS => return @ecall(3, 1, target.LogEcall.(level.inner, message.ptr, message.len), @size_of(target.LogEcall)),
			_ => @error("target does not support logging"),
		}
	}
}

$error := log_builder(struct {
	inner := LogLevel.Error
})
$warn := log_builder(struct {
	inner := LogLevel.Warn
})
$info := log_builder(struct {
	inner := LogLevel.Info
})
$debug := log_builder(struct {
	inner := LogLevel.Debug
})
$trace := log_builder(struct {
	inner := LogLevel.Trace
})

fmt_buffer: [config.fmt_buffer_size]u8 = idk

$print := fn(any: @Any()): void {
	info(fmt_buffer[..fmt.format(fmt_buffer[..], any)])
}

$printf := fn(str: []u8, any: @Any()): void {
	info(fmt_buffer[..fmt.format_with_str(str, fmt_buffer[..], any)])
}
