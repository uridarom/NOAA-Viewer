import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.courier(13))
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.bgTabSelected)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
