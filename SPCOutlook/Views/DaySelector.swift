import SwiftUI

struct DaySelector: View {
    @Binding var selectedDay: OutlookDay
    let thumbnails: [OutlookDay: UIImage]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(OutlookDay.allCases) { day in
                    DayCell(
                        day: day,
                        isSelected: day == selectedDay,
                        thumbnail: thumbnails[day]
                    )
                    .onTapGesture {
                        guard day != selectedDay else { return }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedDay = day
                    }
                }
            }
        }
    }
}

private struct DayCell: View {
    let day: OutlookDay
    let isSelected: Bool
    let thumbnail: UIImage?

    var body: some View {
        VStack(spacing: 6) {
            Text(day.title)
                .font(.courier(13))
                .foregroundStyle(Color.textSecondary)

            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.bgCard)

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text("MAP")
                        .font(.courier(10))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .frame(width: 90, height: 64)
        }
        .frame(width: 110)
        .opacity(isSelected ? 1.0 : 0.45)
    }
}
