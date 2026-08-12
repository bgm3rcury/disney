import SwiftUI

struct AttractionRow: View {
    let attraction: Attraction
    let isFavorite: Bool
    let toggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(attraction.name)
                        .font(.headline)
                        .lineLimit(2)

                    Spacer()

                    CrowdBadge(level: attraction.crowdLevel)
                }

                HStack(spacing: 6) {
                    Text(attraction.park.shortName)
                    Text("•")
                    Text(attraction.landName)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(attraction.isOpen ? "\(attraction.waitTime) min wait" : "Closed")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(attraction.isOpen ? .primary : .secondary)
            }

            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove favorite" : "Add favorite")
        }
        .padding(.vertical, 4)
    }
}

struct CrowdBadge: View {
    let level: CrowdLevel

    var body: some View {
        Text(level.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
    }

    private var color: Color {
        switch level {
        case .low:
            return .green
        case .moderate:
            return .orange
        case .busy:
            return .red
        case .veryBusy:
            return .purple
        case .closed:
            return .gray
        }
    }
}
