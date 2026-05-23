package com.chinesecheckers.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.chinesecheckers.ui.theme.Black
import com.chinesecheckers.ui.theme.White

enum class AvatarType(val label: String) {
    CAT("Cat"),
    BEAR("Bear"),
    ROBOT("Robot"),
    ALIEN("Alien"),
    BUNNY("Bunny"),
    FOX("Fox"),
    PANDA("Panda"),
    GHOST("Ghost")
}

@Composable
fun AvatarView(
    avatarType: Int,
    size: Dp = 48.dp,
    selected: Boolean = false,
    onClick: (() -> Unit)? = null
) {
    val type = AvatarType.entries.getOrElse(avatarType) { AvatarType.CAT }
    val borderWidth = if (selected) 3.dp else 1.dp

    Canvas(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .border(borderWidth, Black, CircleShape)
            .then(if (onClick != null) Modifier.clickable { onClick() } else Modifier)
    ) {
        drawCircle(color = White)
        drawCircle(color = Black, style = Stroke(width = 2f))
        drawAvatar(type, center, this.size.minDimension * 0.42f)
    }
}

private fun DrawScope.drawAvatar(type: AvatarType, c: Offset, r: Float) {
    when (type) {
        AvatarType.CAT -> drawCat(c, r)
        AvatarType.BEAR -> drawBear(c, r)
        AvatarType.ROBOT -> drawRobot(c, r)
        AvatarType.ALIEN -> drawAlien(c, r)
        AvatarType.BUNNY -> drawBunny(c, r)
        AvatarType.FOX -> drawFox(c, r)
        AvatarType.PANDA -> drawPanda(c, r)
        AvatarType.GHOST -> drawGhost(c, r)
    }
}

// --- Cat ---
private fun DrawScope.drawCat(c: Offset, r: Float) {
    val stroke = Stroke(width = r * 0.07f, cap = StrokeCap.Round)
    // Head outline
    drawCircle(Black, r, c, style = stroke)
    // Ears (triangles)
    val earW = r * 0.35f
    val earH = r * 0.4f
    drawPath(trianglePath(Offset(c.x - r * 0.55f, c.y - r * 0.6f), earW, earH), Black)
    drawPath(trianglePath(Offset(c.x + r * 0.55f, c.y - r * 0.6f), earW, earH), Black)
    // Eyes
    drawCircle(Black, r * 0.1f, Offset(c.x - r * 0.3f, c.y - r * 0.1f))
    drawCircle(Black, r * 0.1f, Offset(c.x + r * 0.3f, c.y - r * 0.1f))
    // Nose
    drawCircle(Black, r * 0.07f, Offset(c.x, c.y + r * 0.1f))
    // Whiskers
    drawLine(Black, Offset(c.x - r * 0.7f, c.y + r * 0.05f), Offset(c.x - r * 0.15f, c.y + r * 0.1f), r * 0.04f)
    drawLine(Black, Offset(c.x + r * 0.7f, c.y + r * 0.05f), Offset(c.x + r * 0.15f, c.y + r * 0.1f), r * 0.04f)
    drawLine(Black, Offset(c.x - r * 0.7f, c.y + r * 0.18f), Offset(c.x - r * 0.15f, c.y + r * 0.18f), r * 0.04f)
    drawLine(Black, Offset(c.x + r * 0.7f, c.y + r * 0.18f), Offset(c.x + r * 0.15f, c.y + r * 0.18f), r * 0.04f)
    // Mouth smile arc
    drawArc(Black, 0f, 180f, false,
        topLeft = Offset(c.x - r * 0.15f, c.y + r * 0.1f),
        size = Size(r * 0.3f, r * 0.2f),
        style = stroke
    )
}

// --- Bear ---
private fun DrawScope.drawBear(c: Offset, r: Float) {
    val stroke = Stroke(width = r * 0.07f, cap = StrokeCap.Round)
    drawCircle(Black, r, c, style = stroke)
    // Round ears
    drawCircle(White, r * 0.28f, Offset(c.x - r * 0.65f, c.y - r * 0.7f))
    drawCircle(Black, r * 0.28f, Offset(c.x - r * 0.65f, c.y - r * 0.7f), style = stroke)
    drawCircle(White, r * 0.28f, Offset(c.x + r * 0.65f, c.y - r * 0.7f))
    drawCircle(Black, r * 0.28f, Offset(c.x + r * 0.65f, c.y - r * 0.7f), style = stroke)
    // Muzzle
    drawCircle(White, r * 0.35f, Offset(c.x, c.y + r * 0.2f))
    drawCircle(Black, r * 0.35f, Offset(c.x, c.y + r * 0.2f), style = stroke)
    // Eyes
    drawCircle(Black, r * 0.1f, Offset(c.x - r * 0.3f, c.y - r * 0.1f))
    drawCircle(Black, r * 0.1f, Offset(c.x + r * 0.3f, c.y - r * 0.1f))
    // Nose
    drawCircle(Black, r * 0.08f, Offset(c.x, c.y + r * 0.1f))
}

// --- Robot ---
private fun DrawScope.drawRobot(c: Offset, r: Float) {
    val stroke = Stroke(width = r * 0.07f)
    // Square head
    drawRect(White, Offset(c.x - r * 0.75f, c.y - r * 0.7f), Size(r * 1.5f, r * 1.4f))
    drawRect(Black, Offset(c.x - r * 0.75f, c.y - r * 0.7f), Size(r * 1.5f, r * 1.4f), style = stroke)
    // Antenna
    drawLine(Black, Offset(c.x, c.y - r * 0.7f), Offset(c.x, c.y - r * 1.1f), r * 0.06f)
    drawCircle(Black, r * 0.1f, Offset(c.x, c.y - r * 1.1f))
    // Eyes (squares)
    drawRect(Black, Offset(c.x - r * 0.52f, c.y - r * 0.4f), Size(r * 0.28f, r * 0.28f))
    drawRect(Black, Offset(c.x + r * 0.24f, c.y - r * 0.4f), Size(r * 0.28f, r * 0.28f))
    // Mouth (grid of dots)
    for (i in 0..2) {
        drawCircle(Black, r * 0.06f, Offset(c.x - r * 0.25f + i * r * 0.25f, c.y + r * 0.3f))
    }
}

// --- Alien ---
private fun DrawScope.drawAlien(c: Offset, r: Float) {
    val stroke = Stroke(width = r * 0.07f, cap = StrokeCap.Round)
    // Oval head
    drawOval(White, Offset(c.x - r * 0.7f, c.y - r), Size(r * 1.4f, r * 1.8f))
    drawOval(Black, Offset(c.x - r * 0.7f, c.y - r), Size(r * 1.4f, r * 1.8f), style = stroke)
    // Large eyes
    drawOval(Black, Offset(c.x - r * 0.55f, c.y - r * 0.5f), Size(r * 0.45f, r * 0.3f))
    drawOval(Black, Offset(c.x + r * 0.1f, c.y - r * 0.5f), Size(r * 0.45f, r * 0.3f))
    // White glints in eyes
    drawCircle(White, r * 0.08f, Offset(c.x - r * 0.38f, c.y - r * 0.42f))
    drawCircle(White, r * 0.08f, Offset(c.x + r * 0.27f, c.y - r * 0.42f))
    // Smile
    drawArc(Black, 0f, 180f, false,
        topLeft = Offset(c.x - r * 0.25f, c.y + r * 0.05f),
        size = Size(r * 0.5f, r * 0.25f),
        style = stroke
    )
}

// --- Bunny ---
private fun DrawScope.drawBunny(c: Offset, r: Float) {
    val stroke = Stroke(width = r * 0.07f, cap = StrokeCap.Round)
    // Long ears (ovals)
    drawOval(White, Offset(c.x - r * 0.55f, c.y - r * 1.5f), Size(r * 0.35f, r * 0.9f))
    drawOval(Black, Offset(c.x - r * 0.55f, c.y - r * 1.5f), Size(r * 0.35f, r * 0.9f), style = stroke)
    drawOval(White, Offset(c.x + r * 0.2f, c.y - r * 1.5f), Size(r * 0.35f, r * 0.9f))
    drawOval(Black, Offset(c.x + r * 0.2f, c.y - r * 1.5f), Size(r * 0.35f, r * 0.9f), style = stroke)
    // Head
    drawCircle(White, r, c)
    drawCircle(Black, r, c, style = stroke)
    // Eyes
    drawCircle(Black, r * 0.1f, Offset(c.x - r * 0.3f, c.y - r * 0.1f))
    drawCircle(Black, r * 0.1f, Offset(c.x + r * 0.3f, c.y - r * 0.1f))
    // Tiny nose
    drawCircle(Black, r * 0.07f, Offset(c.x, c.y + r * 0.15f))
    // Smile
    drawArc(Black, 0f, 180f, false,
        topLeft = Offset(c.x - r * 0.15f, c.y + r * 0.15f),
        size = Size(r * 0.3f, r * 0.18f),
        style = stroke
    )
}

// --- Fox ---
private fun DrawScope.drawFox(c: Offset, r: Float) {
    val stroke = Stroke(width = r * 0.07f, cap = StrokeCap.Round)
    drawCircle(Black, r, c, style = stroke)
    // Pointed ears
    drawPath(trianglePath(Offset(c.x - r * 0.5f, c.y - r * 0.6f), r * 0.4f, r * 0.55f), Black)
    drawPath(trianglePath(Offset(c.x + r * 0.5f, c.y - r * 0.6f), r * 0.4f, r * 0.55f), Black)
    // Muzzle diamond shape
    val muzzle = Path().apply {
        moveTo(c.x, c.y + r * 0.35f)
        lineTo(c.x - r * 0.25f, c.y + r * 0.15f)
        lineTo(c.x, c.y - r * 0.05f)
        lineTo(c.x + r * 0.25f, c.y + r * 0.15f)
        close()
    }
    drawPath(muzzle, White)
    drawPath(muzzle, Black, style = stroke)
    // Eyes
    drawCircle(Black, r * 0.11f, Offset(c.x - r * 0.32f, c.y - r * 0.2f))
    drawCircle(Black, r * 0.11f, Offset(c.x + r * 0.32f, c.y - r * 0.2f))
    // Nose
    drawCircle(Black, r * 0.08f, Offset(c.x, c.y + r * 0.1f))
}

// --- Panda ---
private fun DrawScope.drawPanda(c: Offset, r: Float) {
    val stroke = Stroke(width = r * 0.07f, cap = StrokeCap.Round)
    drawCircle(White, r, c)
    drawCircle(Black, r, c, style = stroke)
    // Round ears (black)
    drawCircle(Black, r * 0.28f, Offset(c.x - r * 0.65f, c.y - r * 0.72f))
    drawCircle(Black, r * 0.28f, Offset(c.x + r * 0.65f, c.y - r * 0.72f))
    // Eye patches (black ovals)
    drawOval(Black, Offset(c.x - r * 0.58f, c.y - r * 0.42f), Size(r * 0.42f, r * 0.32f))
    drawOval(Black, Offset(c.x + r * 0.16f, c.y - r * 0.42f), Size(r * 0.42f, r * 0.32f))
    // White dots in eye patches
    drawCircle(White, r * 0.1f, Offset(c.x - r * 0.4f, c.y - r * 0.3f))
    drawCircle(White, r * 0.1f, Offset(c.x + r * 0.34f, c.y - r * 0.3f))
    // Nose
    drawCircle(Black, r * 0.09f, Offset(c.x, c.y + r * 0.1f))
    // Smile
    drawArc(Black, 0f, 180f, false,
        topLeft = Offset(c.x - r * 0.2f, c.y + r * 0.1f),
        size = Size(r * 0.4f, r * 0.2f),
        style = stroke
    )
}

// --- Ghost ---
private fun DrawScope.drawGhost(c: Offset, r: Float) {
    val stroke = Stroke(width = r * 0.07f, cap = StrokeCap.Round)
    // Ghost body path
    val path = Path().apply {
        val top = Offset(c.x, c.y - r)
        val left = Offset(c.x - r, c.y + r * 0.2f)
        val right = Offset(c.x + r, c.y + r * 0.2f)
        moveTo(left.x, left.y)
        cubicTo(left.x, c.y - r * 1.2f, right.x, c.y - r * 1.2f, right.x, right.y)
        // Wavy bottom
        val waveAmp = r * 0.22f
        val waveStep = r * 2f / 3f
        lineTo(right.x, right.y + r * 0.3f)
        for (i in 2 downTo 0) {
            val wx = left.x + waveStep * i + waveStep * 0.5f
            val wy = right.y + r * 0.3f + (if (i % 2 == 0) -waveAmp else waveAmp)
            lineTo(wx, wy)
        }
        lineTo(left.x, left.y + r * 0.3f)
        close()
    }
    drawPath(path, White)
    drawPath(path, Black, style = stroke)
    // Eyes
    drawCircle(Black, r * 0.13f, Offset(c.x - r * 0.28f, c.y - r * 0.2f))
    drawCircle(Black, r * 0.13f, Offset(c.x + r * 0.28f, c.y - r * 0.2f))
    // Mouth
    drawArc(Black, 0f, 180f, false,
        topLeft = Offset(c.x - r * 0.2f, c.y + r * 0.05f),
        size = Size(r * 0.4f, r * 0.2f),
        style = stroke
    )
}

// Upward-pointing triangle centred at (cx, cy - h/3)
private fun trianglePath(tip: Offset, baseW: Float, height: Float): Path = Path().apply {
    moveTo(tip.x, tip.y - height)
    lineTo(tip.x - baseW / 2f, tip.y)
    lineTo(tip.x + baseW / 2f, tip.y)
    close()
}
