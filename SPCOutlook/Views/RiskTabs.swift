import SwiftUI

struct RiskTabs: View {
    @Binding var selectedRisk: RiskType
    let selectedDay: OutlookDay

    var body: some View {
        HStack(spacing: 4) {
            ForEach(RiskType.allCases) { risk in
                tabButton(risk)
            }
        }
    }

    private func isDisabled(_ risk: RiskType) -> Bool {
        risk != .general && (selectedDay == .three || selectedDay.isGrouped)
    }

    @ViewBuilder
    private func tabButton(_ risk: RiskType) -> some View {
        let isSelected = selectedRisk == risk
        let disabled   = isDisabled(risk)
        Button {
            guard !disabled, risk != selectedRisk else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedRisk = risk
        } label: {
            Text(risk.label)
                .font(.courier(13))
                .tracking(0.5)
                .foregroundStyle(
                    disabled   ? Color.textTertiary :
                    isSelected ? Color.textPrimary  : Color.textSecondary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected && !disabled ? Color.bgTabSelected : Color.bgTabUnselected)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
