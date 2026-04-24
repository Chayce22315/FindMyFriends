import SwiftUI
import UIKit

struct FriendsFamilyView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var contacts: ContactsFriendService
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var notifications: NotificationManager

    @State private var segment = 0
    @State private var showCreateFamily = false
    @State private var showJoinFamily = false
    @State private var familyName = ""
    @State private var joinCode = ""
    @State private var joinDisplayName = "Me"
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var rosterPollTask: Task<Void, Never>?
    @State private var knownRosterDeviceIds: Set<String> = []
    @State private var rosterBootstrapComplete = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                if !session.hasFamily {
                    familyGate
                } else {
                    VStack(spacing: 0) {
                        Picker("Section", selection: $segment) {
                            Text("Real-life friends").tag(0)
                            Text("Family").tag(1)
                            Text("Feed").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                        .padding(.vertical, 12)

                        if segment == 0 {
                            realLifeFriends
                        } else if segment == 1 {
                            familySection
                        } else {
                            SocialFeedView()
                        }
                    }
                }
            }
            .navigationTitle("Circle")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if session.hasFamily && segment == 0 {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            contacts.requestAccess()
                            contacts.reloadContacts()
                        } label: {
                            Label("Contacts", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateFamily) {
                NavigationStack {
                    Form {
                        TextField("Name your family", text: $familyName, prompt: Text("e.g. The Riveras"))
                        Text("After you create, use Invite on the Family tab — it shares the real https link from the server.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .navigationTitle("Create family")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showCreateFamily = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                createFamilyRemote()
                            }
                            .disabled(isSubmitting || familyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showJoinFamily) {
                NavigationStack {
                    Form {
                        TextField("Invite code", text: $joinCode, prompt: Text("ABC123"))
                            .textInputAutocapitalization(.characters)
                        TextField("Your name in the circle", text: $joinDisplayName, prompt: Text("Alex"))
                            .textInputAutocapitalization(.words)
                        Text("We will validate the invite code with your backend.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .navigationTitle("Join family")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showJoinFamily = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Join") {
                                joinFamilyRemote()
                            }
                            .disabled(isSubmitting || joinCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .alert("Backend error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if contacts.authorizationStatus == .authorized {
                    contacts.reloadContacts()
                }
                Task { await syncRosterFromServerIfPossible() }
                startRosterPollingIfOrganizer()
            }
            .onDisappear {
                rosterPollTask?.cancel()
                rosterPollTask = nil
            }
            .onChange(of: session.family?.inviteCode) { _, _ in
                rosterPollTask?.cancel()
                rosterPollTask = nil
                knownRosterDeviceIds = []
                rosterBootstrapComplete = false
                startRosterPollingIfOrganizer()
                Task { await syncRosterFromServerIfPossible() }
            }
        }
    }

    private var isFamilyOrganizer: Bool {
        session.familyMembers.contains { $0.isYou && $0.role == "Organizer" }
    }

    private func startRosterPollingIfOrganizer() {
        guard session.hasFamily, isFamilyOrganizer else { return }
        guard rosterPollTask == nil else { return }
        rosterPollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 45_000_000_000)
                await syncRosterFromServerIfPossible()
            }
        }
    }

    @MainActor
    private func syncRosterFromServerIfPossible() async {
        guard let family = session.family else { return }
        let base = settings.backendBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !base.isEmpty else { return }
        do {
            let client = try BackendClient(baseURLString: base)
            let roster = try await client.fetchRoster(inviteCode: family.inviteCode)
            session.applyServerRoster(roster)
            let myId = DeviceIdentity.id
            let remoteIds = Set(roster.members.map(\.deviceId))
            if !rosterBootstrapComplete {
                knownRosterDeviceIds = remoteIds
                rosterBootstrapComplete = true
            } else if isFamilyOrganizer {
                for member in roster.members where member.deviceId != myId {
                    if !knownRosterDeviceIds.contains(member.deviceId) {
                        knownRosterDeviceIds.insert(member.deviceId)
                        notifications.scheduleFamilyMemberJoined(displayName: member.name, familyName: family.name)
                    }
                }
            }
        } catch {
            // Silent: roster is optional when offline
        }
    }

    private var familyGate: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Circle")
                        .font(.largeTitle.weight(.bold))
                    Text("Families, invites, and people you know, laid out for full-width phones.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Families unlock everything", systemImage: "figure.2.and.child.holdinghands")
                            .font(.title2.weight(.semibold))
                        Text("Create or join a family to add real-life friends, share location, and keep your circle in sync.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Invite links are powered by your backend so they can be shared for real.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                VStack(spacing: 14) {
                    Button {
                        showCreateFamily = true
                    } label: {
                        Label("Create a family", systemImage: "plus.circle.fill")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(AppTheme.accent)

                    Button {
                        showJoinFamily = true
                    } label: {
                        Label("Join with invite code", systemImage: "arrow.right.circle.fill")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
            .contentMaxWidth()
        }
    }

    private var realLifeFriends: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if contacts.authorizationStatus != .authorized {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Button("Allow Contacts to add friends") {
                                contacts.requestAccess()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accent)
                            Text("We only read names to help you add people you know, nothing is uploaded without your action.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                }

                if !contactPicksPreview.isEmpty && contacts.authorizationStatus == .authorized {
                    listSectionTitle("From contacts")
                    GlassCard {
                        VStack(spacing: 0) {
                            ForEach(contactPicksPreview) { pick in
                                Button {
                                    addFriend(from: pick)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(pick.name)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                if pick.id != contactPicksPreview.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                }

                listSectionTitle("Your friends")
                GlassCard {
                    if session.friends.isEmpty {
                        Text("No friends yet, tap a contact or invite a family member.")
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(session.friends) { friend in
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(friend.name)
                                            .font(.headline)
                                        Text(friend.source.label)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        session.removeFriend(friend)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                if friend.id != session.friends.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
            }
            .padding(.vertical, 12)
            .contentMaxWidth()
        }
    }

    private var familySection: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if let family = session.family {
                    listSectionTitle("Your family")
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(family.name)
                                        .font(.headline)
                                    Text("Created \(family.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                ShareLink(item: family.inviteLink(baseURL: settings.backendBaseURL)) {
                                    Label("Invite", systemImage: "square.and.arrow.up")
                                }
                                Button {
                                    UIPasteboard.general.string = family.inviteCode
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(.borderless)
                            }
                            LabeledContent("Invite code") {
                                Text(family.inviteCode)
                                    .font(.title3.monospaced())
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                }

                listSectionTitle("People in your circle")
                Text("Family members appear here when they join. Organizers see updates from the server automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                GlassCard {
                    VStack(spacing: 0) {
                        ForEach(session.familyMembers) { member in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(member.name)
                                    Text(member.role)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if member.isYou {
                                    Text("You")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if member.id != session.familyMembers.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
            }
            .padding(.vertical, 12)
            .contentMaxWidth()
        }
    }

    private func listSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2.weight(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
    }

    private var contactPicksPreview: [ContactPick] {
        Array(contacts.contacts.prefix(40))
    }

    private func addFriend(from pick: ContactPick) {
        let friend = Friend(
            name: pick.name,
            subtitle: "From Contacts",
            latitude: 37.33 + Double.random(in: -0.05 ... 0.05),
            longitude: -122.00 + Double.random(in: -0.05 ... 0.05),
            source: .contacts,
            isFamilyMember: false
        )
        session.addFriend(friend)
    }

    private func createFamilyRemote() {
        let name = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        isSubmitting = true
        Task {
            do {
                let client = try BackendClient(baseURLString: settings.backendBaseURL)
                let remote = try await client.createFamily(
                    name: name,
                    deviceId: DeviceIdentity.id,
                    displayName: "Organizer"
                )
                let group = FamilyGroup(
                    id: remote.id,
                    name: remote.name,
                    inviteCode: remote.inviteCode,
                    inviteURL: remote.inviteUrl,
                    createdAt: remote.createdAt
                )
                await MainActor.run {
                    session.setFamily(group, role: "Organizer")
                    familyName = ""
                    showCreateFamily = false
                    isSubmitting = false
                    knownRosterDeviceIds = []
                    rosterBootstrapComplete = false
                    startRosterPollingIfOrganizer()
                }
                await syncRosterFromServerIfPossible()
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func joinFamilyRemote() {
        let code = joinCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        let display = joinDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Me"
            : joinDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        isSubmitting = true
        Task {
            do {
                let client = try BackendClient(baseURLString: settings.backendBaseURL)
                let remote = try await client.joinFamily(
                    code: code,
                    deviceId: DeviceIdentity.id,
                    displayName: display
                )
                let group = FamilyGroup(
                    id: remote.id,
                    name: remote.name,
                    inviteCode: remote.inviteCode,
                    inviteURL: remote.inviteUrl,
                    createdAt: remote.createdAt
                )
                await MainActor.run {
                    session.setFamily(group, role: "Member")
                    joinCode = ""
                    joinDisplayName = "Me"
                    showJoinFamily = false
                    isSubmitting = false
                }
                await syncRosterFromServerIfPossible()
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}
