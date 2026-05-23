package com.chinesecheckers.navigation

import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.chinesecheckers.ChineseCheckersApp
import com.chinesecheckers.data.entities.Profile
import com.chinesecheckers.ui.screens.*
import com.chinesecheckers.viewmodel.GameViewModel
import com.chinesecheckers.viewmodel.MenuViewModel
import com.chinesecheckers.viewmodel.ProfileViewModel

private sealed class Route(val path: String) {
    object Menu : Route("menu")
    object Profiles : Route("profiles")
    object Leaderboard : Route("leaderboard")
    object Game : Route("game/{p1Id}/{p2Id}") {
        fun build(p1Id: Long, p2Id: Long) = "game/$p1Id/$p2Id"
    }
}

@Composable
fun AppNavigation() {
    val context = LocalContext.current
    val app = context.applicationContext as ChineseCheckersApp
    val repository = app.repository

    val navController = rememberNavController()

    val menuVm: MenuViewModel = viewModel(factory = MenuViewModel.Factory(repository))
    val profileVm: ProfileViewModel = viewModel(factory = ProfileViewModel.Factory(repository))

    NavHost(navController = navController, startDestination = Route.Menu.path) {

        composable(Route.Menu.path) {
            MenuScreen(
                viewModel = menuVm,
                onPlay = { p1Id, p2Id ->
                    navController.navigate(Route.Game.build(p1Id, p2Id))
                },
                onManageProfiles = { navController.navigate(Route.Profiles.path) },
                onLeaderboard = { navController.navigate(Route.Leaderboard.path) }
            )
        }

        composable(Route.Profiles.path) {
            ProfileScreen(
                menuViewModel = menuVm,
                profileViewModel = profileVm,
                onBack = { navController.popBackStack() }
            )
        }

        composable(Route.Leaderboard.path) {
            LeaderboardScreen(
                viewModel = menuVm,
                onBack = { navController.popBackStack() }
            )
        }

        composable(
            route = Route.Game.path,
            arguments = listOf(
                navArgument("p1Id") { type = NavType.LongType },
                navArgument("p2Id") { type = NavType.LongType }
            )
        ) { backStack ->
            val p1Id = backStack.arguments!!.getLong("p1Id")
            val p2Id = backStack.arguments!!.getLong("p2Id")

            var p1 by remember { mutableStateOf<Profile?>(null) }
            var p2 by remember { mutableStateOf<Profile?>(null) }

            LaunchedEffect(p1Id, p2Id) {
                p1 = repository.getProfileById(p1Id)
                p2 = repository.getProfileById(p2Id)
            }

            if (p1 != null && p2 != null) {
                val gameVm: GameViewModel = viewModel(
                    key = "game_${p1Id}_${p2Id}",
                    factory = GameViewModel.Factory(repository, p1!!, p2!!)
                )
                GameScreen(
                    viewModel = gameVm,
                    onBack = { navController.popBackStack() }
                )
            }
        }
    }
}
