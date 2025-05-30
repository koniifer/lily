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

$arbitrary_0 := 0x243F6A8885A308D3
$arbitrary_1 := 0x13198A2E03707344
$arbitrary_2 := 0xA4093822299F31D0
$arbitrary_3 := 0x82EFA98EC4E6C89
$arbitrary_4 := 0x452821E638D01377
$arbitrary_5 := 0xBE5466CF34E90C6C
$arbitrary_6 := 0xC0AC29B7C97C50DD
$arbitrary_7 := 0x3F84D5B5B5470917
$arbitrary_8 := 0x9216D5D98979FB1B
$arbitrary_9 := 0xD1310BA698DFB5AC
$shared_seed := uint.[arbitrary_4, arbitrary_5, arbitrary_6, arbitrary_7]

U128 := struct {
	.hi: uint;
	.lo: uint

	shift_left := fn(x: ^U128, shift: uint): void {
		lshift := shift & 63
		ge64 := -(shift >> 6)
		hi1 := x.hi << lshift | (x.lo >> 64 - lshift & 63)
		lo1 := x.lo << lshift

		hi2 := x.lo << lshift
		lo2 := 0

		x.hi = hi1 & ~ge64 | (hi2 & ge64)
		x.lo = lo1 & ~ge64 | (lo2 & ge64)
	}
}

// todo: possibly replace uint with u64 for consistency
FoldHasher := struct {
	.accumulator: uint;
	.original_seed: uint;
	.sponge: U128;
	.sponge_len: u8;
	.fold_seed: uint;
	.expand_seed: uint;
	.expand_seed2: uint;
	.expand_seed3: uint

	$new := fn(per_hasher_seed: uint): FoldHasher {
		return .(
			per_hasher_seed,
			per_hasher_seed,
			U128.(0, 0),
			0,
			shared_seed[0],
			shared_seed[1],
			shared_seed[2],
			shared_seed[3],
		)
	}
	$deinit := fn(self: ^FoldHasher): void {
		self.* = idk
	}
	$default := fn(): FoldHasher {
		a := 0
		target.rand_fill(@bit_cast(&a), @size_of(uint))
		return .new(a)
	}
	write := fn(self: ^FoldHasher, _w: @Any()): void {
		$T := TypeInfo(@TypeOf(_w))
		$if T.internal_kind == .Pointer {
			@error("no pointers yet")
			$if T.Child.is_int | T.Child.is_float {
				w := _w.*
				return self.write(w)
			}
		}
		$if T.is_int | T.is_float {
			if self.sponge_len + T.bits > 128 {
				lo := self.sponge.lo
				hi := self.sponge.hi
				self.accumulator = folded_multiply(lo ^ self.accumulator, hi ^ self.accumulator)
				$if T.is_float {
					self.sponge.lo = @bit_cast(@float_to_int(_w))
				} else $if T.is_int {
					self.sponge.lo = @int_cast(_w)
				}
				self.sponge_len = @int_cast(T.bits)
			} else {
				x := U128.(0, 0)
				$if T.is_float {
					x.lo = @bit_cast(@float_to_int(_w))
				} else $if T.is_int {
					x.lo = @int_cast(_w)
				}
				x.shift_left(self.sponge_len)
				self.sponge |= x
				self.sponge_len += @int_cast(T.bits)
			}
		} else {
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
				s0 := base_seed
				s1 := self.expand_seed
				if len >= 8 {
					s0 ^= @as(^uint, @bit_cast(w[0..8].ptr)).*
					s1 ^= @as(^uint, @bit_cast(w[len - 8..].ptr)).*
				} else if len >= 4 {
					s0 ^= @as(^uint, @bit_cast(w[0..4].ptr)).*
					s1 ^= @as(^uint, @bit_cast(w[len - 4..].ptr)).*
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
	}

	finish := fn(self: ^FoldHasher): uint {
		if self.sponge_len > 0 {
			return folded_multiply(self.sponge.lo ^ self.accumulator, self.sponge.hi ^ self.fold_seed)
		} else {
			return self.accumulator
		}
	}

	$reset := fn(self: ^FoldHasher): void {
		self.accumulator = self.original_seed
		self.sponge = .(0, 0)
		self.sponge_len = 0
	}
}

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
	$chunk_size := 16
	lo := 0
	hi := bytes.len
	loop {
		if lo >= hi {
			break
		}

		a := @as(^uint, @bit_cast(bytes[lo..lo + 16][0..8].ptr)).*
		b := @as(^uint, @bit_cast(bytes[lo..lo + 16][8..16].ptr)).*
		c := @as(^uint, @bit_cast(bytes[hi - 17..hi - 1][0..8].ptr)).*
		d := @as(^uint, @bit_cast(bytes[hi - 17..hi - 1][8..16].ptr)).*

		hi -= chunk_size
		lo += chunk_size

		s0 = folded_multiply(a ^ s0, c ^ fold_seed)
		s1 = folded_multiply(b ^ s1, d ^ fold_seed)
	}
	return s0 ^ s1
}

hash_bytes_long := fn(bytes: @Any(), s0: uint, s1: uint, s2: uint, s3: uint, fold_seed: uint): uint {
	$chunk_size := 64
	remainder := bytes.len % chunk_size
	chunk := 0
	loop if chunk >= bytes.len - remainder break else {
		a := @as(^uint, @bit_cast(bytes[chunk..chunk + chunk_size][0..8].ptr)).*
		b := @as(^uint, @bit_cast(bytes[chunk..chunk + chunk_size][8..16].ptr)).*
		c := @as(^uint, @bit_cast(bytes[chunk..chunk + chunk_size][16..24].ptr)).*
		d := @as(^uint, @bit_cast(bytes[chunk..chunk + chunk_size][24..32].ptr)).*
		e := @as(^uint, @bit_cast(bytes[chunk..chunk + chunk_size][32..40].ptr)).*
		f := @as(^uint, @bit_cast(bytes[chunk..chunk + chunk_size][40..48].ptr)).*
		g := @as(^uint, @bit_cast(bytes[chunk..chunk + chunk_size][48..56].ptr)).*
		h := @as(^uint, @bit_cast(bytes[chunk..chunk + chunk_size][56..64].ptr)).*

		chunk += chunk_size

		s0 = folded_multiply(a ^ s0, e ^ fold_seed)
		s1 = folded_multiply(b ^ s1, f ^ fold_seed)
		s2 = folded_multiply(c ^ s2, g ^ fold_seed)
		s3 = folded_multiply(d ^ s3, h ^ fold_seed)
	}
	s0 ^= s2
	s1 ^= s3

	if remainder > 0 {
		if remainder < 16 remainder = 16
		return hash_bytes_medium(bytes[bytes.len - remainder..], s0, s1, fold_seed)
	} else {
		return s0 ^ s1
	}
}

// todo: go to math.hb
rotate_right := fn(x: uint, n: u32): uint {
	n = n % 64
	return x >> n | x << 64 - n
}
