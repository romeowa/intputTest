//
//  File.swift
//  inputTest2
//
//  Created by yunjin han on 2021/11/11.
//

import Foundation
import GRDB

class TestDatabase {
    static var shared = TestDatabase()
    private var dbQueue: DatabaseQueue?
    
    func insert(records: [TestRecord]) {
        do {
            try dbQueue?.inTransaction { db in
                for record in records {
                    try record.insert(db)
                }
                return .commit
            }
        } catch {
            print("\(error)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    private var databasePath: String {
        return self.getDocumentsDirectory().appendingPathComponent("test.sqlite").path
    }
    
    init() {
        try? initDatabase()
    }
    
    private func initDatabase() throws {
//        print(self.databasePath)
        do {
            try FileManager.default.removeItem(at: URL.init(fileURLWithPath: self.databasePath))
        } catch {
            print(error)
        }
        
        guard dbQueue == nil else { return }
        dbQueue = try? DatabaseQueue(path: databasePath)
        dbQueue.map {
            try? migrator.migrate($0)
        }
    }
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("createTable") { db in
            let columns = TestRecord.Columns.self
            try db.create(table: TestRecord.databaseTableName, body: { table in
                table.autoIncrementedPrimaryKey(columns.id.rawValue)
                table.column(columns.word.rawValue, .text).notNull().unique(onConflict: .replace)
                table.column(columns.placeId.rawValue, .double).notNull()
            })
        }
        
        return migrator
    }
    
    func insert(record: TestRecord) {
        try? dbQueue?.write { db in
            do {
                try record.insert(db)
            } catch {
                print("insert error (\(error))")
            }
        }
    }
    
    func fetchAll() -> [TestRecord] {
        var results = [TestRecord]()
        do {
            try dbQueue?.read { db in
                results = try TestRecord.fetchAll(db)
            }
        } catch {
            print("fetch error (\(error))")
        }
        
        return results
    }
    
    func fetch(word: String) -> TestRecord? {
        var result: TestRecord?
        do {
            try dbQueue?.read { db in
                result = try TestRecord.filter(TestRecord.Columns.word == word).fetchOne(db)
            }
        } catch {
            print("fetch error (\(error))")
        }
        return result
    }
}


struct TestRecord: FetchableRecord, TableRecord, PersistableRecord, Codable, Hashable {
    var id: Int64?
    var word: String
    var placeId: Int64
    
    static var databaseTableName: String { "Test" }
    static let dbMaxCapacity: Int = 10
    
    enum Columns: String, ColumnExpression {
        case id, word, similarWords, placeId
    }
    
    init(word: String, placeId: Int64) {
        self.word = word
        self.placeId = placeId
    }
    
    init(row: Row) {
        id = row[Columns.id]
        word = row[Columns.word]
        placeId = row[Columns.placeId]
    }
    
    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.word] = word
        container[Columns.placeId] = placeId
    }
}

