import Foundation
import Combine
import SQLite3

final class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()

    @Published private(set) var items: [ClipItem] = []

    private let db: Database
    private let prefs = PreferencesStore.shared

    private init() {
        do {
            self.db = try Database()
        } catch {
            fatalError("Failed to open database: \(error)")
        }
        reload()
    }

    // MARK: - Public

    func reload() {
        do {
            let rows = try fetchAll()
            DispatchQueue.main.async { self.items = rows }
        } catch {
            Log.error("reload failed: \(error)", Log.db)
        }
    }

    func find(byHash hash: String) -> ClipItem? {
        do {
            return try fetchOne(byHash: hash)
        } catch {
            return nil
        }
    }

    func insert(_ item: ClipItem) {
        do {
            try insertRow(item)
            try enforceLimits()
            reload()
        } catch {
            Log.error("insert failed: \(error)", Log.db)
        }
    }

    func touchToTop(id: UUID) {
        let now = Date().timeIntervalSince1970
        try? db.run("UPDATE clip_items SET created_at = ?, updated_at = ? WHERE id = ?") { stmt in
            Database.bindDouble(stmt, 1, now)
            Database.bindDouble(stmt, 2, now)
            Database.bindString(stmt, 3, id.uuidString)
        }
        reload()
    }

    func setPinned(id: UUID, pinned: Bool) {
        try? db.run("UPDATE clip_items SET is_pinned = ? WHERE id = ?") { stmt in
            Database.bindBool(stmt, 1, pinned)
            Database.bindString(stmt, 2, id.uuidString)
        }
        reload()
    }

    func delete(id: UUID) {
        if let item = items.first(where: { $0.id == id }), let fname = item.imageFileName {
            ImageStore.delete(fileName: fname, thumbnailPath: item.imageThumbnailPath)
        }
        try? db.run("DELETE FROM clip_items WHERE id = ?") { stmt in
            Database.bindString(stmt, 1, id.uuidString)
        }
        reload()
    }

    func deleteAll(includingPinned: Bool = false) {
        let toDelete = items.filter { includingPinned || !$0.isPinned }
        for item in toDelete {
            if let fname = item.imageFileName {
                ImageStore.delete(fileName: fname, thumbnailPath: item.imageThumbnailPath)
            }
        }
        let sql = includingPinned
            ? "DELETE FROM clip_items"
            : "DELETE FROM clip_items WHERE is_pinned = 0"
        _ = try? db.exec(sql)
        reload()
    }

    // MARK: - Persistence helpers

    private func insertRow(_ item: ClipItem) throws {
        let sql = """
        INSERT INTO clip_items
        (id, kind, text, rich_text_data, html_data, image_file_name, image_thumbnail_path,
         image_width, image_height, image_bytes, source_app, source_bundle_id,
         created_at, updated_at, is_pinned, content_hash)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """
        try db.run(sql) { stmt in
            Database.bindString(stmt, 1, item.id.uuidString)
            Database.bindString(stmt, 2, item.kind.rawValue)
            Database.bindString(stmt, 3, item.text)
            Database.bindBlob(stmt, 4, item.richTextData)
            Database.bindBlob(stmt, 5, item.htmlData)
            Database.bindString(stmt, 6, item.imageFileName)
            Database.bindString(stmt, 7, item.imageThumbnailPath)
            Database.bindInt(stmt, 8, item.imageWidth)
            Database.bindInt(stmt, 9, item.imageHeight)
            Database.bindInt(stmt, 10, item.imageBytes)
            Database.bindString(stmt, 11, item.sourceApp)
            Database.bindString(stmt, 12, item.sourceBundleID)
            Database.bindDouble(stmt, 13, item.createdAt.timeIntervalSince1970)
            Database.bindDouble(stmt, 14, item.updatedAt.timeIntervalSince1970)
            Database.bindBool(stmt, 15, item.isPinned)
            Database.bindString(stmt, 16, item.contentHash)
        }
    }

    private func fetchAll() throws -> [ClipItem] {
        let sql = """
        SELECT id, kind, text, rich_text_data, html_data, image_file_name, image_thumbnail_path,
               image_width, image_height, image_bytes, source_app, source_bundle_id,
               created_at, updated_at, is_pinned, content_hash
        FROM clip_items
        ORDER BY is_pinned DESC, created_at DESC
        LIMIT 1500
        """
        return try db.query(sql, { _ in }) { stmt in
            ClipItem.fromRow(stmt: stmt)
        }
    }

    private func fetchOne(byHash hash: String) throws -> ClipItem? {
        let sql = """
        SELECT id, kind, text, rich_text_data, html_data, image_file_name, image_thumbnail_path,
               image_width, image_height, image_bytes, source_app, source_bundle_id,
               created_at, updated_at, is_pinned, content_hash
        FROM clip_items WHERE content_hash = ? LIMIT 1
        """
        let rows = try db.query(sql, { stmt in
            Database.bindString(stmt, 1, hash)
        }) { stmt in
            ClipItem.fromRow(stmt: stmt)
        }
        return rows.first
    }

    // MARK: - Limits

    private func enforceLimits() throws {
        let maxText = prefs.maxTextItems
        let maxDays = prefs.maxRetentionDays
        let cutoff = Date().addingTimeInterval(-Double(maxDays) * 86400).timeIntervalSince1970

        // 期間切れ（ピン除く）削除
        try collectAndDelete(sql: """
            SELECT image_file_name, image_thumbnail_path FROM clip_items
            WHERE is_pinned = 0 AND created_at < ? AND kind != 'image'
        """, bind: { Database.bindDouble($0, 1, cutoff) })
        try db.run("DELETE FROM clip_items WHERE is_pinned = 0 AND created_at < ? AND kind != 'image'") { stmt in
            Database.bindDouble(stmt, 1, cutoff)
        }

        // テキスト件数オーバー削除
        try db.run("""
            DELETE FROM clip_items WHERE id IN (
                SELECT id FROM clip_items
                WHERE is_pinned = 0 AND kind != 'image'
                ORDER BY created_at DESC
                LIMIT -1 OFFSET ?
            )
        """) { stmt in
            Database.bindInt(stmt, 1, maxText)
        }

        // 画像件数オーバー
        let maxImageItems = prefs.maxImageItems
        try collectAndDelete(sql: """
            SELECT image_file_name, image_thumbnail_path FROM clip_items
            WHERE is_pinned = 0 AND kind = 'image' AND id IN (
                SELECT id FROM clip_items
                WHERE is_pinned = 0 AND kind = 'image'
                ORDER BY created_at DESC
                LIMIT -1 OFFSET ?
            )
        """, bind: { Database.bindInt($0, 1, maxImageItems) })
        try db.run("""
            DELETE FROM clip_items WHERE id IN (
                SELECT id FROM clip_items
                WHERE is_pinned = 0 AND kind = 'image'
                ORDER BY created_at DESC
                LIMIT -1 OFFSET ?
            )
        """) { stmt in
            Database.bindInt(stmt, 1, maxImageItems)
        }

        // 画像容量オーバー
        let cap = prefs.maxImageBytes
        let imageRows: [(id: String, file: String?, thumb: String?, bytes: Int)] = try db.query("""
            SELECT id, image_file_name, image_thumbnail_path, COALESCE(image_bytes, 0)
            FROM clip_items WHERE kind = 'image' AND is_pinned = 0
            ORDER BY created_at DESC
        """, { _ in }) { stmt in
            (
                Database.columnString(stmt, 0) ?? "",
                Database.columnString(stmt, 1),
                Database.columnString(stmt, 2),
                Database.columnInt(stmt, 3) ?? 0
            )
        }
        var total = 0
        for row in imageRows {
            total += row.bytes
            if total > cap {
                if let f = row.file {
                    ImageStore.delete(fileName: f, thumbnailPath: row.thumb)
                }
                try db.run("DELETE FROM clip_items WHERE id = ?") { stmt in
                    Database.bindString(stmt, 1, row.id)
                }
            }
        }
    }

    private func collectAndDelete(sql: String, bind: (OpaquePointer?) -> Void) throws {
        let rows = try db.query(sql, bind) { stmt -> (String?, String?) in
            (Database.columnString(stmt, 0), Database.columnString(stmt, 1))
        }
        for (file, thumb) in rows {
            if let f = file {
                ImageStore.delete(fileName: f, thumbnailPath: thumb)
            }
        }
    }
}

private extension ClipItem {
    static func fromRow(stmt: OpaquePointer?) -> ClipItem {
        ClipItem(
            id: UUID(uuidString: Database.columnString(stmt, 0) ?? "") ?? UUID(),
            kind: ClipKind(rawValue: Database.columnString(stmt, 1) ?? "plainText") ?? .plainText,
            text: Database.columnString(stmt, 2),
            richTextData: Database.columnBlob(stmt, 3),
            htmlData: Database.columnBlob(stmt, 4),
            imageFileName: Database.columnString(stmt, 5),
            imageThumbnailPath: Database.columnString(stmt, 6),
            imageWidth: Database.columnInt(stmt, 7),
            imageHeight: Database.columnInt(stmt, 8),
            imageBytes: Database.columnInt(stmt, 9),
            sourceApp: Database.columnString(stmt, 10),
            sourceBundleID: Database.columnString(stmt, 11),
            createdAt: Date(timeIntervalSince1970: Database.columnDouble(stmt, 12)),
            updatedAt: Date(timeIntervalSince1970: Database.columnDouble(stmt, 13)),
            isPinned: Database.columnBool(stmt, 14),
            contentHash: Database.columnString(stmt, 15) ?? ""
        )
    }
}
