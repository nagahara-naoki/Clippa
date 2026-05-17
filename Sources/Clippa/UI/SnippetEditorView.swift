import SwiftUI

struct SnippetEditorView: View {
    @EnvironmentObject var store: SnippetStore
    @Environment(\.dismiss) private var dismiss

    let snippet: Snippet?

    @State private var title: String = ""
    @State private var content: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(snippet == nil ? "Add Text" : "Edit Text")
                .font(.headline)
            TextField("Name", text: $title)
                .textFieldStyle(.roundedBorder)

            Text("Text")
                .font(.caption).foregroundColor(.secondary)
            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 220)
                .padding(6)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.16)))

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.isEmpty || content.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 460, height: 390)
        .onAppear {
            title = snippet?.title ?? ""
            content = snippet?.body ?? ""
        }
    }

    private func save() {
        if let existing = snippet {
            var updated = existing
            updated.title = title
            updated.body = content
            updated.folderID = nil
            updated.updatedAt = Date()
            store.upsert(updated)
        } else {
            let s = Snippet(title: title, body: content, folderID: nil, sortIndex: store.snippets.count)
            store.upsert(s)
        }
        dismiss()
    }
}
