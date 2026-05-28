import SwiftUI

// File-level so PlayerNameField (a separate struct) can reference it
private enum MenuField { case p1, p2 }

struct MenuView: View {
    @Binding var p1Name: String
    @Binding var p2Name: String
    let onPlay: () -> Void

    @State private var showLeaderboard = false
    @FocusState private var focus: MenuField?

    private var canPlay: Bool {
        !p1Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !p2Name.trimmingCharacters(in: .whitespaces).isEmpty &&
        p1Name.trimmingCharacters(in: .whitespaces).lowercased() !=
        p2Name.trimmingCharacters(in: .whitespaces).lowercased()
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Spacer().frame(height: 60)
                    Text("Chinese")
                        .font(.system(size: 38, weight: .black))
                        .foregroundColor(.textMain)
                    Text("Checkers")
                        .font(.system(size: 38, weight: .black))
                        .foregroundColor(.moveHint)

                    HStack(spacing: 8) {
                        Circle().fill(Color.p1).frame(width: 14, height: 14)
                        Circle().fill(Color.p2).frame(width: 14, height: 14)
                    }
                    .padding(.top, 4)
                }

                Spacer()

                // Player inputs
                VStack(spacing: 16) {
                    PlayerNameField(
                        label: "Player 1",
                        color: .p1,
                        text: $p1Name,
                        focusField: $focus,
                        field: .p1,
                        nextField: .p2
                    )

                    PlayerNameField(
                        label: "Player 2",
                        color: .p2,
                        text: $p2Name,
                        focusField: $focus,
                        field: .p2,
                        nextField: nil
                    )
                }
                .padding(.horizontal, 28)

                Spacer()

                // Play button
                Button(action: { focus = nil; onPlay() }) {
                    Text("Play")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            canPlay
                                ? LinearGradient(colors: [.p1, .moveHint], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [.boardLine, .boardLine], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }
                .disabled(!canPlay)
                .padding(.horizontal, 28)

                Button("Leaderboard") { showLeaderboard = true }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.moveHint)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView()
        }
        .onTapGesture { focus = nil }
    }
}

private struct PlayerNameField: View {
    let label: String
    let color: Color
    @Binding var text: String
    var focusField: FocusState<MenuField?>.Binding
    let field: MenuField
    let nextField: MenuField?

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(color).frame(width: 10, height: 10)
            TextField(label, text: $text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.textMain)
                .focused(focusField, equals: field)
                .submitLabel(nextField != nil ? .next : .done)
                .onSubmit {
                    if let next = nextField { focusField.wrappedValue = next }
                    else { focusField.wrappedValue = nil }
                }
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: color.opacity(0.15), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(focusField.wrappedValue == field ? color : Color.boardLine, lineWidth: 1.5)
        )
    }
}
