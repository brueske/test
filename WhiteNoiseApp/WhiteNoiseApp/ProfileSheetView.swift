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
    @State private var editMode: EditMode = .inactive

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider().background(Color.white.opacity(0.1))
                saveSection
                Divider().background(Color.white.opacity(0.1))
                profileList
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
            Text("Delete \"\(profile.name)\"?")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("PROFILES")
                .font(.system(size: 12, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .tracking(4)
            Spacer()
            // Reorder toggle
            Button(action: {
                withAnimation { editMode = editMode == .active ? .inactive : .active }
            }) {
                Text(editMode == .active ? "DONE" : "REORDER")
                    .font(.system(size: 10, weight: .light, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(.white.opacity(editMode == .active ? 0.7 : 0.35))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white.opacity(editMode == .active ? 0.3 : 0.12), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 20)
    }

    // MARK: - Save section

    private var saveSection: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                .overlay(Rectangle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
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
    }

    // MARK: - Profile list

    private var profileList: some View {
        List {
            ForEach(profileManager.profiles) { profile in
                profileRow(profile)
                    .listRowBackground(Color.black)
                    .listRowSeparatorTint(Color.white.opacity(0.05))
                    .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // Trash — no .destructive role so it stays monochrome
                        Button {
                            deleteCandidate = profile
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .ultraLight))
                        }
                        .tint(Color(white: 0.22))

                        // Pin / unpin
                        Button {
                            profileManager.togglePin(id: profile.id)
                        } label: {
                            Image(systemName: profile.isPinned ? "pin.slash" : "pin")
                                .font(.system(size: 14, weight: .ultraLight))
                        }
                        .tint(Color(white: 0.14))
                    }
            }
            .onMove { source, destination in
                profileManager.move(from: source, to: destination)
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, $editMode)
        .scrollContentBackground(.hidden)
        .background(Color.black)
    }

    // MARK: - Profile row

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
                    HStack(spacing: 8) {
                        Text(profile.name)
                            .font(.system(size: 13, weight: .light, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        if profile.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9, weight: .ultraLight))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            if editingProfile?.id != profile.id {
                Button(action: {
                    editingProfile = profile
                    editingName = profile.name
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
                .padding(.leading, 16)
            }
        }
        .padding(.vertical, 14)
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
