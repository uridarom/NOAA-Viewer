import SwiftUI

struct LocalRisksCard: View {
    let localRisks: LocalRisks

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Local Risks")
                .font(.courier(16, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            riskRow("Tornado:", value: localRisks.tornado)
            riskRow("Hail:", value: localRisks.hail)
            riskRow("Wind:", value: localRisks.wind)
            floodRow
        }
        .padding(12)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func riskRow(_ label: String, value: Int) -> some View {
        HStack {
            Text(label)
                .font(.courier(14))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text("\(value)%")
                .font(.courier(14))
                .foregroundStyle(Color.riskColor(for: value))
        }
    }

    @ViewBuilder
    private var floodRow: some View {
        HStack {
            Text("Flood:")
                .font(.courier(14))
                .foregroundStyle(Color.textPrimary)
            Spacer()
            if let flood = localRisks.flood {
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
}
