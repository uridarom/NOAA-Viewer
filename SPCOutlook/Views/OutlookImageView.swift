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
            } else {
                ProgressView()
                    .tint(Color.textSecondary)
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
