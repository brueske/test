package com.chinesecheckers.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.chinesecheckers.data.entities.Profile
import com.chinesecheckers.ui.components.AvatarView
import com.chinesecheckers.ui.components.VictoryGraph
import com.chinesecheckers.ui.theme.Black
import com.chinesecheckers.ui.theme.LightGray
import com.chinesecheckers.ui.theme.White
import com.chinesecheckers.viewmodel.MenuViewModel

@Composable
fun MenuScreen(
    viewModel: MenuViewModel,
    onPlay: (player1Id: Long, player2Id: Long) -> Unit,
    onManageProfiles: () -> Unit,
    onLeaderboard: () -> Unit
) {
    val profiles by viewModel.profiles.collectAsStateWithLifecycle()

    var p1Id by remember { mutableStateOf<Long?>(null) }
    var p2Id by remember { mutableStateOf<Long?>(null) }

    // Auto-select first two profiles when list loads
    LaunchedEffect(profiles) {
        if (profiles.size >= 1 && p1Id == null) p1Id = profiles[0].id
        if (profiles.size >= 2 && p2Id == null) p2Id = profiles[1].id
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(White)
            .systemBarsPadding()
            .padding(horizontal = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(24.dp))

        Text(
            "Chinese Checkers",
            fontSize = 26.sp,
            fontWeight = FontWeight.Bold,
            color = Black
        )

        Spacer(Modifier.height(6.dp))

        // Action row
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            TextButton(onClick = onManageProfiles) {
                Text("Profiles", color = Black, fontWeight = FontWeight.SemiBold)
            }
            TextButton(onClick = onLeaderboard) {
                Text("Leaderboard", color = Black, fontWeight = FontWeight.SemiBold)
            }
        }

        HorizontalDivider(color = Black, thickness = 1.dp)
        Spacer(Modifier.height(16.dp))

        if (profiles.isEmpty()) {
            Text(
                "Create at least two profiles to play.",
                color = Black,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(vertical = 24.dp)
            )
        } else {
            Text("Player 1", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = Black)
            Spacer(Modifier.height(8.dp))
            PlayerPicker(profiles, p1Id, excludeId = p2Id) { p1Id = it }

            Spacer(Modifier.height(16.dp))

            Text("Player 2", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = Black)
            Spacer(Modifier.height(8.dp))
            PlayerPicker(profiles, p2Id, excludeId = p1Id) { p2Id = it }

            Spacer(Modifier.height(24.dp))

            val canPlay = p1Id != null && p2Id != null && p1Id != p2Id
            Button(
                onClick = { onPlay(p1Id!!, p2Id!!) },
                enabled = canPlay,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(4.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Black,
                    contentColor = White,
                    disabledContainerColor = LightGray,
                    disabledContentColor = Black
                )
            ) {
                Text("Play", fontSize = 18.sp, fontWeight = FontWeight.Bold)
            }
        }

        Spacer(Modifier.weight(1f))

        // Victory graph at bottom
        if (profiles.isNotEmpty()) {
            HorizontalDivider(color = Black, thickness = 1.dp)
            Spacer(Modifier.height(8.dp))
            Text("Victories", fontSize = 12.sp, color = Black, fontWeight = FontWeight.SemiBold)
            VictoryGraph(profiles)
            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
private fun PlayerPicker(
    profiles: List<Profile>,
    selectedId: Long?,
    excludeId: Long?,
    onSelect: (Long) -> Unit
) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        contentPadding = PaddingValues(horizontal = 4.dp)
    ) {
        items(profiles.filter { it.id != excludeId }) { profile ->
            val selected = profile.id == selectedId
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .clip(RoundedCornerShape(8.dp))
                    .clickable { onSelect(profile.id) }
                    .background(if (selected) Black else White)
                    .border(1.dp, Black, RoundedCornerShape(8.dp))
                    .padding(8.dp)
            ) {
                AvatarView(
                    avatarType = profile.avatarType,
                    size = 48.dp,
                    selected = selected
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    profile.name.take(10),
                    fontSize = 11.sp,
                    color = if (selected) White else Black,
                    fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal
                )
            }
        }
    }
}
