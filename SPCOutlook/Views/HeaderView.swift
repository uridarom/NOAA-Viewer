import SwiftUI

struct HeaderView: View {
    let lastUpdated: String
    let nextIssuance: String
    let isRefreshing: Bool
    let onSettings: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
                Text("SPC OUTLOOK")
                    .font(.courier(22, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
                Text(Self.formattedCurrentDate)
                    .font(.courier(13))
                    .foregroundStyle(Color.textSecondary)
                    .padding(.bottom, 10)
            }
            Spacer()
            HStack(spacing: 0) {
                iconButton("gearshape", action: onSettings)
                refreshButton
            }
        }
    }

    private static var formattedCurrentDate: String {
        let now = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: now)
        let year = calendar.component(.year, from: now)
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let month = monthFormatter.string(from: now)
        let ordinalFormatter = NumberFormatter()
        ordinalFormatter.numberStyle = .ordinal
        let dayOrdinal = ordinalFormatter.string(from: NSNumber(value: day)) ?? "\(day)"
        return "\(month) \(dayOrdinal), \(year)"
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
