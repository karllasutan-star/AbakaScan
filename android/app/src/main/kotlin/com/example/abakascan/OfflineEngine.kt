package com.example.abakascan

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.exifinterface.media.ExifInterface
import ai.onnxruntime.*
import org.json.JSONObject
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.security.MessageDigest
import kotlin.math.*

class OfflineEngine(private val context: Context) : AutoCloseable {
    private val env = OrtEnvironment.getEnvironment()
    private val options = OrtSession.SessionOptions().apply { setIntraOpNumThreads(2); setInterOpNumThreads(1) }
    private var material: OrtSession? = null
    private var grader: OrtSession? = null
    private var validated = false
    private var report: Map<String, Any>? = null
    private val grades = arrayOf("JK", "S-I", "S-S2")
    private val modelHashes = mapOf(
        "material_gate_v3.onnx" to "cb2d000b435d164d2942b2d8839b310a8591f1ad71e21d4bf2a47c310bcf11be",
        "grade_classifier_v3.onnx" to "fd6c5f2a44225ae0aef245eb67582c893b43e70157e1af5c1f638bb5ff291b3b")
    private fun asset(path: String) = context.assets.open("flutter_assets/assets/offline_v3/$path").use { it.readBytes() }
    private fun load() {
        if (material != null && grader != null) return
        for ((name, hash) in modelHashes) {
            val file = File(context.noBackupFilesDir, name)
            fun sha(file: File): String = file.inputStream().use { stream ->
                val d = MessageDigest.getInstance("SHA-256"); val b = ByteArray(65536)
                while (true) { val n = stream.read(b); if (n < 0) break; d.update(b, 0, n) }
                d.digest().joinToString("") { "%02x".format(it) }
            }
            if (!file.exists() || sha(file) != hash) {
                val temp = File(context.noBackupFilesDir, "$name.tmp")
                context.assets.open("flutter_assets/assets/offline_v3/models/$name").use { input -> temp.outputStream().use { input.copyTo(it) } }
                check(sha(temp) == hash) { "Offline model file check failed." }
                check(temp.renameTo(file)) { "Unable to prepare offline model." }
            }
            if (name.startsWith("material")) material = env.createSession(file.absolutePath, options)
            else grader = env.createSession(file.absolutePath, options)
        }
    }
    private fun scores(session: OrtSession, tensor: FloatArray): FloatArray {
        OnnxTensor.createTensor(env, FloatBuffer.wrap(tensor), longArrayOf(1, 3, 224, 224)).use { input ->
            session.run(mapOf("image" to input)).use { output ->
                @Suppress("UNCHECKED_CAST")
                val logits = (output[0].value as Array<FloatArray>)[0]
                val max = logits.maxOrNull()!!.toDouble()
                val exps = DoubleArray(logits.size) { exp(logits[it] - max) }
                val sum = exps.sum()
                return FloatArray(logits.size) { (exps[it] / sum).toFloat() }.also { result ->
                    check(result.all { it.isFinite() && it in 0f..1f }) { "Invalid model scores." }
                }
            }
        }
    }
    private fun prepare(bytes: ByteArray): ByteArray {
        require(bytes.isNotEmpty() && bytes.size <= 20 * 1024 * 1024) { "Select an image smaller than 20 MB." }
        val info = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, info)
        require(info.outWidth > 0 && info.outHeight > 0 && info.outWidth.toLong() * info.outHeight <= 24_000_000 && max(info.outWidth, info.outHeight) <= 10000) {
            "This image is too large or unsupported. Select a smaller JPEG or PNG image."
        }
        val orientation = try { ExifInterface(ByteArrayInputStream(bytes)).getAttributeInt(ExifInterface.TAG_ORIENTATION, 1) } catch (_: Exception) { 1 }
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size,
            BitmapFactory.Options().apply { inPreferredConfig = Bitmap.Config.ARGB_8888; inScaled = false })
            ?: throw IllegalArgumentException("Unable to read this image.")
        val w = bitmap.width; val h = bitmap.height
        val pixels = IntArray(w * h)
        bitmap.getPixels(pixels, 0, w, 0, 0, w, h)
        bitmap.recycle()
        return PillowResize.resize(w, h, pixels, orientation)
    }
    fun selfTest(): Map<String, Any> {
        report?.let { return it }
        load()
        val fixtures = org.json.JSONArray(String(asset("fixtures/expected_outputs.json"), Charsets.UTF_8))
        var maxTensorScoreDifference = 0.0; var maxImageScoreDifference = 0.0
        var maxPixelDifference = 0
        for (i in 0 until fixtures.length()) {
            val fixture = fixtures.getJSONObject(i)
            val rawTensor = asset("fixtures/${fixture.getString("tensor")}")
            val buffer = ByteBuffer.wrap(rawTensor).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
            val tensor = FloatArray(buffer.remaining()); buffer.get(tensor)
            val fromImage = prepare(asset("fixtures/${fixture.getString("original_image")}"))
            val reference = BitmapFactory.decodeByteArray(asset("fixtures/${fixture.getString("resized_rgb")}"), 0,
                asset("fixtures/${fixture.getString("resized_rgb")}").size)!!
            var squareError = 0.0
            for (p in 0 until 224 * 224) for (c in 0..2) {
                val wanted = (reference.getPixel(p % 224, p / 224) shr ((2 - c) * 8)) and 255
                val difference = abs((fromImage[p * 3 + c].toInt() and 255) - wanted)
                maxPixelDifference = max(maxPixelDifference, difference)
                squareError += difference.toDouble() * difference
            }
            reference.recycle()
            check(sqrt(squareError / (224 * 224 * 3)) <= 2.0 && maxPixelDifference <= 12) {
                "Offline image preparation check failed on this device."
            }
            val originalScores = arrayOf(scores(material!!, tensor), scores(grader!!, tensor))
            val imageScores = arrayOf(scores(material!!, PillowResize.normalize(fromImage)), scores(grader!!, PillowResize.normalize(fromImage)))
            for (model in 0..1) {
                val expected = fixture.getJSONArray(if (model == 0) "material_scores" else "grade_scores")
                for (j in 0 until expected.length()) {
                    maxTensorScoreDifference = max(maxTensorScoreDifference, abs(originalScores[model][j] - expected.getDouble(j)))
                    maxImageScoreDifference = max(maxImageScoreDifference, abs(imageScores[model][j] - expected.getDouble(j)))
                }
            }
            fun winner(values: FloatArray) = values.indices.maxByOrNull { values[it] }!!
            check((originalScores[0][1] >= .8f) == (imageScores[0][1] >= .8f) && winner(originalScores[1]) == winner(imageScores[1])) {
                "Offline conversion decisions do not match on this device."
            }
        }
        check(maxTensorScoreDifference <= .0001 && maxImageScoreDifference <= .01) { "Offline model score check failed on this device." }
        validated = true
        return mapOf<String, Any>("passed" to true, "fixtures" to fixtures.length(),
            "maximum_tensor_score_difference" to maxTensorScoreDifference,
            "maximum_image_score_difference" to maxImageScoreDifference,
            "maximum_rgb_pixel_difference" to maxPixelDifference,
            "threshold" to .8, "model" to "abakascan-resnet18-v3").also { report = it }
    }
    fun classify(bytes: ByteArray): Pair<Map<String, Any>, ByteArray> {
        if (!validated) selfTest()
        val rgb = prepare(bytes)
        val tensor = PillowResize.normalize(rgb)
        val materialScores = scores(material!!, tensor)
        if (materialScores[1] < .8f) return Pair(mapOf(
            "predicted_grade" to "", "confidence" to 0.0,
            "saved_to_history" to false, "detection_status" to "unidentified_object",
            "detection_message" to "Material not identified with sufficient confidence. Please upload a clear image of one abaca bundle."
        ), ByteArray(0))
        val gradeScores = scores(grader!!, tensor)
        val winner = gradeScores.indices.maxByOrNull { gradeScores[it] }!!
        val pixels = IntArray(224 * 224) { p -> (255 shl 24) or ((rgb[p*3].toInt() and 255) shl 16) or ((rgb[p*3+1].toInt() and 255) shl 8) or (rgb[p*3+2].toInt() and 255) }
        val thumbnailBitmap = Bitmap.createBitmap(pixels,224,224,Bitmap.Config.ARGB_8888)
        val thumb = ByteArrayOutputStream().use { output -> thumbnailBitmap.compress(Bitmap.CompressFormat.JPEG, 85, output); output.toByteArray() }
        thumbnailBitmap.recycle()
        return Pair(mapOf("predicted_grade" to grades[winner], "confidence" to gradeScores[winner].toDouble(),
            "grade_scores" to grades.indices.associate { grades[it] to gradeScores[it].toDouble() },
            "model_name" to "abakascan-resnet18-v3", "saved_to_history" to true, "detection_status" to "graded"), thumb)
    }
    override fun close() { material?.close(); grader?.close(); options.close() }
}
