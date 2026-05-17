import SwiftUI
import AppKit
import Combine

struct HistoryListView: View {
    @EnvironmentObject var store: ClipboardStore
    @EnvironmentObject var pasteStack: PasteStackManager
    @EnvironmentObject var prefs: PreferencesStore
    @EnvironmentObject var keyHandler: PopupKeyHandler

    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @State private var previewItem: ClipItem? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                searchBar
                Divider()
                if filtered.isEmpty {
                    EmptyStateView(
                        title: NSLocalizedString("history.empty.title", comment: ""),
                        subtitle: NSLocalizedString("history.empty.subtitle", comment: "")
                    )
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, item in
                                    ClipRowView(
                                        item: item,
                                        index: idx + 1,
                                        isSelected: idx == selectedIndex,
                                        onPick: { pick(item: item) },
                                        onTogglePin: { store.setPinned(id: item.id, pinned: !item.isPinned) },
                                        onDelete: { store.delete(id: item.id) }
                                    )
                                    .id(item.id)
                                    .padding(.horizontal, 8)
                                    .onTapGesture {
                                        selectedIndex = idx
                                        pick(item: item)
                                    }
                                }
                            }
                        }
                        .onChange(of: selectedIndex) { _ in
                            if filtered.indices.contains(selectedIndex) {
                                withAnimation(.linear(duration: 0.1)) {
                                    proxy.scrollTo(filtered[selectedIndex].id, anchor: .center)
                                }
                            }
                        }
                    }
                }
                Divider()
                footer
            }

            // Quick Look 風プレビュー (Space で開閉)
            if let item = previewItem {
                ClipPreviewView(item: item) { previewItem = nil }
                    .transition(.opacity)
            }
        }
        .onReceive(keyHandler.arrowPressed) { delta in
            let next = max(0, min(filtered.count - 1, selectedIndex + delta))
            selectedIndex = next
        }
        .onReceive(keyHandler.returnPressed) {
            if filtered.indices.contains(selectedIndex) {
                pick(item: filtered[selectedIndex])
            }
        }
        .onReceive(keyHandler.digitPressed) { n in
            // 1-9 で N 番目の項目を即貼付
            let index = n - 1
            if filtered.indices.contains(index) {
                pick(item: filtered[index])
            }
        }
        .onReceive(keyHandler.spacePressed) {
            if previewItem != nil {
                previewItem = nil
            } else if filtered.indices.contains(selectedIndex) {
                previewItem = filtered[selectedIndex]
            }
        }
        .onChange(of: query) { _ in selectedIndex = 0 }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField(NSLocalizedString("history.search.placeholder", comment: ""), text: $query)
                .textFieldStyle(.plain)
            if prefs.pasteStackEnabled, !pasteStack.queue.isEmpty {
                Text("\(pasteStack.queue.count)").font(.caption)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.accentColor).foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Text("Return to paste · Space to preview")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Spacer()
            Button(NSLocalizedString("history.clearAll", comment: "")) {
                store.deleteAll()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding(8)
    }

    private var searchFiltered: [ClipItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return store.items }
        let lower = q.lowercased()
        return store.items.filter { item in
            (item.text?.lowercased().contains(lower) ?? false)
        }
    }

    private var filtered: [ClipItem] {
        searchFiltered
    }

    private func pick(item: ClipItem) {
        if prefs.pasteStackEnabled {
            pasteStack.enqueue(item)
            if pasteStack.queue.count == 1 {
                pasteStack.pasteNext()
                PopupWindowController.shared.close()
            }
            return
        }
        PopupWindowController.shared.close()
        PasteEngine.writeAndPaste(item)
    }
}
