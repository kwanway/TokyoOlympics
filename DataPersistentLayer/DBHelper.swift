//
//  DBHelper.swift
//  TokyoOlympics
//
//  Created by tingo on 2019/5/3.
//  Copyright © 2019 tingo. All rights reserved.
//

import Foundation
import SQLite3

let DB_FILE_NAME = "app.db"

public class DBHelper {
    
    static var db: OpaquePointer? = nil
    
    // Get sand box directory
    static func applicationDocumentsDirectoryFile(_ fileName: String) -> [CChar]? {
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let path = (documentDirectory[0] as AnyObject).appendingPathComponent(DB_FILE_NAME) as String
        
        let cpath = path.cString(using: String.Encoding.utf8)
        
        return cpath
    }
    
    // Initial and load data
    public static func initDB() {
        
        let frameworkBundle = Bundle(for: DBHelper.self)
        let configTablePath = frameworkBundle.path(forResource: "DBConfig", ofType: "plist")
        let configTable = NSDictionary(contentsOfFile: configTablePath!)
        
        // Get data base version from configuration file
        var dbConfigVersion = configTable?["DB_VERSION"] as? NSNumber
        if (dbConfigVersion == nil) {
            dbConfigVersion = 0
        }
        
        // Get database version from database DBVersionInfo record
        let versionNumber = DBHelper.dbVersionNumber()
        
        // Database version not consistent
        if dbConfigVersion?.int32Value != versionNumber {
            let dbFilePath = DBHelper.applicationDocumentsDirectoryFile(DB_FILE_NAME)
            if sqlite3_open(dbFilePath, &db) == SQLITE_OK {
                print("Database updating...")
                let createtablePath = frameworkBundle.path(forResource: "create_load", ofType: "sql")
                let sql = try? NSString(contentsOfFile: createtablePath!, encoding: String.Encoding.utf8.rawValue)
                let cSql = sql?.cString(using: String.Encoding.utf8.rawValue)
                sqlite3_exec(db, cSql, nil, nil, nil)
                
                // Write current version number back to file
                let usql = NSString(format: "update DBVersionInfo set version_number = %i", (dbConfigVersion?.intValue)!)
                let cusql = usql.cString(using: String.Encoding.utf8.rawValue)
                sqlite3_exec(db, cusql, nil, nil, nil)
            } else {
                print("Database open failed.")
            }
            sqlite3_close(db)
        }
    }
    
    public static func dbVersionNumber() -> Int32 {
        
        var versionNumber: Int32 = -1
        
        let dbFilePath = DBHelper.applicationDocumentsDirectoryFile(DB_FILE_NAME)
        
        if sqlite3_open(dbFilePath, &db) == SQLITE_OK {
            let sql = "create table if not exists DBVersionInfo (version_number int)"
            let cSql = sql.cString(using: String.Encoding.utf8)
            
            sqlite3_exec(db, cSql, nil, nil, nil)
            
            let qsql = "select version_number from DBVersionInfo"
            let cqsql = qsql.cString(using: String.Encoding.utf8)
            
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(db, cqsql, -1, &statement, nil) == SQLITE_OK {
                if (sqlite3_step(statement) == SQLITE_ROW) {
                    print("Have data.")
                    versionNumber = Int32(sqlite3_column_int(statement, 0))
                } else {
                    print("Have no data.")
                    let insertSql = "insert into DBVersionInfo (version_number) values(-1)"
                    let cInsertSql = insertSql.cString(using: String.Encoding.utf8)
                    sqlite3_exec(db, cInsertSql, nil, nil, nil)
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        } else {
            sqlite3_close(db)
        }
        return versionNumber
    }
}
