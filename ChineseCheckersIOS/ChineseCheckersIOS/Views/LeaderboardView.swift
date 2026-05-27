import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                if store.sorted.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy")
                            .font(.system(size: 44))
                            .foregroundColor(.boardLine)
                        Text("No games played yet.")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(store.sorted.enumerated()), id: \.element.id) { rank, profile in
                                LeaderboardRow(rank: rank + 1, profile: profile)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.moveHint)
                }
            }
        }
    }
}

private struct LeaderboardRow: View {
    let rank: Int
    let profile: PlayerProfile

    private var rankColor: Color {
        switch rank {
        case 1: return .p1
        case 2: return .p2
        default: return .boardLine
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rank badge
            ZStack {
                Circle().fill(rankColor.opacity(rank <= 2 ? 0.15 : 0.08))
                    .frame(width: 36, height: 36)
                Text("#\(rank)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(rank <= 2 ? rankColor : .textMain)
            }

            Text(profile.name)
                .font(.system(size: 17, weight: rank == 1 ? .bold : .medium))
                .foregroundColor(.textMain)

            Spacer()

            HStack(spacing: 4) {
                Text("\(profile.wins)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(rank <= 2 ? rankColor : .textMain)
                Text(profile.wins == 1 ? "win" : "wins")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: rankColor.opacity(rank <= 2 ? 0.12 : 0.04), radius: 4, x: 0, y: 2)
    }
}
