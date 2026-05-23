import SwiftUI

struct DiscussionView: View {
    let discussion: ParsedDiscussion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(discussion.headline)
                .font(.courier(14, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            ForEach(discussion.sections.indices, id: \.self) { idx in
                sectionView(discussion.sections[idx])
            }

            if let prev = discussion.previousDiscussion, !prev.sections.isEmpty {
                Color.dividerColor.frame(height: 1).padding(.vertical, 4)

                Text(prevHeader(for: prev))
                    .font(.courier(11, weight: .bold))
                    .foregroundStyle(Color.textSecondary)

                ForEach(prev.sections.indices, id: \.self) { idx in
                    sectionView(prev.sections[idx])
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    @ViewBuilder
    private func sectionView(_ section: ParsedSection) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.title)
                .font(.courier(12, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Text(section.body)
                .font(.courier(12))
                .foregroundStyle(Color.textSecondary)
        }
    }

    private func prevHeader(for prev: PreviousDiscussion) -> String {
        guard let date = prev.issuance else { return "PREVIOUS OUTLOOK" }
        return "PREVIOUS OUTLOOK — " + Self.timeFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "h:mm a"
        return f
    }()
}
