import Foundation

struct Snippet: Identifiable, Hashable {
    let id: UUID
    var title: String
    var body: String
    var folderID: UUID?
    var sortIndex: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        folderID: UUID? = nil,
        sortIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.folderID = folderID
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct SnippetFolder: Identifiable, Hashable {
    let id: UUID
    var name: String
    var sortIndex: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        sortIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sortIndex = sortIndex
        self.createdAt = createdAt
    }
}
