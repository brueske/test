import SwiftUI

struct ProfileSheetView: View {
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var audioEngine: AudioEngine
    @ObservedObject var lfoManager: LFOManager
    @Binding var activeProfileID: UUID?
    @Environment(\.dismiss) private var dismiss

    @State private var showSaveField = false
    @State private var newProfileName = ""
    @State private var editingProfile: NoiseProfile? = nil
    @State private var editingName = ""
    @State private var deleteCandidate: NoiseProfile? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("PROFILES")
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(4)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .ultraLight))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)

                Divider().background(Color.white.opacity(0.1))

                // Save new profile
                VStack(alignment: .leading, spacing: 12) {
                    if showSaveField {
                        HStack(spacing: 12) {
                            TextField("", text: $newProfileName)
                                .placeholder(when: newProfileName.isEmpty) {
                                    Text("profile name")
                                        .foregroundColor(.white.opacity(0.3))
                                        .font(.system(size: 13, weight: .light, design: .monospaced))
                                }
                                .font(.system(size: 13, weight: .light, design: .monospaced))
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            Button("SAVE") {
                                guard !newProfileName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                profileManager.save(
                                    name: newProfileName,
                                    bandGains: audioEngine.bandGains,
                                    lfoStates: lfoManager.states
                                )
                                newProfileName = ""
                                showSaveField = false
                            }
                            .font(.system(size: 11, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(2)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 24)
                    } else {
                        Button(action: { showSaveField = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .ultraLight))
                                Text("SAVE CURRENT")
                                    .font(.system(size: 11, weight: .light, design: .monospaced))
                                    .tracking(2)
                            }
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                        }
                    }
                }
                .padding(.top, 8)

                Divider().background(Color.white.opacity(0.1))

                // Profile list with swipe actions and drag reorder
                List {
                    ForEach(profileManager.profiles) { profile in
                        profileRow(profile)
                            .listRowBackground(Color.black)
                            .listRowSeparatorTint(Color.white.opacity(0.05))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteCandidate = profile
                                    showDeleteConfirm = true
                                } label: {
                                    Image(systemName: "trash")
                                }

                                Button {
                                    profileManager.togglePin(id: profile.id)
                                } label: {
                                    Image(systemName: profile.isPinned ? "pin.slash" : "pin")
                                }
                                .tint(Color.white.opacity(0.3))
                            }
                    }
                    .onMove { source, destination in
                        profileManager.move(from: source, to: destination)
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Delete Profile", isPresented: $showDeleteConfirm, presenting: deleteCandidate) { profile in
            Button("Delete", role: .destructive) {
                profileManager.delete(id: profile.id)
                if activeProfileID == profile.id { activeProfileID = nil }
            }
            Button("Cancel", role: .cancel) {}
        } message: { profile in
            Text("Delete "\(profile.name)"?")
        }
    }

    private func profileRow(_ profile: NoiseProfile) -> some View {
        HStack(spacing: 0) {
            if editingProfile?.id == profile.id {
                TextField("", text: $editingName)
                    .placeholder(when: editingName.isEmpty) {
                        Text(profile.name)
                            .foregroundColor(.white.opacity(0.3))
                            .font(.system(size: 13, weight: .light, design: .monospaced))
                    }
                    .font(.system(size: 13, weight: .light, design: .monospaced))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit {
                        if !editingName.trimmingCharacters(in: .whitespaces).isEmpty {
                            profileManager.update(id: profile.id, name: editingName)
                        }
                        editingProfile = nil
                    }
            } else {
                Button(action: {
                    loadProfile(profile)
                    dismiss()
                }) {
                    Text(profile.name)
                        .font(.system(size: 13, weight: .light, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if profile.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.leading, 8)
                }
            }

            Spacer()

            if editingProfile?.id != profile.id {
                Button(action: {
                    editingProfile = profile
                    editingName = profile.name
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.leading, 16)
            }
        }
        .padding(.vertical, 8)
    }

    private func loadProfile(_ profile: NoiseProfile) {
        audioEngine.bandGains = profile.bandGains
        if let saved = profile.lfoStates, saved.count == lfoManager.bandCount {
            lfoManager.states = saved
        }
        activeProfileID = profile.id
    }
}

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
