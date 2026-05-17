import SwiftUI

struct SnippetListView: View {
    @EnvironmentObject var store: SnippetStore
    @EnvironmentObject var keyHandler: PopupKeyHandler

    @State private var query: String = ""
    @State private var selected: Snippet?
    @State private var editing: Snippet?
    @State private var showingNew = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if store.snippets.isEmpty {
                EmptyStateView(
                    title: NSLocalizedString("snippets.empty.title", comment: ""),
                    subtitle: NSLocalizedString("snippets.empty.subtitle", comment: "")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(filtered) { snip in
                            SnippetRowView(snippet: snip,
                                           isSelected: selected?.id == snip.id,
                                           onPick: { paste(snip) },
                                           onEdit: { editing = snip },
                                           onDelete: { store.delete(snip.id) })
                                .padding(.horizontal, 8)
                                .onTapGesture { selected = snip }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            if let s = selected {
                Divider()
                previewPane(snippet: s)
            }
        }
        .sheet(item: $editing) { snip in
            SnippetEditorView(snippet: snip)
        }
        .sheet(isPresented: $showingNew) {
            SnippetEditorView(snippet: nil)
        }
        .onAppear {
            selected = filtered.first
        }
        .onReceive(keyHandler.arrowPressed) { delta in
            guard !filtered.isEmpty else { return }
            let currentIndex = selected.flatMap { current in
                filtered.firstIndex(where: { $0.id == current.id })
            } ?? 0
            let nextIndex = max(0, min(filtered.count - 1, currentIndex + delta))
            selected = filtered[nextIndex]
        }
        .onReceive(keyHandler.returnPressed) {
            if let selected {
                paste(selected)
            } else if let first = filtered.first {
                selected = first
            }
        }
        .onChange(of: query) { _ in
            selected = filtered.first
        }
        .onChange(of: store.snippets.count) { _ in
            if let selected, filtered.contains(where: { $0.id == selected.id }) {
                return
            }
            self.selected = filtered.first
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField(NSLocalizedString("snippets.search.placeholder", comment: ""), text: $query)
                .textFieldStyle(.plain)
            Button {
                showingNew = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
    }

    private func previewPane(snippet: Snippet) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView {
                Text(snippet.body)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(maxHeight: 100)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            HStack {
                Button(NSLocalizedString("snippets.edit", comment: "")) { editing = snippet }
                Button(NSLocalizedString("snippets.delete", comment: "")) { store.delete(snippet.id); selected = nil }
                    .foregroundColor(.red)
                Spacer()
                Button(NSLocalizedString("snippets.paste", comment: "")) { paste(snippet) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(8)
    }

    private var filtered: [Snippet] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return store.snippets }
        return store.snippets.filter {
            $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q)
        }
    }

    private func paste(_ snip: Snippet) {
        let clipboardString = NSPasteboard.general.string(forType: .string)
        let result = SnippetEngine.expand(snip.body, clipboard: clipboardString)
        PopupWindowController.shared.close()
        PasteEngine.writeStringToClipboard(result.text)
        PasteEngine.pasteCurrentClipboard()
    }
}
