.{target, config, fmt} := @use("lib.hb")

// todo: this whole file sucks

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
		.hbvm_ableos => return @ecall(3, 1, target.LogEcall.(level, str.ptr, str.len), @size_of(target.LogEcall)),
		.x86_64_linux => {
			pfx: []u8 = idk
			match level {
				.Error => pfx = "\{1b}[31mERROR\{1b}[0m: ",
				.Warn => pfx = "\{1b}[33mWARN\{1b}[0m: ",
				.Info => pfx = "\{1b}[32mINFO\{1b}[0m: ",
				.Debug => pfx = "\{1b}[34mDEBUG\{1b}[0m: ",
				.Trace => pfx = "\{1b}[35mTRACE\{1b}[0m: ",
			}
			target.memcopy(@bit_cast(&fmt_buffer), pfx.ptr, pfx.len)
			target.memcopy(@bit_cast(&fmt_buffer) + pfx.len, str.ptr, str.len)
			ptr := @as(^u8, @bit_cast(&fmt_buffer)) + pfx.len + str.len
			ptr.* = '\n'
			@syscall(1, 1, &fmt_buffer, pfx.len + str.len + 1)
		},
		_ => @error("target does not support logging"),
	}
}

// type here used as workaround for comptime (and lack of inlining)
$log_builder := fn($level: type): type {
	$if level.inner > config.min_loglevel {
		return fn(str: []u8): void {
		}
	} else {
		return fn(str: []u8): void $match target.current {
			.hbvm_ableos => return @ecall(3, 1, target.LogEcall.(level.inner, str.ptr, str.len), @size_of(target.LogEcall)),
			.x86_64_linux => {
				pfx: []u8 = idk
				$match level.inner {
					.Error => pfx = "\{1b}[31mERROR\{1b}[0m: ",
					.Warn => pfx = "\{1b}[33mWARN\{1b}[0m: ",
					.Info => pfx = "\{1b}[32mINFO\{1b}[0m: ",
					.Debug => pfx = "\{1b}[34mDEBUG\{1b}[0m: ",
					.Trace => pfx = "\{1b}[35mTRACE\{1b}[0m: ",
				}
				target.memcopy(@bit_cast(&fmt_buffer), pfx.ptr, pfx.len)
				target.memcopy(@bit_cast(&fmt_buffer) + pfx.len, str.ptr, str.len)
				ptr := @as(^u8, @bit_cast(&fmt_buffer)) + pfx.len + str.len
				ptr.* = '\n'
				@syscall(1, 1, &fmt_buffer, pfx.len + str.len + 1)
			},
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
	$match target.current {
		.hbvm_ableos => info(fmt_buffer[..fmt.format(fmt_buffer[..], any)]),
		.x86_64_linux => {
			len := fmt.format(fmt_buffer[..], any)
			fmt_buffer[len] = '\n'
			@syscall(1, 1, &fmt_buffer, len + 1)
		},
		_ => @error("target does not support logging"),
	}
}

$printf := fn(str: []u8, any: @Any()): void {
	$match target.current {
		.hbvm_ableos => info(fmt_buffer[..fmt.format_with_str(str, fmt_buffer[..], any)]),
		.x86_64_linux => {
			len := fmt.format_with_str(str, fmt_buffer[..], any)
			fmt_buffer[len] = '\n'
			@syscall(1, 1, &fmt_buffer, len + 1)
		},
		_ => @error("target does not support logging"),
	}
}
