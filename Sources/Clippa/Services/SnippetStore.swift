import Foundation
import Combine

final class SnippetStore: ObservableObject {
    static let shared = SnippetStore()

    @Published private(set) var snippets: [Snippet] = []
    @Published private(set) var folders: [SnippetFolder] = []

    private let db: Database

    private init() {
        do {
            self.db = try Database()
        } catch {
            fatalError("Failed to open database: \(error)")
        }
        reload()
    }

    func reload() {
        do {
            let snipRows: [Snippet] = try db.query("""
                SELECT id, title, body, folder_id, sort_index, created_at, updated_at
                FROM snippets ORDER BY sort_index, created_at DESC
            """, { _ in }) { stmt in
                Snippet(
                    id: UUID(uuidString: Database.columnString(stmt, 0) ?? "") ?? UUID(),
                    title: Database.columnString(stmt, 1) ?? "",
                    body: Database.columnString(stmt, 2) ?? "",
                    folderID: (Database.columnString(stmt, 3)).flatMap { UUID(uuidString: $0) },
                    sortIndex: Database.columnInt(stmt, 4) ?? 0,
                    createdAt: Date(timeIntervalSince1970: Database.columnDouble(stmt, 5)),
                    updatedAt: Date(timeIntervalSince1970: Database.columnDouble(stmt, 6))
                )
            }
            let folderRows: [SnippetFolder] = try db.query("""
                SELECT id, name, sort_index, created_at FROM snippet_folders
                ORDER BY sort_index, created_at
            """, { _ in }) { stmt in
                SnippetFolder(
                    id: UUID(uuidString: Database.columnString(stmt, 0) ?? "") ?? UUID(),
                    name: Database.columnString(stmt, 1) ?? "",
                    sortIndex: Database.columnInt(stmt, 2) ?? 0,
                    createdAt: Date(timeIntervalSince1970: Database.columnDouble(stmt, 3))
                )
            }
            DispatchQueue.main.async {
                self.snippets = snipRows
                self.folders = folderRows
            }
        } catch {
            Log.error("snippet reload failed: \(error)", Log.db)
        }
    }

    func upsert(_ s: Snippet) {
        let sql = """
        INSERT INTO snippets (id, title, body, folder_id, sort_index, created_at, updated_at)
        VALUES (?,?,?,?,?,?,?)
        ON CONFLICT(id) DO UPDATE SET
          title=excluded.title, body=excluded.body, folder_id=excluded.folder_id,
          sort_index=excluded.sort_index, updated_at=excluded.updated_at
        """
        try? db.run(sql) { stmt in
            Database.bindString(stmt, 1, s.id.uuidString)
            Database.bindString(stmt, 2, s.title)
            Database.bindString(stmt, 3, s.body)
            Database.bindString(stmt, 4, s.folderID?.uuidString)
            Database.bindInt(stmt, 5, s.sortIndex)
            Database.bindDouble(stmt, 6, s.createdAt.timeIntervalSince1970)
            Database.bindDouble(stmt, 7, Date().timeIntervalSince1970)
        }
        reload()
    }

    func delete(_ id: UUID) {
        try? db.run("DELETE FROM snippets WHERE id = ?") { stmt in
            Database.bindString(stmt, 1, id.uuidString)
        }
        reload()
    }

    func addFolder(name: String) -> SnippetFolder {
        let folder = SnippetFolder(name: name, sortIndex: folders.count)
        try? db.run("INSERT INTO snippet_folders (id, name, sort_index, created_at) VALUES (?,?,?,?)") { stmt in
            Database.bindString(stmt, 1, folder.id.uuidString)
            Database.bindString(stmt, 2, folder.name)
            Database.bindInt(stmt, 3, folder.sortIndex)
            Database.bindDouble(stmt, 4, folder.createdAt.timeIntervalSince1970)
        }
        reload()
        return folder
    }

    func renameFolder(id: UUID, name: String) {
        try? db.run("UPDATE snippet_folders SET name = ? WHERE id = ?") { stmt in
            Database.bindString(stmt, 1, name)
            Database.bindString(stmt, 2, id.uuidString)
        }
        reload()
    }

    func deleteFolder(id: UUID) {
        try? db.run("DELETE FROM snippet_folders WHERE id = ?") { stmt in
            Database.bindString(stmt, 1, id.uuidString)
        }
        reload()
    }
}
