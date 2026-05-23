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
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func sectionView(_ section: ParsedSection) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.title)
                .font(.courier(14, weight: .bold))
                .foregroundStyle(Color.textPrimary)
            Text(section.body)
                .font(.courier(14))
                .foregroundStyle(Color.textSecondary)
        }
    }
}
