/*
* This source file is an implementation of the FoldHash algorithm from https://github.com/orlp/foldhash,
* originally written by Orson Peters under the zlib license.
*
* Changes to the original code were made to meet the simplicity requirements of this implementation.
* Behaviour aims to be equivalent but not identical to the original code.
*
* The following is the license under which this source file is distributed:
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
*/

lily.{TypeInfo, mem, target} := @use("../lib.hb")

FoldHasher := @CurrentScope();

.accumulator: uint;
.original_seed: uint;
.fold_seed: uint;
.expand_seed: uint;
.expand_seed2: uint;
.expand_seed3: uint

$new := fn(per_hasher_seed: uint): FoldHasher {
	return .(
		per_hasher_seed,
		per_hasher_seed,
		0x452821E638D01377,
		0xBE5466CF34E90C6C,
		0xC0AC29B7C97C50DD,
		0x3F84D5B5B5470917,
	)
}
$deinit := fn(self: ^FoldHasher): void self.* = idk
$default := fn(): FoldHasher {
	a := 0
	target.rand_fill(@bit_cast(&a), @size_of(uint))
	return .new(a)
}
write := fn(self: ^FoldHasher, _w: @Any()): void {
	$T := TypeInfo(@TypeOf(_w))
	$if T.internal_kind == .Struct & T.offset != 1 {
		@error("Does not support structs of align != 1 (or single field) yet.")
	}

	w: []u8 = idk

	$if T.internal_kind == .SliceOrArray {
		w = mem.as_bytes(_w[..])
	} else $if T.internal_kind == .Pointer {
		w = mem.as_bytes(_w)
	} else {
		w = mem.as_bytes(&_w)
	}

	len := w.len
	base_seed := rotate_right(self.accumulator, @int_cast(len))
	if len <= 16 {
		ptr := w.ptr
		s0 := base_seed
		s1 := self.expand_seed
		if len >= 8 {
			s0 ^= @as(^uint, @bit_cast(ptr)).*
			s1 ^= @as(^uint, @bit_cast(ptr + len - 8)).*
		} else if len >= 4 {
			s0 ^= @as(^u32, @bit_cast(ptr)).*
			s0 ^= @as(^u32, @bit_cast(ptr + len - 4)).*
		} else if len > 0 {
			lo := w[0]
			mid := w[len >> 1]
			hi := w[len - 1]
			s0 ^= lo
			s1 ^= @int_cast(hi) << 8 | mid
		}
		self.accumulator = folded_multiply(s0, s1)
	} else if len < 256 {
		self.accumulator = hash_bytes_medium(
			w,
			base_seed,
			base_seed + self.expand_seed,
			self.fold_seed,
		)
	} else {
		self.accumulator = hash_bytes_long(
			w,
			base_seed,
			base_seed + self.expand_seed,
			base_seed + self.expand_seed2,
			base_seed + self.expand_seed3,
			self.fold_seed,
		)
	}
}

$finish := fn(self: ^FoldHasher): uint return folded_multiply(self.accumulator, 0x243f6a8885a308d3)
$reset := fn(self: ^FoldHasher): void self.accumulator = self.original_seed

$folded_multiply := fn(x: uint, y: uint): uint {
	lx: u32 = @int_cast(x)
	ly: u32 = @int_cast(y)
	hx := x >> 32
	hy := y >> 32

	ll := @as(uint, lx) * ly
	lh := @as(uint, lx) * hy
	hl := hx * ly
	hh := hx * hy
	return rotate_right(hh ^ ll ^ (hl ^ lh), 32)
}

hash_bytes_medium := fn(bytes: @Any(), s0: uint, s1: uint, fold_seed: uint): uint {
	lo := bytes.ptr
	hi := bytes.ptr + bytes.len
	loop if lo >= hi break else {
		a := @as(^uint, @bit_cast(lo)).*
		b := @as(^uint, @bit_cast(lo) + 1).*
		c := @as(^uint, @bit_cast(hi) - 2).*
		d := @as(^uint, @bit_cast(hi) - 1).*

		hi -= 16
		lo += 16

		s0 = folded_multiply(a ^ s0, c ^ fold_seed)
		s1 = folded_multiply(b ^ s1, d ^ fold_seed)
	}
	return s0 ^ s1
}

hash_bytes_long := fn(bytes: @Any(), s0: uint, s1: uint, s2: uint, s3: uint, fold_seed: uint): uint {
	remainder := bytes.len & 63
	end := bytes.ptr + bytes.len - remainder
	chunk := bytes.ptr
	loop if chunk >= end break else {
		a := @as(^uint, @bit_cast(chunk)).*
		b := @as(^uint, @bit_cast(chunk) + 1).*
		c := @as(^uint, @bit_cast(chunk) + 2).*
		d := @as(^uint, @bit_cast(chunk) + 3).*
		e := @as(^uint, @bit_cast(chunk) + 4).*
		f := @as(^uint, @bit_cast(chunk) + 5).*
		g := @as(^uint, @bit_cast(chunk) + 6).*
		h := @as(^uint, @bit_cast(chunk) + 7).*

		chunk += 64

		s0 = folded_multiply(a ^ s0, e ^ fold_seed)
		s1 = folded_multiply(b ^ s1, f ^ fold_seed)
		s2 = folded_multiply(c ^ s2, g ^ fold_seed)
		s3 = folded_multiply(d ^ s3, h ^ fold_seed)
	}
	s0 ^= s2
	s1 ^= s3

	if remainder > 0 {
		if remainder < 16 remainder = 16
		return @inline(hash_bytes_medium, bytes[bytes.len - remainder..], s0, s1, fold_seed)
	} else {
		return s0 ^ s1
	}
}

// todo: go to math.hb
rotate_right := fn(x: uint, n: u32): uint {
	n &= 63
	return x >> n | x << 64 - n
}
