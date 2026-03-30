import SwiftUI

private struct ActiveMember: Identifiable {
    let id: UUID
    let name: String
    let subtitle: String
    let isLive: Bool
}

struct SocialFeedView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var tracking: TrackingService

    @StateObject private var store = SocialFeedStore()

    private var activeMembers: [ActiveMember] {
        var members: [ActiveMember] = []
        let you = ActiveMember(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "You",
            subtitle: tracking.travelModeLabel,
            isLive: tracking.isLive
        )
        members.append(you)
        for friend in session.friends {
            let live = friend.latitude != nil && friend.longitude != nil
            members.append(
                ActiveMember(
                    id: friend.id,
                    name: friend.name,
                    subtitle: friend.isFamilyMember ? "Family" : "Friend",
                    isLive: live
                )
            )
        }
        return members
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: LayoutMetrics.sectionSpacing) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Active now", subtitle: "Live movers from your circle.")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(activeMembers) { member in
                                        activePill(member)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)

                    ForEach(store.checkIns) { checkIn in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(checkIn.name)
                                            .font(.headline)
                                        Text("\(checkIn.place) • \(checkIn.time.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundStyle(AppTheme.accent)
                                }
                                Text(checkIn.status)
                                    .font(.subheadline)

                                HStack(spacing: 10) {
                                    ForEach(checkIn.reactions) { reaction in
                                        Button {
                                            store.toggleReaction(on: checkIn, type: reaction.type)
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: reaction.type.rawValue)
                                                Text("\(reaction.count)")
                                                    .font(.caption.weight(.semibold))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                reaction.isSelected ? AppTheme.accent.opacity(0.2) : Color.white.opacity(0.08),
                                                in: Capsule()
                                            )
                                            .foregroundStyle(reaction.isSelected ? AppTheme.accent : .primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, LayoutMetrics.pageHorizontalPadding)
                    }
                }
                .padding(.vertical, 24)
                .contentMaxWidth()
            }
        }
        .navigationTitle("Social Feed")
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Social Feed")
                .font(.largeTitle.weight(.bold))
            Text("Family check-ins with reactions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LayoutMetrics.headerHorizontalPadding)
    }

    private func activePill(_ member: ActiveMember) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(member.isLive ? Color.green : Color.gray.opacity(0.6))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.subheadline.weight(.semibold))
                Text(member.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08), in: Capsule())
    }
}
