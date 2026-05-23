package com.chinesecheckers.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.chinesecheckers.ui.components.AvatarView
import com.chinesecheckers.ui.components.BoardView
import com.chinesecheckers.ui.theme.Black
import com.chinesecheckers.ui.theme.LightGray
import com.chinesecheckers.ui.theme.White
import com.chinesecheckers.viewmodel.GameViewModel

@Composable
fun GameScreen(
    viewModel: GameViewModel,
    onBack: () -> Unit
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val p1 = viewModel.player1
    val p2 = viewModel.player2

    // Winner dialog
    if (state.winner != null) {
        val winner = if (state.winner == 1) p1 else p2
        WinnerDialog(
            winnerName = winner.name,
            winnerAvatarType = winner.avatarType,
            onNewGame = { viewModel.newGame() },
            onMenu = onBack
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(White)
            .systemBarsPadding()
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextButton(onClick = onBack) {
                Text("Menu", color = Black, fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.weight(1f))
            Text(
                "Chinese Checkers",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = Black
            )
            Spacer(Modifier.weight(1f))
            // Invisible placeholder to balance the row
            TextButton(onClick = {}, enabled = false) {
                Text("Menu", color = White)
            }
        }

        HorizontalDivider(color = Black, thickness = 1.dp)

        // Turn indicator
        val currentProfile = if (state.currentPlayer == 1) p1 else p2
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(Black)
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            AvatarView(avatarType = currentProfile.avatarType, size = 32.dp)
            Spacer(Modifier.width(10.dp))
            Text(
                text = "${currentProfile.name}'s Turn  •  Player ${state.currentPlayer}",
                color = White,
                fontWeight = FontWeight.SemiBold,
                fontSize = 14.sp
            )
        }

        // Board (takes remaining space)
        BoardView(
            state = state,
            onTap = { viewModel.onTap(it) },
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .padding(8.dp)
        )

        // Bottom controls
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(LightGray)
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Player 1 info
            PlayerIndicator(
                name = p1.name,
                avatarType = p1.avatarType,
                isActive = state.currentPlayer == 1,
                playerNumber = 1
            )

            // Mid-jump end button
            if (state.isJumping) {
                Button(
                    onClick = { viewModel.endJump() },
                    shape = RoundedCornerShape(4.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Black, contentColor = White),
                    modifier = Modifier.padding(horizontal = 8.dp)
                ) {
                    Text("End Jump", fontSize = 12.sp)
                }
            } else {
                Spacer(Modifier.width(96.dp))
            }

            // Player 2 info
            PlayerIndicator(
                name = p2.name,
                avatarType = p2.avatarType,
                isActive = state.currentPlayer == 2,
                playerNumber = 2,
                alignEnd = true
            )
        }
    }
}

@Composable
private fun PlayerIndicator(
    name: String,
    avatarType: Int,
    isActive: Boolean,
    playerNumber: Int,
    alignEnd: Boolean = false
) {
    val arrangement = if (alignEnd) Arrangement.End else Arrangement.Start
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = arrangement,
        modifier = Modifier
            .border(if (isActive) 2.dp else 0.dp, Black, RoundedCornerShape(6.dp))
            .background(if (isActive) LightGray else White, RoundedCornerShape(6.dp))
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        if (alignEnd) {
            Column(horizontalAlignment = Alignment.End) {
                Text(name.take(10), fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = Black)
                Text("P$playerNumber", fontSize = 10.sp, color = Black)
            }
            Spacer(Modifier.width(6.dp))
            AvatarView(avatarType = avatarType, size = 36.dp, selected = isActive)
        } else {
            AvatarView(avatarType = avatarType, size = 36.dp, selected = isActive)
            Spacer(Modifier.width(6.dp))
            Column {
                Text(name.take(10), fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = Black)
                Text("P$playerNumber", fontSize = 10.sp, color = Black)
            }
        }
    }
}

@Composable
private fun WinnerDialog(
    winnerName: String,
    winnerAvatarType: Int,
    onNewGame: () -> Unit,
    onMenu: () -> Unit
) {
    Dialog(onDismissRequest = {}) {
        Column(
            modifier = Modifier
                .background(White)
                .border(2.dp, Black)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                "Victory!",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = Black
            )
            Spacer(Modifier.height(16.dp))
            AvatarView(avatarType = winnerAvatarType, size = 72.dp)
            Spacer(Modifier.height(12.dp))
            Text(
                "$winnerName wins!",
                fontSize = 18.sp,
                fontWeight = FontWeight.SemiBold,
                color = Black
            )
            Spacer(Modifier.height(24.dp))
            Button(
                onClick = onNewGame,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(4.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Black, contentColor = White)
            ) {
                Text("Play Again", fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.height(8.dp))
            OutlinedButton(
                onClick = onMenu,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(4.dp),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Black),
                border = BorderStroke(1.dp, Black)
            ) {
                Text("Main Menu")
            }
        }
    }
}
