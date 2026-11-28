package com.example.abakascan

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONObject
import java.io.File
import java.util.UUID

class OfflineStore(private val context: Context) : SQLiteOpenHelper(context, "abakascan_local_v1.db", null, 1) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""CREATE TABLE records(id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner TEXT NOT NULL, grade TEXT NOT NULL, confidence REAL NOT NULL,
            scores TEXT NOT NULL, model TEXT NOT NULL, created TEXT NOT NULL,
            image_file TEXT NOT NULL, thumbnail BLOB NOT NULL)""")
        db.execSQL("CREATE INDEX records_owner_id ON records(owner,id)")
    }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        error("Unsupported local database upgrade; keep the existing data intact.")
    }
    private fun imageDir() = File(context.noBackupFilesDir,"analysis_images").apply { mkdirs() }
    private fun number(owner: String, id: Long): Int = readableDatabase.rawQuery(
        "SELECT COUNT(*) FROM records WHERE owner=? AND id<=?",arrayOf(owner,id.toString())).use { c -> c.moveToFirst();c.getInt(0) }
    private fun map(c: Cursor, number: Int): Map<String, Any> {
        val id = c.getLong(c.getColumnIndexOrThrow("id"))
        val scores = JSONObject(c.getString(c.getColumnIndexOrThrow("scores")))
        return mapOf("classification_id" to "local-$id", "analysis_number" to number,
            "predicted_grade" to c.getString(c.getColumnIndexOrThrow("grade")),
            "confidence" to c.getDouble(c.getColumnIndexOrThrow("confidence")),
            "grade_scores" to mapOf("JK" to scores.getDouble("JK"), "S-I" to scores.getDouble("S-I"), "S-S2" to scores.getDouble("S-S2")),
            "model_name" to c.getString(c.getColumnIndexOrThrow("model")),
            "created_at" to c.getString(c.getColumnIndexOrThrow("created")),
            "image_url" to "abakascan-local:local-$id", "saved_to_history" to true)
    }
    private fun id(value: String): Long = value.removePrefix("local-").toLongOrNull()?.takeIf { it > 0 }
        ?: throw IllegalArgumentException("Invalid saved analysis.")
    fun save(owner: String, result: Map<String, Any>, bytes: ByteArray, thumb: ByteArray): Map<String, Any> {
        val file = File(imageDir(),UUID.randomUUID().toString()+".image")
        try {
            file.writeBytes(bytes)
            val values = ContentValues().apply {
                put("owner",owner);put("grade",result["predicted_grade"] as String)
                put("confidence",(result["confidence"] as Number).toDouble())
                put("scores",JSONObject(result["grade_scores"] as Map<*,*>).toString())
                put("model",result["model_name"] as String)
                put("created", java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",java.util.Locale.US).apply { timeZone=java.util.TimeZone.getTimeZone("UTC") }.format(java.util.Date()))
                put("image_file",file.name);put("thumbnail",thumb)
            }
            val id = writableDatabase.insertOrThrow("records",null,values)
            return get(owner,"local-$id")
        } catch (e: Exception) { file.delete(); throw e }
    }
    fun history(owner: String): List<Map<String, Any>> = readableDatabase.query("records",
        arrayOf("id","grade","confidence","scores","model","created"),"owner=?",arrayOf(owner),null,null,"id DESC").use { c ->
        val result = ArrayList<Map<String,Any>>()
        var number = c.count
        while (c.moveToNext()) result.add(map(c,number--))
        result
    }
    fun get(owner: String, value: String): Map<String, Any> {
        val id = id(value)
        return readableDatabase.query("records",arrayOf("id","grade","confidence","scores","model","created"),"owner=? AND id=?",arrayOf(owner,id.toString()),null,null,null).use { c ->
            require(c.moveToFirst()) { "Saved analysis not found for this account." }; map(c,number(owner,id))
        }
    }
    fun image(owner: String, value: String, full: Boolean): ByteArray = readableDatabase.query("records",arrayOf("image_file","thumbnail"),
        "owner=? AND id=?",arrayOf(owner,id(value).toString()),null,null,null).use { c ->
        require(c.moveToFirst()) { "Saved image not found for this account." }
        if (full) File(imageDir(),c.getString(0)).readBytes() else c.getBlob(1)
    }
    fun delete(owner: String, value: String) {
        val id = id(value)
        val filename = readableDatabase.query("records",arrayOf("image_file"),"owner=? AND id=?",arrayOf(owner,id.toString()),null,null,null).use { c ->
            require(c.moveToFirst()) { "Saved analysis not found for this account." };c.getString(0)
        }
        check(writableDatabase.delete("records","owner=? AND id=?",arrayOf(owner,id.toString()))==1)
        File(imageDir(),filename).delete()
    }
}
