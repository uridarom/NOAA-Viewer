import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = OutlookViewModel()
    @State private var selectedDay: OutlookDay = .one
    @State private var selectedRisk: RiskType = .general
    @State private var isLocalView: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HeaderView(
                    lastUpdated: viewModel.lastUpdatedString,
                    nextIssuance: viewModel.nextIssuanceString(for: selectedDay),
                    isRefreshing: viewModel.isRefreshing,
                    onSettings: {},
                    onRefresh: { Task { await viewModel.refresh(day: selectedDay, risk: selectedRisk) } }
                )

                HStack(alignment: .top, spacing: 12) {
                    LocalRisksCard(localRisks: viewModel.localRisks)
                    DaySelector(selectedDay: $selectedDay, thumbnails: viewModel.thumbnails)
                        .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(outlookTitle)
                        .font(.courier(16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text(subtitleText)
                        .font(.courier(13))
                        .foregroundStyle(Color.textSecondary)
                }

                OutlookImageView(isLocalView: $isLocalView, image: viewModel.outlookImage)

                RiskTabs(selectedRisk: $selectedRisk, selectedDay: selectedDay)

                if let discussion = viewModel.discussion {
                    DiscussionView(discussion: discussion)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.bgCard)
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .overlay(ProgressView().tint(Color.textSecondary))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .overlay(alignment: .bottom) { toastOverlay }
        .animation(.easeInOut(duration: 0.25), value: viewModel.toastMessage)
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.load(day: selectedDay, risk: selectedRisk) }
                group.addTask { await viewModel.loadThumbnails() }
                group.addTask { await viewModel.loadDiscussion(day: selectedDay) }
                group.addTask { await viewModel.startLocationServices() }
            }
        }
        .onChange(of: selectedDay) { newDay in
            let needsReset = (newDay == .three || newDay.isGrouped) && selectedRisk != .general
            let targetRisk: RiskType
            if needsReset {
                selectedRisk = .general
                targetRisk = .general
            } else {
                targetRisk = selectedRisk
            }
            Task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await viewModel.load(day: newDay, risk: targetRisk) }
                    group.addTask { await viewModel.loadDiscussion(day: newDay) }
                    if newDay == .one { group.addTask { await viewModel.loadLocalRisks() } }
                }
            }
        }
        .onChange(of: selectedRisk) { newRisk in
            Task { await viewModel.load(day: selectedDay, risk: newRisk) }
        }
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if let message = viewModel.toastMessage {
            Text(message)
                .font(.courier(13))
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.bgTabSelected)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.bottom, 32)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var outlookTitle: String {
        selectedDay.isGrouped ? "Day 4–8 Outlook" : "Day \(selectedDay.rawValue) Convective Outlook"
    }

    private var subtitleText: String {
        if selectedDay.isGrouped {
            return "Days 4–8 share a combined outlook"
        }
        return "Tap for local view, swipe for Day \(min(selectedDay.rawValue + 1, 8))"
    }
}

#Preview {
    ContentView()
}
