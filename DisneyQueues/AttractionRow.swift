import SwiftUI
import UIKit

struct AttractionRow: View {
    let attraction: Attraction
    let isFavorite: Bool
    let toggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AttractionThumbnail(attraction: attraction)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(attraction.name)
                        .font(.headline)
                        .lineLimit(2)

                    Spacer()

                    CrowdBadge(level: attraction.crowdLevel)
                }

                HStack(spacing: 6) {
                    Text(attraction.park.shortName)
                    Text("-")
                    Text(attraction.landName)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !attraction.officialTags.isEmpty {
                    Text(attraction.officialTags.prefix(3).joined(separator: " / "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(attraction.isOpen ? "\(attraction.waitTime) min wait" : "Closed")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(attraction.isOpen ? .primary : .secondary)
            }

            Button(action: toggleFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove favorite" : "Add favorite")
        }
        .padding(.vertical, 4)
    }
}

private struct AttractionThumbnail: View {
    let attraction: Attraction

    var body: some View {
        Group {
            if let imageName = attraction.imageName, let image = UIImage(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: placeholderColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: attraction.isCoaster ? "figure.play" : "sparkles")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: 72, height: 54)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var placeholderColors: [Color] {
        if attraction.isCoaster {
            return [.red, .purple]
        }

        if attraction.displayCategories.contains(.chillRide) {
            return [.blue, .green]
        }

        return [.indigo, .cyan]
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
