/*
* This code is an implementation of the FoldHash algorithm from https://github.com/orlp/foldhash,
* originally written by Orson Peters under the zlib license.
*
* Changes to the original code were made to meet the simplicity requirements of this implementation.
* Behaviour aims to be equivalent but not identical to the original code.
*
* Copyright (c) 2024 Orson Peters
* 
* This software is provided 'as-is', without any express or implied warranty. In
* no event will the authors be held liable for any damages arising from the use of
* this software.
* 
* Permission is granted to anyone to use this software for any purpose, including
* commercial applications, and to alter it and redistribute it freely, subject to
* the following restrictions:
* 
* 1. The origin of this software must not be misrepresented; you must not claim
*     that you wrote the original software. If you use this software in a product,
*     an acknowledgment in the product documentation would be appreciated but is
*     not required.
* 
* 2. Altered source versions must be plainly marked as such, and must not be
*     misrepresented as being the original software.
* 
* 3. This notice may not be removed or altered from any source distribution.
*/;

.{math, Target, TypeOf} := @use("../lib.hb")

$ARBITRARY0 := 0x243F6A8885A308D3
$ARBITRARY1 := 0x13198A2E03707344
$ARBITRARY2 := 0xA4093822299F31D0
$ARBITRARY3 := 0x82EFA98EC4E6C89
$ARBITRARY4 := 0x452821E638D01377
$ARBITRARY5 := 0xBE5466CF34E90C6C
$ARBITRARY6 := 0xC0AC29B7C97C50DD
$ARBITRARY7 := 0x3F84D5B5B5470917
$ARBITRARY8 := 0x9216D5D98979FB1B
$ARBITRARY9 := 0xD1310BA698DFB5AC
$FIXED_GLOBAL_SEED := uint.[ARBITRARY4, ARBITRARY5, ARBITRARY6, ARBITRARY7]

U128 := packed struct {a: uint, b: uint}

$folded_multiply := fn(x: uint, y: uint): uint {
	lx: u32 = @intcast(x)
	ly: u32 = @as(u32, @intcast(y))
	hx := x >> 32
	hy := y >> 32
	afull := lx * hy
	bfull := hx * ly
	return afull ^ (bfull << 32 | bfull >> 32)
}

// ! (libc) (compiler) panics with "not yet implemented: bool" when using slice
hash_bytes_medium := fn(bytes: ^u8, len: uint, s0: uint, s1: uint, fold_seed: uint): uint {
	lo := bytes
	end := bytes + len
	hi := end - 16

	loop if lo >= hi return s0 ^ s1 else {
		a := *@as(^uint, @bitcast(lo))
		b := *@as(^uint, @bitcast(lo + 8))
		c := *@as(^uint, @bitcast(hi))
		d := *@as(^uint, @bitcast(hi + 8))
		s0 = folded_multiply(a ^ s0, c ^ fold_seed)
		s1 = folded_multiply(b ^ s1, d ^ fold_seed)
		hi -= 16
		lo += 16
	}
	return s0 ^ s1
}

hash_bytes_long := fn(bytes: ^u8, len: uint, s0: uint, s1: uint, s2: uint, s3: uint, fold_seed: uint): uint {
	$chunk_size := 64
	chunks := len / chunk_size
	remainder := len % chunk_size

	ptr := bytes
	i := 0
	loop if i >= chunks break else {
		a := *@as(^uint, @bitcast(ptr))
		b := *@as(^uint, @bitcast(ptr + 8))
		c := *@as(^uint, @bitcast(ptr + 16))
		d := *@as(^uint, @bitcast(ptr + 24))
		e := *@as(^uint, @bitcast(ptr + 32))
		f := *@as(^uint, @bitcast(ptr + 40))
		g := *@as(^uint, @bitcast(ptr + 48))
		h := *@as(^uint, @bitcast(ptr + 56))

		s0 = folded_multiply(a ^ s0, e ^ fold_seed)
		s1 = folded_multiply(b ^ s1, f ^ fold_seed)
		s2 = folded_multiply(c ^ s2, g ^ fold_seed)
		s3 = folded_multiply(d ^ s3, h ^ fold_seed)

		ptr += chunk_size
		i += 1
	}

	s0 ^= s2
	s1 ^= s3

	if remainder > 0 {
		remainder_start := bytes + len - math.max(remainder, 16)
		return hash_bytes_medium(remainder_start, math.max(remainder, 16), s0, s1, fold_seed)
	}

	return s0 ^ s1
}

FoldHasher := struct {
	accumulator: uint,
	original_seed: uint,
	sponge: U128,
	sponge_len: u8,
	fold_seed: uint,
	expand_seed: uint,
	expand_seed2: uint,
	expand_seed3: uint,

	$new := fn(seed: uint): Self {
		return .(
			seed,
			seed,
			.(0, 0),
			0,
			FIXED_GLOBAL_SEED[0],
			FIXED_GLOBAL_SEED[1],
			FIXED_GLOBAL_SEED[2],
			FIXED_GLOBAL_SEED[3],
		)
	}

	$deinit := fn(self: ^Self): void {
	}

	$default := fn(): Self {
		a := 0
		Target.getrandom(@bitcast(&a), @sizeof(@TypeOf(a)))
		return Self.new(a)
	}

	write := fn(self: ^Self, any: @Any()): void {
		T := TypeOf(any)

		// ! broken
		// if T.is_int() {
		// 	bits := 8 * T.size()
		// 	if @as(uint, self.sponge_len) + bits > 128 {
		// 		self.accumulator = folded_multiply(self.sponge.b ^ self.accumulator, self.sponge.a ^ self.fold_seed)
		// 		self.sponge = *@bitcast(&any)
		// 		self.sponge_len = @intcast(bits)
		// 	} else {
		// 		// note: this behaviour is incorrect with U128 struct
		// 		self.sponge |= *@as(^U128, @bitcast(&any)) << *@as(^U128, @bitcast(&self.sponge_len))
		// 		self.sponge_len += @intcast(bits)
		// 	}
		// 	return
		// }

		bytes := @as(^u8, @bitcast(&any))
		len := 0
		// ! (libc) (compiler) crashes when setting len = any.len
		match T.kind() {
			.Slice => {
				len = any.len
				bytes = any.ptr
			},
			_ => len = @sizeof(T.This()),
		}

		s0 := self.accumulator
		s1 := self.expand_seed
		if len <= 16 {
			if len >= 8 {
				s0 ^= *@bitcast(bytes)
				s1 ^= *@bitcast(bytes + len - 8)
			} else if len >= 4 {
				s0 ^= *@as(^u32, @bitcast(bytes))
				s1 ^= *@as(^u32, @bitcast(bytes + len - 4))
			} else if len > 0 {
				lo := *bytes
				mid := *(bytes + len / 2)
				hi := *(bytes + len - 1)
				s0 ^= lo
				s1 ^= @as(uint, hi) << 8 | mid
			}
			self.accumulator = folded_multiply(s0, s1)
		} else if len < 256 {
			self.accumulator = hash_bytes_medium(bytes, len, s0, s1, self.fold_seed)
		} else {
			self.accumulator = @inline(hash_bytes_long, bytes, len, s0, s1, self.expand_seed2, self.expand_seed3, self.fold_seed)
		}
	}

	finish := fn(self: ^Self): uint {
		if self.sponge_len > 0 {
			return folded_multiply(self.sponge.b ^ self.accumulator, self.sponge.a ^ self.fold_seed)
		} else {
			return self.accumulator
		}
	}

	reset := fn(self: ^Self): void {
		self.accumulator = self.original_seed
		self.sponge = .(0, 0)
		self.sponge_len = 0
	}
}