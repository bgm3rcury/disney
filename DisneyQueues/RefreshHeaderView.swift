import SwiftUI

struct RefreshHeaderView: View {
    let isLoading: Bool
    let lastRefresh: Date?
    let nextRefresh: Date
    let now: Date
    let errorMessage: String?
    let refresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isLoading ? "Refreshing..." : "Next refresh in \(countdown)")
                        .font(.headline)

                    Text(lastRefreshText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
                .accessibilityLabel("Refresh queue times")
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private var countdown: String {
        let remaining = max(0, Int(nextRefresh.timeIntervalSince(now)))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var lastRefreshText: String {
        guard let lastRefresh else {
            return "No refresh yet"
        }

        return "Updated \(lastRefresh.formatted(date: .omitted, time: .shortened))"
    }
}
