package com.chinesecheckers

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.chinesecheckers.navigation.AppNavigation
import com.chinesecheckers.ui.theme.ChineseCheckersTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            ChineseCheckersTheme {
                AppNavigation()
            }
        }
    }
}
