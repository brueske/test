import SwiftUI

struct ScoreboardView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                if store.gameHistory.isEmpty {
                    VStack(spacing: 12) {
                        Text("🏆").font(.system(size: 44))
                        Text("No games recorded yet.")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(Array(store.gameHistory.enumerated()), id: \.element.id) { idx, record in
                                ScoreboardRow(index: idx + 1, record: record)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Scoreboard")
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

private struct ScoreboardRow: View {
    let index:  Int
    let record: GameRecord

    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.boardLine)
                .frame(width: 24)

            Text(record.winnerEmoji)
                .font(.system(size: 28))
                .frame(width: 44, height: 44)
                .background(Color.hole, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(record.winnerName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textMain)
                Text(Self.fmt.string(from: record.date))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(record.moves)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.moveHint)
                Text("moves")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.boardLine.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}
