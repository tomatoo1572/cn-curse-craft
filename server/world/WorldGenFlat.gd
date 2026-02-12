extends RefCounted

# M2: thread-safe static generator (no shared state)
# subchunk y=0: y=0..3 stone, else air

static func generate_subchunk_0_bytes() -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(16 * 16 * 16)

	for y in range(16):
		for z in range(16):
			for x in range(16):
				var idx := x + (z * 16) + (y * 256)
				if y <= 3:
					bytes[idx] = 1 # stone
				else:
					bytes[idx] = 0 # air
	return bytes
