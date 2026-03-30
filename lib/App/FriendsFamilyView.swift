import SwiftUI
import UIKit

struct FriendsFamilyView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var contacts: ContactsFriendService

    @State private var segment = 0
    @State private var showCreateFamily = false
    @State private var showJoinFamily = false
    @State private var familyName = ""
    @State private var joinCode = ""

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
                        }
                        .pickerStyle(.segmented)
                        .padding()

                        if segment == 0 {
                            realLifeFriends
                        } else {
                            familySection
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
                    }
                    .navigationTitle("Create family")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showCreateFamily = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                let name = familyName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !name.isEmpty else { return }
                                session.createFamily(named: name)
                                familyName = ""
                                showCreateFamily = false
                            }
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
                    }
                    .navigationTitle("Join family")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showJoinFamily = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Join") {
                                if session.joinFamily(code: joinCode) {
                                    joinCode = ""
                                    showJoinFamily = false
                                }
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .onAppear {
                if contacts.authorizationStatus == .authorized {
                    contacts.reloadContacts()
                }
            }
        }
    }

    private var familyGate: some View {
        ScrollView {
            VStack(spacing: 20) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Families unlock everything", systemImage: "figure.2.and.child.holdinghands")
                            .font(.title3.weight(.semibold))
                        Text("Create or join a family to add real-life friends, share location, and keep your circle in sync.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Button {
                        showCreateFamily = true
                    } label: {
                        Label("Create a family", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)

                    Button {
                        showJoinFamily = true
                    } label: {
                        Label("Join with invite code", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
            }
            .padding(.top, 24)
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
                            Text("We only read names to help you add people you know — nothing is uploaded without your action.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
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
                    .padding(.horizontal)
                }

                listSectionTitle("Your friends")
                GlassCard {
                    if session.friends.isEmpty {
                        Text("No friends yet — tap a contact or invite a family member.")
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
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
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
                                ShareLink(
                                    item: URL(string: "https://findmyfriends.app/join?code=\(family.inviteCode)")!
                                ) {
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
                                    .weight(.semibold)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                listSectionTitle("Members")
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
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
    }

    private func listSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
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
}
