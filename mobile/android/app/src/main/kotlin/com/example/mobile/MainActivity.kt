package com.example.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

class MainActivity : FlutterActivity() {
    // Forzar renderizado OpenGL en lugar de Vulkan/Impeller
    override fun getRenderMode() = io.flutter.embedding.android.RenderMode.surface
}
