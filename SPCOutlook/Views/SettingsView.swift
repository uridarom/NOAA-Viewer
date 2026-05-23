import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .font(.courier(14))
            .foregroundStyle(Color.textSecondary)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.bgPrimary.ignoresSafeArea())
            .preferredColorScheme(.dark)
    }
}
