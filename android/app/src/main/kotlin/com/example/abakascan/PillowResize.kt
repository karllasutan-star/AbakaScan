package com.example.abakascan

import kotlin.math.*

/** Separable, antialiased bilinear RGB resize with Pillow's 22-bit coefficient rounding.
 * Source is a virtual square padded RGB image; no full square bitmap is allocated.
 */
object PillowResize {
    private const val BITS = 22
    private data class Weights(val first: Int, val coeff: IntArray)
    private fun weights(input: Int, output: Int): Array<Weights> {
        val scale = input.toDouble() / output
        val filterScale = max(1.0, scale)
        return Array(output) { x ->
            val center = (x + .5) * scale
            val first = max(0, (center - filterScale + .5).toInt())
            val end = min(input, (center + filterScale + .5).toInt())
            val values = DoubleArray(end - first) { i -> max(0.0, 1.0 - abs((i + first - center + .5) / filterScale)) }
            val sum = values.sum()
            Weights(first, IntArray(values.size) { i -> (values[i] / sum * (1 shl BITS) + .5).toInt() })
        }
    }
    fun resize(width: Int, height: Int, pixels: IntArray, orientation: Int): ByteArray {
        val swap = orientation in 5..8
        val w = if (swap) height else width
        val h = if (swap) width else height
        val side = max(w, h)
        val left = (side - w) / 2
        val top = (side - h) / 2
        fun pixel(x: Int, y: Int): Int {
            val xx = x - left; val yy = y - top
            if (xx !in 0 until w || yy !in 0 until h) return (124 shl 16) or (116 shl 8) or 104
            val sx: Int; val sy: Int
            when (orientation) {
                2 -> { sx = width - 1 - xx; sy = yy }
                3 -> { sx = width - 1 - xx; sy = height - 1 - yy }
                4 -> { sx = xx; sy = height - 1 - yy }
                5 -> { sx = yy; sy = xx }
                6 -> { sx = yy; sy = height - 1 - xx }
                7 -> { sx = width - 1 - yy; sy = height - 1 - xx }
                8 -> { sx = width - 1 - yy; sy = xx }
                else -> { sx = xx; sy = yy }
            }
            return pixels[sy * width + sx]
        }
        val coeff = weights(side, 224)
        val horizontal = ByteArray(side * 224 * 3)
        for (y in 0 until side) for (x in 0 until 224) {
            val weights = coeff[x]
            for (channel in 0..2) {
                var sum = 1 shl (BITS - 1)
                for (i in weights.coeff.indices) {
                    val color = (pixel(weights.first + i, y) shr ((2 - channel) * 8)) and 255
                    sum += color * weights.coeff[i]
                }
                horizontal[(y * 224 + x) * 3 + channel] = (sum shr BITS).coerceIn(0, 255).toByte()
            }
        }
        val result = ByteArray(224 * 224 * 3)
        for (y in 0 until 224) for (x in 0 until 224) for (c in 0..2) {
            val weights = coeff[y]
            var sum = 1 shl (BITS - 1)
            for (i in weights.coeff.indices) {
                sum += (horizontal[((weights.first + i) * 224 + x) * 3 + c].toInt() and 255) * weights.coeff[i]
            }
            result[(y * 224 + x) * 3 + c] = (sum shr BITS).coerceIn(0, 255).toByte()
        }
        return result
    }
    fun normalize(rgb: ByteArray): FloatArray {
        val mean = floatArrayOf(.485f, .456f, .406f)
        val std = floatArrayOf(.229f, .224f, .225f)
        val count = 224 * 224
        return FloatArray(count * 3) { i ->
            val c = i / count
            (((rgb[(i % count) * 3 + c].toInt() and 255) / 255f) - mean[c]) / std[c]
        }
    }
}
