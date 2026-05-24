import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = OutlookViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                HeaderView(
                    lastUpdated: viewModel.lastUpdatedString,
                    nextIssuance: viewModel.nextIssuanceString(for: viewModel.selectedDay),
                    isRefreshing: viewModel.isRefreshing,
                    onSettings: { showSettings = true },
                    onRefresh: {
                        Task { await viewModel.refresh(day: viewModel.selectedDay,
                                                       risk: viewModel.selectedRisk) }
                    }
                )

                HStack(alignment: .top, spacing: 6) {
                    LocalRisksCard(localRisks: viewModel.localRisks,
                                   locationDenied: viewModel.locationPermissionDenied)
                    DaySelector(selectedDay: $viewModel.selectedDay, thumbnails: viewModel.thumbnails)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 10)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(outlookTitle)
                        .font(.courier(14, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text(subtitleText)
                        .font(.courier(12))
                        .foregroundStyle(subtitleColor)
                        .padding(.bottom, 10)
                }

                OutlookImageView(
                    isLocalView: viewModel.isLocalView,
                    canToggleLocalView: viewModel.wfo != nil && !viewModel.localViewDisabled,
                    image: viewModel.outlookImage,
                    onTap: {
                        Task { await viewModel.toggleLocalView(day: viewModel.selectedDay,
                                                               risk: viewModel.selectedRisk) }
                    },
                    onSwipe: { delta in
                        let days = OutlookDay.allCases
                        guard let idx = days.firstIndex(of: viewModel.selectedDay) else { return }
                        let newIdx = max(0, min(days.count - 1, idx + delta))
                        guard newIdx != idx else { return }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.selectedDay = days[newIdx]
                    }
                )

                RiskTabs(selectedRisk: $viewModel.selectedRisk,
                         selectedDay: viewModel.selectedDay)

                discussionArea
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .overlay(alignment: .top) {
            Color.bgPrimary
                .ignoresSafeArea(edges: .top)
                .frame(height: 0)
        }
        .navigationDestination(isPresented: $showSettings) { SettingsView() }
        .preferredColorScheme(.dark)
        .overlay(alignment: .bottom) { toastOverlay }
        .animation(.easeInOut(duration: 0.25), value: viewModel.toastMessage)
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.backgroundSync() }
                group.addTask { await viewModel.loadThumbnails() }
                group.addTask { await viewModel.startLocationServices() }
            }
        }
        .onChange(of: viewModel.selectedDay) { newDay in
            let needsReset = (newDay == .three || newDay.isGrouped) && viewModel.selectedRisk != .general
            let targetRisk: RiskType
            if needsReset {
                viewModel.selectedRisk = .general
                targetRisk = .general
            } else {
                targetRisk = viewModel.selectedRisk
            }
            PersistenceStore.save(selectedDay: newDay, selectedRisk: targetRisk)
            Task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await viewModel.load(day: newDay, risk: targetRisk) }
                    group.addTask { await viewModel.loadDiscussion(day: newDay) }
                    if newDay == .one { group.addTask { await viewModel.loadLocalRisks() } }
                }
            }
        }
        .onChange(of: viewModel.selectedRisk) { newRisk in
            PersistenceStore.save(selectedDay: viewModel.selectedDay, selectedRisk: newRisk)
            Task { await viewModel.load(day: viewModel.selectedDay, risk: newRisk) }
        }
        } // NavigationStack
    }

    // MARK: - Discussion area

    @ViewBuilder
    private var discussionArea: some View {
        if let discussion = viewModel.discussion {
            DiscussionView(discussion: discussion)
        } else if viewModel.isInitialLoadComplete {
            // Load completed but no data (offline + no cache)
            noDataView
        } else {
            // Still loading
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.bgCard)
                .frame(maxWidth: .infinity, minHeight: 80)
                .overlay(ProgressView().tint(Color.textSecondary))
        }
    }

    @ViewBuilder
    private var noDataView: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.bgCard)
            .frame(maxWidth: .infinity, minHeight: 80)
            .overlay(
                Text("No outlook available — pull to retry")
                    .font(.courier(13))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(12)
            )
    }

    // MARK: - Toast

    @ViewBuilder
    private var toastOverlay: some View {
        if let message = viewModel.toastMessage {
            ToastView(message: message)
                .padding(.bottom, 32)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: - Computed strings

    private var outlookTitle: String {
        viewModel.selectedDay.isGrouped
            ? "Day 4–8 Outlook"
            : "Day \(viewModel.selectedDay.rawValue) Convective Outlook"
    }

    private var subtitleText: String {
        if viewModel.isLocalView, let wfo = viewModel.wfo {
            return "Showing \(wfo) region — tap to return"
        }
        if viewModel.selectedDay.isGrouped {
            return "Days 4–8 share a combined outlook"
        }
        return "Last Updated: \(viewModel.lastUpdatedString) (next \(viewModel.nextIssuanceString(for: viewModel.selectedDay)))"
    }

    private var subtitleColor: Color {
        if !viewModel.isLocalView && (viewModel.wfo == nil || viewModel.localViewDisabled) {
            return Color.textTertiary
        }
        return Color.textSecondary
    }
}

#Preview {
    ContentView()
}
