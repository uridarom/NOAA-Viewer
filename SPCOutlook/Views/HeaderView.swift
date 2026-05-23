import SwiftUI

struct HeaderView: View {
    let lastUpdated: String
    let nextIssuance: String
    let isRefreshing: Bool
    let onSettings: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SPC OUTLOOK")
                    .font(.courier(22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text("Last Updated: \(lastUpdated) (next \(nextIssuance))")
                    .font(.courier(13))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            HStack(spacing: 3) {
                iconButton("gearshape", action: onSettings)
                refreshButton
            }
        }
    }

    @ViewBuilder
    private var refreshButton: some View {
        Button(action: onRefresh) {
            Group {
                if isRefreshing {
                    ProgressView()
                        .tint(Color.textPrimary)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Color.textPrimary)
                }
            }
            .frame(width: 36, height: 36)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .disabled(isRefreshing)
    }

    @ViewBuilder
    private func iconButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(Color.textPrimary)
                .frame(width: 36, height: 36)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}
