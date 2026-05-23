import SwiftUI

struct OutlookImageView: View {
    let isLocalView: Bool
    let canToggleLocalView: Bool
    let image: UIImage?
    let onTap: () -> Void
    let onSwipe: (Int) -> Void  // +1 = next day, -1 = previous day

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.bgCard)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
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
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let h = value.translation.width
                    let v = value.translation.height
                    guard abs(h) > abs(v) else { return }
                    if h < -50 { onSwipe(1) }
                    else if h > 50 { onSwipe(-1) }
                }
        )
        .onTapGesture { if canToggleLocalView { onTap() } }
    }
}
