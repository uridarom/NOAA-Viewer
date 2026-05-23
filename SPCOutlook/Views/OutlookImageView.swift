import SwiftUI

struct OutlookImageView: View {
    @Binding var isLocalView: Bool
    let image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.bgCard)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .tint(Color.textSecondary)
            }

            if isLocalView {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("LOCAL VIEW")
                            .font(.courier(11, weight: .bold))
                            .foregroundStyle(Color.accentAmber)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.bgPrimary.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(10)
                    }
                }
            }
        }
        .aspectRatio(4 / 3, contentMode: .fit)
        .onTapGesture { isLocalView.toggle() }
    }
}
