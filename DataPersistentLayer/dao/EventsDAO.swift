//
//  EventsDAO.swift
//  TokyoOlympics
//
//  Created by tingo on 2019/5/2.
//  Copyright © 2019 tingo. All rights reserved.
//

import Foundation
import SQLite3

public class EventsDAO: BaseDAO {
    
    // Insert data
    public func create(_ model: Events) -> Int {
    
        if self.openDB() {
            let sql = "INSERT INTO Events (EventName, EventIcon, KeyInfo, BasicsInfo, OlympicInfo VALUES (?,?,?,?,?)"
            let cSql = sql.cString(using: String.Encoding.utf8)
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(db, cSql, -1, &statement, nil) == SQLITE_OK {
                
                let cEventName = model.EventName?.cString(using: String.Encoding.utf8)
                let cEventIcon = model.EventIcon?.cString(using: String.Encoding.utf8)
                let cKeyInfo = model.KeyInfo?.cString(using: String.Encoding.utf8)
                let cBasicsInfo = model.BasicsInfo?.cString(using: String.Encoding.utf8)
                let cOlympicInfo = model.OlympicInfo?.cString(using: String.Encoding.utf8)
                
                sqlite3_bind_text(statement, 1, cEventName, -1, nil)
                sqlite3_bind_text(statement, 2, cEventIcon, -1, nil)
                sqlite3_bind_text(statement, 3, cKeyInfo, -1, nil)
                sqlite3_bind_text(statement, 4, cBasicsInfo, -1, nil)
                sqlite3_bind_text(statement, 5, cOlympicInfo, -1, nil)
                
                if (sqlite3_step(statement) != SQLITE_DONE) {
                    sqlite3_finalize(statement)
                    sqlite3_close(db)
                    assert(false, "Insert data failed.")
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }
        return 0
    }
    
    // Delete data
    public func remove(model: Events) -> Int {
        if self.openDB() {
            
            // Delete Slave table (Shedule Table) data first
            let sqlScheduleStr = String(format: "DELETE from Schedule where EventID=%i", model.EventID!)
            let cSqlScheduleStr = sqlScheduleStr.cString(using: String.Encoding.utf8)
            
            // Commit the last issue before executing
            sqlite3_exec(db, "BEGIN IMMEDIATE TRANSACTION", nil, nil, nil)
            
            if sqlite3_exec(db, cSqlScheduleStr, nil, nil, nil) != SQLITE_OK {
                
                // Roll back issue
                sqlite3_exec(db, "ROLLBACK TRANSACTION", nil, nil, nil)
                assert(false, "Delete data failed.")
            }
            
            // Delete the Events table value
            let sqlEventsStr = String(format: "DELETE from Events where EventID=%i", model.EventID!)
            let cSqlEventsStr = sqlEventsStr.cString(using: String.Encoding.utf8)
            if sqlite3_exec(db, cSqlEventsStr, nil, nil, nil) != SQLITE_OK {
                // Roll back issue
                sqlite3_exec(db, "ROLLBACK TRANSACTION", nil, nil, nil)
                assert(false, "Delete data failed.")
            }
            
            // Commit issue
            sqlite3_exec(db, "COMMIT TRASACTION", nil, nil, nil)
            sqlite3_close(db)
        }
        return 0
    }
    
    
    public func findAll() -> [Events] {
     
        var listData = [Events]()
        
        if self.openDB() {
            
            let sql = "SELECT EventName, EventIcon, KeyInfo, BasicsInfo, OlympicInfo, EventID FROM Events"
            let cSql = sql.cString(using: String.Encoding.utf8)
            
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(db, cSql, -1, &statement, nil) == SQLITE_OK {
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    let events = Events()
                    
                    if let strEventName = getColumnValue(index: 0, stmt: statement!) {
                        events.EventName = strEventName
                    }
                    
                    if let strEventIcon = getColumnValue(index: 1, stmt: statement!) {
                        events.EventIcon = strEventIcon
                    }
                    
                    if let strKeyInfo = getColumnValue(index: 2, stmt: statement!) {
                        events.KeyInfo = strKeyInfo
                    }
                    
                    if let strBaseInfo = getColumnValue(index: 3, stmt: statement!) {
                        events.BasicsInfo = strBaseInfo
                    }
                    
                    if let strOlympicInfo = getColumnValue(index: 4, stmt: statement!) {
                        events.OlympicInfo = strOlympicInfo
                    }
                    
                    events.EventID = Int(sqlite3_column_int(statement, 5))
                    listData.append(events)
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }
        return listData
    }
    
}
