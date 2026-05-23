package com.chinesecheckers.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.chinesecheckers.data.entities.Profile
import com.chinesecheckers.ui.theme.Black
import com.chinesecheckers.ui.theme.LightGray
import com.chinesecheckers.ui.theme.White

@Composable
fun VictoryGraph(profiles: List<Profile>, modifier: Modifier = Modifier) {
    val measurer = rememberTextMeasurer()

    Canvas(modifier = modifier.fillMaxWidth().height(120.dp)) {
        if (profiles.isEmpty()) {
            drawNoDataLabel(measurer)
            return@Canvas
        }

        val padL = 32f
        val padR = 16f
        val padTop = 12f
        val padBot = 36f

        val chartW = size.width - padL - padR
        val chartH = size.height - padTop - padBot
        val baseline = size.height - padBot

        // Axes
        drawLine(Black, Offset(padL, padTop), Offset(padL, baseline), strokeWidth = 2f)
        drawLine(Black, Offset(padL, baseline), Offset(size.width - padR, baseline), strokeWidth = 2f)

        val maxWins = profiles.maxOf { it.wins }.coerceAtLeast(1)
        val barCount = profiles.size.coerceAtMost(6) // show up to 6 profiles
        val barTotalW = chartW / barCount
        val barW = barTotalW * 0.55f

        for (i in 0 until barCount) {
            val p = profiles[i]
            val barH = chartH * p.wins.toFloat() / maxWins
            val barX = padL + i * barTotalW + (barTotalW - barW) * 0.5f
            val barY = baseline - barH

            // Bar fill
            drawRect(Black, Offset(barX, barY), Size(barW, barH))

            // Win count label above bar
            val countText = measurer.measure(
                "${p.wins}",
                TextStyle(fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Black)
            )
            drawText(
                countText,
                topLeft = Offset(barX + (barW - countText.size.width) * 0.5f, (barY - countText.size.height - 2f).coerceAtLeast(0f))
            )

            // Name label below axis
            val nameText = measurer.measure(
                p.name.take(6),
                TextStyle(fontSize = 9.sp, color = Black)
            )
            drawText(
                nameText,
                topLeft = Offset(barX + (barW - nameText.size.width) * 0.5f, baseline + 4f)
            )
        }

        // Y-axis max label
        val maxLabel = measurer.measure(
            "$maxWins",
            TextStyle(fontSize = 9.sp, color = Black)
        )
        drawText(maxLabel, topLeft = Offset(2f, padTop))
    }
}

private fun DrawScope.drawNoDataLabel(measurer: TextMeasurer) {
    val text = measurer.measure(
        "No profiles yet",
        TextStyle(fontSize = 12.sp, color = Black)
    )
    drawText(text, topLeft = Offset((size.width - text.size.width) * 0.5f, (size.height - text.size.height) * 0.5f))
}
