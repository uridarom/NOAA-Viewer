import SwiftUI

struct DaySelector: View {
    @Binding var selectedDay: OutlookDay
    let thumbnails: [OutlookDay: UIImage]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
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
        VStack(spacing: 10) {
            Text(day.title)
                .font(.courier(13))
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 2)

            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.bgCard)

                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                } else {
                    Text("MAP")
                        .font(.courier(12))
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .frame(width: 90, height: 90)
        }
        .frame(width: 140)
        .opacity(isSelected ? 1.0 : 0.45)
    }
}
