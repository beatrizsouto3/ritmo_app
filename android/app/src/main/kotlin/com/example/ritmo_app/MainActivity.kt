package com.example.ritmo_app

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.ritmo_app/session"
    private val storageName = "ritmo_session"
    private val sessionKey = "session"
    private val keyAlias = "ritmo_session_key"
    private val oauthChannelName = "com.example.ritmo_app/oauth"
    private val oauthScheme = "br.ufrn.ritmo"
    private val oauthHost = "login-callback"
    private var pendingOAuth: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, oauthChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "authenticate" -> startOAuth(call.arguments as? String, result)
                    "cancel" -> {
                        pendingOAuth?.error("OAUTH_CANCELED", "OAuth canceled", null)
                        pendingOAuth = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "read" -> result.success(readSession())
                        "write" -> {
                            val value = call.arguments as? String
                                ?: throw IllegalArgumentException("Invalid session value")
                            writeSession(value)
                            result.success(null)
                        }
                        "clear" -> {
                            clearSession()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    result.error("SESSION_STORAGE_ERROR", "Cannot access saved session", null)
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val data = intent.data ?: return
        if (data.scheme != oauthScheme || data.host != oauthHost) return
        // Link sem tentativa ativa (ex.: após cancelar) é ignorado.
        pendingOAuth?.success(data.toString())
        pendingOAuth = null
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        pendingOAuth = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun startOAuth(url: String?, result: MethodChannel.Result) {
        if (url == null) {
            result.error("OAUTH_INVALID_URL", "Invalid authorize URL", null)
            return
        }
        if (pendingOAuth != null) {
            result.error("OAUTH_IN_PROGRESS", "OAuth already in progress", null)
            return
        }
        try {
            startActivity(
                Intent(Intent.ACTION_VIEW, Uri.parse(url))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            pendingOAuth = result
        } catch (_: ActivityNotFoundException) {
            result.error("BROWSER_NOT_FOUND", "No browser available", null)
        }
    }

    private fun readSession(): String? {
        val saved = getSharedPreferences(storageName, Context.MODE_PRIVATE)
            .getString(sessionKey, null) ?: return null
        val parts = saved.split(':', limit = 2)
        require(parts.size == 2)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(
            Cipher.DECRYPT_MODE,
            getKey(),
            GCMParameterSpec(128, Base64.decode(parts[0], Base64.NO_WRAP)),
        )
        return String(cipher.doFinal(Base64.decode(parts[1], Base64.NO_WRAP)), Charsets.UTF_8)
    }

    private fun writeSession(value: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getKey())
        val saved = Base64.encodeToString(cipher.iv, Base64.NO_WRAP) + ":" +
            Base64.encodeToString(
                cipher.doFinal(value.toByteArray(Charsets.UTF_8)),
                Base64.NO_WRAP,
            )
        val written = getSharedPreferences(storageName, Context.MODE_PRIVATE)
            .edit().putString(sessionKey, saved).commit()
        if (!written) throw IOException("Cannot save session")
    }

    private fun clearSession() {
        val cleared = getSharedPreferences(storageName, Context.MODE_PRIVATE)
            .edit().remove(sessionKey).commit()
        if (!cleared) throw IOException("Cannot clear session")
    }

    private fun getKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = keyStore.getKey(keyAlias, null) as? SecretKey
        if (existing != null) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }
}
