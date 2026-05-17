import SwiftUI

struct SnippetRowView: View {
    let snippet: Snippet
    let isSelected: Bool
    let onPick: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text").foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(snippet.title).font(.system(size: 13, weight: .medium))
                Text(snippet.body.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            if isHovered {
                Button(action: onEdit) {
                    Image(systemName: "pencil").foregroundColor(.secondary)
                }.buttonStyle(.plain)
                Button(action: onDelete) {
                    Image(systemName: "trash").foregroundColor(.secondary)
                }.buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.16) : (isHovered ? Color.primary.opacity(0.05) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.24) : Color.clear, lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .contentShape(Rectangle())
    }
}
