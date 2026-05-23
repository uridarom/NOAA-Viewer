import SwiftUI

struct DaySelector: View {
    @Binding var selectedDay: OutlookDay
    let thumbnails: [OutlookDay: UIImage]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(OutlookDay.allCases) { day in
                        DayCell(
                            day: day,
                            isSelected: day == selectedDay,
                            thumbnail: thumbnails[day]
                        )
                        .id(day)
                        .onTapGesture {
                            guard day != selectedDay else { return }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedDay = day
                        }
                    }
                }
                .padding(8)
            }
            .onChange(of: selectedDay) { newDay in
                withAnimation {
                    proxy.scrollTo(newDay, anchor: nil)
                }
            }
        }
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 3))
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

            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.bgPrimary)

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
            .frame(width: 90, height: 61)
        }
        .frame(width: 93)
        .opacity(isSelected ? 1.0 : 0.45)
    }
}
