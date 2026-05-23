import SwiftUI

struct LocalRisksCard: View {
    @Environment(\.openURL) private var openURL

    let localRisks: LocalRisks
    /// true when location permission is denied/restricted; shows "--%  Enable location"
    let locationDenied: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Local Risks")
                .font(.courier(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            riskRow("Hail:",    value: localRisks.hail)
            riskRow("Tornado:", value: localRisks.tornado)
            riskRow("Wind:",    value: localRisks.wind)
            floodRow

            if locationDenied {
                Button {
                    if let url = URL(string: "app-settings:") {
                        openURL(url)
                    }
                } label: {
                    Text("Enable location")
                        .font(.courier(11))
                        .foregroundStyle(Color.accentSafe)
                        .underline()
                }
            }
        }
        .padding(12)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func riskRow(_ label: String, value: Int?) -> some View {
        let (text, color) = riskDisplay(value)
        HStack {
            Text(label)
                .font(.courier(14))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text(text)
                .font(.courier(14))
                .foregroundStyle(color)
        }
    }

    @ViewBuilder
    private var floodRow: some View {
        HStack {
            Text("Flood:")
                .font(.courier(14))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            if locationDenied {
                Text("--%")
                    .font(.courier(14))
                    .foregroundStyle(Color.textTertiary)
            } else if let flood = localRisks.flood {
                Text("\(flood)%")
                    .font(.courier(14))
                    .foregroundStyle(Color.riskColor(for: flood))
            } else {
                Text("--%")
                    .font(.courier(14))
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }

    /// Resolves display text and color for a risk value.
    /// - nil    : GeoJSON fetch failed       → "---%" in tertiary
    /// - 0      : fetched, outside all zones → "  0%" in tertiary
    /// - >0     : inside a risk zone         → "N%"   in tier color
    /// When location is denied, always returns "--%".
    private func riskDisplay(_ value: Int?) -> (text: String, color: Color) {
        if locationDenied {
            return ("--%", .textTertiary)
        }
        guard let value else {
            return ("---%", .textTertiary)
        }
        return ("\(value)%", Color.riskColor(for: value))
    }
}
