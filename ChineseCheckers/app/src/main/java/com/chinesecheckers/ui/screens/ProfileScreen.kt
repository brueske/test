package com.chinesecheckers.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.chinesecheckers.data.entities.Profile
import com.chinesecheckers.ui.components.AvatarType
import com.chinesecheckers.ui.components.AvatarView
import com.chinesecheckers.ui.theme.Black
import com.chinesecheckers.ui.theme.LightGray
import com.chinesecheckers.ui.theme.White
import com.chinesecheckers.viewmodel.MenuViewModel
import com.chinesecheckers.viewmodel.ProfileViewModel

@Composable
fun ProfileScreen(
    menuViewModel: MenuViewModel,
    profileViewModel: ProfileViewModel,
    onBack: () -> Unit
) {
    val profiles by menuViewModel.profiles.collectAsStateWithLifecycle()
    var editingProfile by remember { mutableStateOf<Profile?>(null) }
    var showNewForm by remember { mutableStateOf(false) }

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
                Text("Back", color = Black, fontWeight = FontWeight.SemiBold)
            }
            Spacer(Modifier.weight(1f))
            Text("Profiles", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Black)
            Spacer(Modifier.weight(1f))
            TextButton(onClick = { showNewForm = true; editingProfile = null }) {
                Text("+ New", color = Black, fontWeight = FontWeight.SemiBold)
            }
        }

        HorizontalDivider(color = Black, thickness = 1.dp)

        if (showNewForm || editingProfile != null) {
            ProfileForm(
                initial = editingProfile,
                onSave = { profile ->
                    profileViewModel.save(profile)
                    editingProfile = null
                    showNewForm = false
                },
                onCancel = { editingProfile = null; showNewForm = false }
            )
            HorizontalDivider(color = Black, thickness = 1.dp)
        }

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            items(profiles) { profile ->
                ProfileRow(
                    profile = profile,
                    onEdit = { editingProfile = it; showNewForm = false },
                    onDelete = { profileViewModel.delete(it) }
                )
            }
        }
    }
}

@Composable
private fun ProfileForm(
    initial: Profile?,
    onSave: (Profile) -> Unit,
    onCancel: () -> Unit
) {
    var name by remember(initial) { mutableStateOf(initial?.name ?: "") }
    var avatarType by remember(initial) { mutableStateOf(initial?.avatarType ?: 0) }
    val keyboard = LocalSoftwareKeyboardController.current

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        Text(
            if (initial == null) "New Profile" else "Edit Profile",
            fontSize = 15.sp,
            fontWeight = FontWeight.Bold,
            color = Black
        )
        Spacer(Modifier.height(12.dp))

        OutlinedTextField(
            value = name,
            onValueChange = { if (it.length <= 16) name = it },
            label = { Text("Name") },
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
            keyboardActions = KeyboardActions(onDone = { keyboard?.hide() }),
            modifier = Modifier.fillMaxWidth(),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Black,
                unfocusedBorderColor = Black,
                cursorColor = Black,
                focusedLabelColor = Black,
                unfocusedLabelColor = Black
            )
        )

        Spacer(Modifier.height(12.dp))
        Text("Choose Avatar", fontSize = 13.sp, color = Black)
        Spacer(Modifier.height(8.dp))

        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            itemsIndexed(AvatarType.entries) { idx, type ->
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier
                        .clip(RoundedCornerShape(6.dp))
                        .clickable { avatarType = idx }
                        .background(if (avatarType == idx) LightGray else White)
                        .border(if (avatarType == idx) 2.dp else 1.dp, Black, RoundedCornerShape(6.dp))
                        .padding(6.dp)
                ) {
                    AvatarView(avatarType = idx, size = 44.dp, selected = avatarType == idx)
                    Spacer(Modifier.height(3.dp))
                    Text(type.label, fontSize = 9.sp, color = Black)
                }
            }
        }

        Spacer(Modifier.height(16.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedButton(
                onClick = onCancel,
                shape = RoundedCornerShape(4.dp),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Black),
                border = BorderStroke(1.dp, Black),
                modifier = Modifier.weight(1f)
            ) {
                Text("Cancel")
            }
            Button(
                onClick = {
                    if (name.isNotBlank()) {
                        onSave(
                            (initial ?: Profile(name = "", avatarType = 0))
                                .copy(name = name.trim(), avatarType = avatarType)
                        )
                    }
                },
                enabled = name.isNotBlank(),
                shape = RoundedCornerShape(4.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Black, contentColor = White),
                modifier = Modifier.weight(1f)
            ) {
                Text("Save", fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun ProfileRow(
    profile: Profile,
    onEdit: (Profile) -> Unit,
    onDelete: (Profile) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, Black, RoundedCornerShape(6.dp))
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        AvatarView(avatarType = profile.avatarType, size = 44.dp)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(profile.name, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Black)
            Text("Wins: ${profile.wins}", fontSize = 12.sp, color = Black)
        }
        TextButton(onClick = { onEdit(profile) }) {
            Text("Edit", color = Black)
        }
        TextButton(onClick = { onDelete(profile) }) {
            Text("Delete", color = Black)
        }
    }
}
