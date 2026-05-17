import SwiftUI
import AppKit

struct ClipRowView: View {
    let item: ClipItem
    let index: Int
    let isSelected: Bool
    let onPick: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            iconView
            VStack(alignment: .leading, spacing: 2) {
                Text(item.previewText)
                    .lineLimit(2)
                    .font(.system(size: 13))
                HStack(spacing: 6) {
                    if let source = item.sourceApp {
                        Text(source).font(.system(size: 10)).foregroundColor(.secondary)
                    }
                    Text(timeAgoString(item.createdAt))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 4)
            trailingControls
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
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
    }

    private var trailingControls: some View {
        HStack(spacing: 6) {
            if index <= 9 {
                Text("\(index)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Button(action: onTogglePin) {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .foregroundColor(item.isPinned ? .accentColor : .secondary)
                    .opacity(isHovered || item.isPinned ? 1 : 0)
            }
            .buttonStyle(.plain)
            .disabled(!(isHovered || item.isPinned))
            .allowsHitTesting(isHovered || item.isPinned)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1 : 0)
            }
            .buttonStyle(.plain)
            .disabled(!isHovered)
            .allowsHitTesting(isHovered)
        }
        .frame(width: 42, alignment: .trailing)
    }

    @ViewBuilder
    private var iconView: some View {
        switch item.kind {
        case .image:
            if let img = rowImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo").foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
            }
        case .url:
            Image(systemName: "link").foregroundColor(.blue)
                .frame(width: 28, height: 28)
        case .fileURL:
            Image(systemName: "doc").foregroundColor(.secondary)
                .frame(width: 28, height: 28)
        case .richText, .html:
            Image(systemName: "doc.richtext").foregroundColor(.secondary)
                .frame(width: 28, height: 28)
        case .color:
            Image(systemName: "paintpalette").foregroundColor(.secondary)
                .frame(width: 28, height: 28)
        case .plainText:
            Image(systemName: "text.alignleft").foregroundColor(.secondary)
                .frame(width: 28, height: 28)
        }
    }

    private var rowImage: NSImage? {
        if let path = item.imageThumbnailPath,
           let thumbnail = ImageStore.loadThumbnail(path: path) {
            return thumbnail
        }
        if let fileName = item.imageFileName {
            return ImageStore.loadImage(fileName: fileName)
        }
        return nil
    }

    private func timeAgoString(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}
