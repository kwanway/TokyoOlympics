//
//  BaseDAO.swift
//  TokyoOlympics
//
//  Created by tingo on 2019/5/2.
//  Copyright © 2019 tingo. All rights reserved.
//

import Foundation
import SQLite3

public class BaseDAO: NSObject {
    
    internal var db: OpaquePointer? = nil
    
    override init() {
        
        DBHelper.initDB()
    }
    
    internal func openDB() -> Bool {
        
        let dbFilePath = DBHelper.applicationDocumentsDirectoryFile(DB_FILE_NAME)!
        
        print("DbFilePath = \(String(cString: dbFilePath))")
        
        if sqlite3_open(dbFilePath, &db) != SQLITE_OK {
            sqlite3_close(db)
            print("Database Open failed.")
            return false
        }
        return true
    }
    
    // Get segment data
    internal func getColumnValue(index: CInt, stmt: OpaquePointer) -> String? {
        
        if let ptr = UnsafeRawPointer.init(sqlite3_column_text(stmt, index)) {
            let uptr = ptr.bindMemory(to: CChar.self, capacity: 0)
            let txt = String(validatingUTF8: uptr)
            return txt
        }
        return nil
    }
    
}
