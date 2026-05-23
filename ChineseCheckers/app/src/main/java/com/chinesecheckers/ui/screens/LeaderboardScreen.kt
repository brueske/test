package com.chinesecheckers.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.chinesecheckers.ui.components.AvatarView
import com.chinesecheckers.ui.theme.Black
import com.chinesecheckers.ui.theme.LightGray
import com.chinesecheckers.ui.theme.White
import com.chinesecheckers.viewmodel.MenuViewModel

@Composable
fun LeaderboardScreen(
    viewModel: MenuViewModel,
    onBack: () -> Unit
) {
    val profiles by viewModel.profiles.collectAsStateWithLifecycle()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(White)
            .systemBarsPadding()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextButton(onClick = onBack) {
                Text("Back", color = Black, fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.weight(1f))
            Text("Leaderboard", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Black)
            Spacer(Modifier.weight(1f))
            Spacer(Modifier.width(64.dp))
        }

        HorizontalDivider(color = Black, thickness = 1.dp)

        // Header row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(Black)
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("#", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = White, modifier = Modifier.width(28.dp))
            Text("Player", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = White, modifier = Modifier.weight(1f))
            Text("Wins", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = White)
        }

        if (profiles.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("No profiles yet.", color = Black)
            }
        } else {
            LazyColumn(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                itemsIndexed(profiles) { index, profile ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .border(1.dp, if (index == 0) Black else LightGray, RoundedCornerShape(6.dp))
                            .background(
                                if (index == 0) LightGray else White,
                                RoundedCornerShape(6.dp)
                            )
                            .padding(horizontal = 12.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Rank
                        Text(
                            "#${index + 1}",
                            fontSize = 14.sp,
                            fontWeight = if (index == 0) FontWeight.Bold else FontWeight.Normal,
                            color = Black,
                            modifier = Modifier.width(28.dp)
                        )
                        AvatarView(avatarType = profile.avatarType, size = 36.dp)
                        Spacer(Modifier.width(10.dp))
                        Text(
                            profile.name,
                            fontSize = 15.sp,
                            fontWeight = if (index == 0) FontWeight.Bold else FontWeight.Normal,
                            color = Black,
                            modifier = Modifier.weight(1f)
                        )
                        Text(
                            "${profile.wins}",
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            color = Black
                        )
                    }
                }
            }
        }
    }
}
