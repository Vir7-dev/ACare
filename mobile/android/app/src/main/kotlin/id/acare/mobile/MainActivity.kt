package id.acare.mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        buatKanalNotifikasi()
    }

    /**
     * Kanal untuk notifikasi pesanan (tawaran, status, pembayaran) dengan
     * prioritas tinggi supaya muncul sebagai pop-up. ID harus sama dengan
     * Fcm::KANAL_ANDROID di backend.
     */
    private fun buatKanalNotifikasi() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val kanal = NotificationChannel(
            "acare_pesanan",
            "Pesanan",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply { description = "Tawaran pesanan, status pengerjaan, dan pembayaran" }
        getSystemService(NotificationManager::class.java).createNotificationChannel(kanal)
    }
}
