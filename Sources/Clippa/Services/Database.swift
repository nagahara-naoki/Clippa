import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class Database {
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "app.clippa.db", qos: .userInitiated)

    init(url: URL = AppPaths.databaseURL) throws {
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &handle, flags, nil) == SQLITE_OK, let handle else {
            throw DBError.openFailed
        }
        self.db = handle
        try migrate()
    }

    deinit {
        if let db { sqlite3_close(db) }
    }

    enum DBError: Error {
        case openFailed
        case prepareFailed(String)
        case stepFailed(String)
    }

    // MARK: - Migration

    private func migrate() throws {
        try exec("""
        CREATE TABLE IF NOT EXISTS clip_items (
            id TEXT PRIMARY KEY,
            kind TEXT NOT NULL,
            text TEXT,
            rich_text_data BLOB,
            html_data BLOB,
            image_file_name TEXT,
            image_thumbnail_path TEXT,
            image_width INTEGER,
            image_height INTEGER,
            image_bytes INTEGER,
            source_app TEXT,
            source_bundle_id TEXT,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            is_pinned INTEGER NOT NULL DEFAULT 0,
            content_hash TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_clip_items_created_at ON clip_items(created_at DESC);
        CREATE INDEX IF NOT EXISTS idx_clip_items_pinned ON clip_items(is_pinned);
        CREATE INDEX IF NOT EXISTS idx_clip_items_hash ON clip_items(content_hash);

        CREATE TABLE IF NOT EXISTS snippet_folders (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            sort_index INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL
        );

        CREATE TABLE IF NOT EXISTS snippets (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            folder_id TEXT,
            sort_index INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            FOREIGN KEY (folder_id) REFERENCES snippet_folders(id) ON DELETE SET NULL
        );
        CREATE INDEX IF NOT EXISTS idx_snippets_folder ON snippets(folder_id);
        """)
    }

    // MARK: - Helpers

    @discardableResult
    func exec(_ sql: String) throws -> Bool {
        try queue.sync {
            var err: UnsafeMutablePointer<Int8>?
            let result = sqlite3_exec(db, sql, nil, nil, &err)
            if result != SQLITE_OK {
                let msg = err.map { String(cString: $0) } ?? "unknown"
                sqlite3_free(err)
                throw DBError.stepFailed(msg)
            }
            return true
        }
    }

    func run(_ sql: String, _ bind: (OpaquePointer?) -> Void = { _ in }) throws {
        try queue.sync {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
            }
            defer { sqlite3_finalize(stmt) }
            bind(stmt)
            let r = sqlite3_step(stmt)
            guard r == SQLITE_DONE || r == SQLITE_ROW else {
                throw DBError.stepFailed(String(cString: sqlite3_errmsg(db)))
            }
        }
    }

    func query<T>(_ sql: String, _ bind: (OpaquePointer?) -> Void = { _ in }, _ map: (OpaquePointer?) -> T) throws -> [T] {
        try queue.sync {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw DBError.prepareFailed(String(cString: sqlite3_errmsg(db)))
            }
            defer { sqlite3_finalize(stmt) }
            bind(stmt)
            var rows: [T] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                rows.append(map(stmt))
            }
            return rows
        }
    }

    // MARK: - Bind helpers

    static func bindString(_ stmt: OpaquePointer?, _ index: Int32, _ value: String?) {
        if let v = value {
            sqlite3_bind_text(stmt, index, v, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    static func bindInt(_ stmt: OpaquePointer?, _ index: Int32, _ value: Int?) {
        if let v = value {
            sqlite3_bind_int64(stmt, index, Int64(v))
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    static func bindDouble(_ stmt: OpaquePointer?, _ index: Int32, _ value: Double) {
        sqlite3_bind_double(stmt, index, value)
    }

    static func bindBlob(_ stmt: OpaquePointer?, _ index: Int32, _ value: Data?) {
        if let v = value, !v.isEmpty {
            _ = v.withUnsafeBytes { buf in
                sqlite3_bind_blob(stmt, index, buf.baseAddress, Int32(v.count), SQLITE_TRANSIENT)
            }
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }

    static func bindBool(_ stmt: OpaquePointer?, _ index: Int32, _ value: Bool) {
        sqlite3_bind_int(stmt, index, value ? 1 : 0)
    }

    // MARK: - Column helpers

    static func columnString(_ stmt: OpaquePointer?, _ index: Int32) -> String? {
        guard let c = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: c)
    }

    static func columnInt(_ stmt: OpaquePointer?, _ index: Int32) -> Int? {
        if sqlite3_column_type(stmt, index) == SQLITE_NULL { return nil }
        return Int(sqlite3_column_int64(stmt, index))
    }

    static func columnDouble(_ stmt: OpaquePointer?, _ index: Int32) -> Double {
        sqlite3_column_double(stmt, index)
    }

    static func columnBool(_ stmt: OpaquePointer?, _ index: Int32) -> Bool {
        sqlite3_column_int(stmt, index) != 0
    }

    static func columnBlob(_ stmt: OpaquePointer?, _ index: Int32) -> Data? {
        let bytes = sqlite3_column_bytes(stmt, index)
        if bytes <= 0 { return nil }
        guard let ptr = sqlite3_column_blob(stmt, index) else { return nil }
        return Data(bytes: ptr, count: Int(bytes))
    }
}
