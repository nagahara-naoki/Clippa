import SwiftUI
import AppKit

/// 履歴項目の Quick Look 風プレビュー。Space キーまたはクリック外で閉じる。
struct ClipPreviewView: View {
    let item: ClipItem
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // 背景の薄いオーバーレイ (タップで閉じる)
            Color.black.opacity(0.35)
                .onTapGesture { onClose() }

            // プレビュー本体
            VStack(alignment: .leading, spacing: 10) {
                header
                Divider()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .frame(width: 320, height: 420)
            .shadow(radius: 18, y: 8)
        }
    }

    private var header: some View {
        HStack {
            kindIcon
            Text(kindLabel)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .image:
            if let path = item.imageFileName, let img = ImageStore.loadImage(fileName: path) {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            } else {
                Text("Unable to load image").foregroundColor(.secondary)
            }
        case .plainText, .richText, .html, .url, .fileURL, .color:
            ScrollView {
                Text(item.text ?? "")
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
            }
        }
    }

    private var kindIcon: some View {
        let name: String
        switch item.kind {
        case .image: name = "photo"
        case .url: name = "link"
        case .fileURL: name = "doc"
        case .richText, .html: name = "doc.richtext"
        case .color: name = "paintpalette"
        case .plainText: name = "text.alignleft"
        }
        return Image(systemName: name).foregroundColor(.secondary)
    }

    private var kindLabel: String {
        switch item.kind {
        case .image: return "Image"
        case .url: return "URL"
        case .fileURL: return "File"
        case .richText: return "Rich Text"
        case .html: return "HTML"
        case .color: return "Color"
        case .plainText: return "Text"
        }
    }
}
