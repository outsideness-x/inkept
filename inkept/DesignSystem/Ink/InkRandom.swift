import CoreGraphics
import Foundation

/// Deterministic randomness, so every drawn line keeps the same personality across launches.
struct InkRandom {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) &+ 0x9E37_79B9_7F4A_7C15
    }

    /// SplitMix64.
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    /// A value in `0..<1`.
    mutating func unit() -> CGFloat {
        CGFloat(next() >> 11) / CGFloat(UInt64(1) << 53)
    }

    /// A value in `-1..<1`.
    mutating func signed() -> CGFloat {
        unit() * 2 - 1
    }

    mutating func value(in range: ClosedRange<CGFloat>) -> CGFloat {
        range.lowerBound + unit() * (range.upperBound - range.lowerBound)
    }
}

enum InkNoise {
    /// A repeatable value in `-1...1` for an integer lattice point.
    static func lattice(_ index: Int, seed: Int) -> CGFloat {
        var random = InkRandom(seed: (seed &* 73_856_093) ^ (index &* 19_349_663))
        return random.signed()
    }

    /// Smooth one-dimensional value noise in `-1...1`: the slow drift of a hand.
    static func value(_ x: CGFloat, seed: Int) -> CGFloat {
        let base = floor(x)
        let fraction = x - base
        let eased = fraction * fraction * (3 - 2 * fraction)
        let index = Int(base)
        return lattice(index, seed: seed) * (1 - eased) + lattice(index + 1, seed: seed) * eased
    }
}

extension UUID {
    /// A seed that survives relaunches, unlike `hashValue`, which Swift randomizes per process.
    var inkSeed: Int {
        let bytes = uuid
        let high = [bytes.0, bytes.1, bytes.2, bytes.3, bytes.4, bytes.5, bytes.6, bytes.7]
        return Int(truncatingIfNeeded: high.reduce(UInt64(0)) { $0 << 8 | UInt64($1) })
    }
}

extension String {
    /// FNV-1a, stable across launches.
    var inkSeed: Int {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return Int(truncatingIfNeeded: hash)
    }
}
