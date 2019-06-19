//
//  DatabaseTests.swift
//  KeePassiumLibTests
//
//  Created by Andrei Popleteev on 2019-04-23.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import XCTest
@testable import KeePassiumLib

class DatabaseTester: NSObject, DatabaseManagerObserver {
    private var loadExpectation: XCTestExpectation?
    private var failExpectation: XCTestExpectation?
    private var saveExpectation: XCTestExpectation?
    private var closeExpectation: XCTestExpectation?
    
    init(load: XCTestExpectation?,
        fail: XCTestExpectation?,
        save: XCTestExpectation?,
        close: XCTestExpectation?
    ) {
        super.init()
        self.loadExpectation = load
        self.failExpectation = fail
        self.saveExpectation = save
        self.closeExpectation = close
    }
    
    func load(dbFileName: String, password: String, keyFileName: String?) {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: dbFileName, withExtension: nil, subdirectory: nil)!
        let dbRef = try! URLReference(from: url, location: .external)
        let dbm = DatabaseManager.shared
        dbm.addObserver(self)
        dbm.startLoadingDatabase(database: dbRef, password: password, keyFile: nil)
    }
    
    func save() {
        let dbm = DatabaseManager.shared
        dbm.startSavingDatabase()
    }
    func close() {
        let dbm = DatabaseManager.shared
        dbm.removeObserver(self)
        dbm.closeDatabase(
            completion: { [weak self] in
                self?.closeExpectation?.fulfill()
            },
            clearStoredKey: true
        )
    }
    
    func databaseManager(willLoadDatabase urlRef: URLReference) {
        // empty
    }
    
    func databaseManager(database urlRef: URLReference, invalidMasterKey message: String) {
        failExpectation?.fulfill()
    }
    
    func databaseManager(didLoadDatabase urlRef: URLReference, warnings: DatabaseLoadingWarnings) {
        loadExpectation?.fulfill()
    }
    
    func databaseManager(database urlRef: URLReference, loadingError message: String, reason: String?) {
        failExpectation?.fulfill()
    }
    
    func databaseManager(willSaveDatabase urlRef: URLReference) {
        // empty
    }
    
    func databaseManager(didSaveDatabase urlRef: URLReference) {
        saveExpectation?.fulfill()
    }
    
    func databaseManager(database urlRef: URLReference, savingError message: String, reason: String?) {
        failExpectation?.fulfill()
    }
}

class DatabaseTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadingKP1_AES_password() {
        let loadExpectation = XCTestExpectation(description: "DB loaded OK")
        let failExpectation = XCTestExpectation(description: "DB loading failed")
        let saveExpectation = XCTestExpectation(description: "DB saving OK")
        let closeExpectation = XCTestExpectation(description: "DB closed OK")
        
        let dbt = DatabaseTester(
            load: loadExpectation,
            fail: failExpectation,
            save: saveExpectation,
            close: closeExpectation)
        dbt.load(dbFileName: "kp1-pw-aes-100k.kdb", password: "demo", keyFileName: nil)
        wait(for: [loadExpectation], timeout: 2.0)
        
        let dbm = DatabaseManager.shared
        let db = dbm.database
        let dbRef = dbm.databaseRef
        XCTAssertNotNil(db)
        XCTAssertNotNil(dbRef)

        let db1 = db as! Database1
        XCTAssert(db1.header.algorithm == .aes)
        
        dbt.close()
        wait(for: [closeExpectation], timeout: 1.0)
        XCTAssertNil(dbm.databaseRef)
        XCTAssertNil(dbm.database)
    }

    func testLoadingKP1_twofish_password() {
        let loadExpectation = XCTestExpectation(description: "DB loaded OK")
        let failExpectation = XCTestExpectation(description: "DB loading failed")
        let saveExpectation = XCTestExpectation(description: "DB saving OK")
        let closeExpectation = XCTestExpectation(description: "DB closed OK")
        
        let dbt = DatabaseTester(
            load: loadExpectation,
            fail: failExpectation,
            save: saveExpectation,
            close: closeExpectation)
        dbt.load(dbFileName: "kp1-pw-2fi-100k.kdb", password: "demo", keyFileName: nil)
        wait(for: [loadExpectation], timeout: 2.0)
        
        let dbm = DatabaseManager.shared
        let db = dbm.database
        let dbRef = dbm.databaseRef
        XCTAssertNotNil(db)
        XCTAssertNotNil(dbRef)
        
        let db1 = db as! Database1
        XCTAssert(db1.header.algorithm == .twofish)
        
        dbt.close()
        wait(for: [closeExpectation], timeout: 1.0)
        XCTAssertNil(dbm.databaseRef)
        XCTAssertNil(dbm.database)
    }

    func testLoadingKP2v3_aes_aesKdf_salsa20_gzip() {
        let loadExpectation = XCTestExpectation(description: "DB loaded OK")
        let failExpectation = XCTestExpectation(description: "DB loading failed")
        let saveExpectation = XCTestExpectation(description: "DB saving OK")
        let closeExpectation = XCTestExpectation(description: "DB closed OK")
        
        let dbt = DatabaseTester(
            load: loadExpectation,
            fail: failExpectation,
            save: saveExpectation,
            close: closeExpectation)
        dbt.load(dbFileName: "v3-pw-aes-aes-s20-gzip-100k.kdbx", password: "demo", keyFileName: nil)
        wait(for: [loadExpectation], timeout: 2.0)
        
        let dbm = DatabaseManager.shared
        let db = dbm.database
        let dbRef = dbm.databaseRef
        XCTAssertNotNil(db)
        XCTAssertNotNil(dbRef)
        
        let db2 = db as! Database2
        XCTAssert(db2.header.isCompressed)
        XCTAssert(db2.header.innerStreamAlgorithm == .Salsa20)
        XCTAssert(db2.header.formatVersion == .v3)
        XCTAssert(db2.header.kdf is AESKDF)
        
        dbt.close()
        wait(for: [closeExpectation], timeout: 1.0)
        XCTAssertNil(dbm.databaseRef)
        XCTAssertNil(dbm.database)
    }
    
    func testLoadingKP2v3_twofish_aesKdf_salsa20_nocomp() {
        let loadExpectation = XCTestExpectation(description: "DB loaded OK")
        let failExpectation = XCTestExpectation(description: "DB loading failed")
        let saveExpectation = XCTestExpectation(description: "DB saving OK")
        let closeExpectation = XCTestExpectation(description: "DB closed OK")
        
        let dbt = DatabaseTester(
            load: loadExpectation,
            fail: failExpectation,
            save: saveExpectation,
            close: closeExpectation)
        dbt.load(dbFileName: "v3-aes-2fi-nocomp.kdbx", password: "demo", keyFileName: nil)
        wait(for: [loadExpectation], timeout: 2.0)
        
        let dbm = DatabaseManager.shared
        let db = dbm.database
        let dbRef = dbm.databaseRef
        XCTAssertNotNil(db)
        XCTAssertNotNil(dbRef)
        
        let db2 = db as! Database2
        XCTAssertFalse(db2.header.isCompressed)
        XCTAssert(db2.header.innerStreamAlgorithm == .Salsa20)
        XCTAssert(db2.header.formatVersion == .v3)
        XCTAssert(db2.header.kdf is AESKDF)
        XCTAssert(db2.header.dataCipher is TwofishDataCipher)
        
        dbt.close()
        wait(for: [closeExpectation], timeout: 1.0)
        XCTAssertNil(dbm.databaseRef)
        XCTAssertNil(dbm.database)
    }
    
    func testLoadingKP2v4_argon2_chacha20_gzip_password() {
        let loadExpectation = XCTestExpectation(description: "DB loaded OK")
        let failExpectation = XCTestExpectation(description: "DB loading failed")
        let saveExpectation = XCTestExpectation(description: "DB saving OK")
        let closeExpectation = XCTestExpectation(description: "DB closed OK")
        
        let dbt = DatabaseTester(
            load: loadExpectation,
            fail: failExpectation,
            save: saveExpectation,
            close: closeExpectation)
        dbt.load(dbFileName: "v4-pw-ar2-c20-c20-gzip.kdbx", password: "demo", keyFileName: nil)
        wait(for: [loadExpectation], timeout: 2.0)
        
        let dbm = DatabaseManager.shared
        let db = dbm.database
        let dbRef = dbm.databaseRef
        XCTAssertNotNil(db)
        XCTAssertNotNil(dbRef)
        
        let db2 = db as! Database2
        XCTAssert(db2.header.isCompressed)
        XCTAssert(db2.header.innerStreamAlgorithm == .ChaCha20)
        XCTAssert(db2.header.formatVersion == .v4)
        XCTAssert(db2.header.kdf is Argon2KDF)
        
        dbt.close()
        wait(for: [closeExpectation], timeout: 1.0)
        XCTAssertNil(dbm.databaseRef)
        XCTAssertNil(dbm.database)
    }
    
    
    func testLoadingKP2v4_argon2_chacha20_nocompression_password() {
        let loadExpectation = XCTestExpectation(description: "DB loaded OK")
        let failExpectation = XCTestExpectation(description: "DB loading failed")
        let saveExpectation = XCTestExpectation(description: "DB saving OK")
        let closeExpectation = XCTestExpectation(description: "DB closed OK")
        
        let dbt = DatabaseTester(
            load: loadExpectation,
            fail: failExpectation,
            save: saveExpectation,
            close: closeExpectation)
        dbt.load(dbFileName: "v4-pw-ar2-c20-c20-nocomp.kdbx", password: "demo", keyFileName: nil)
        wait(for: [loadExpectation], timeout: 2.0)
        
        let dbm = DatabaseManager.shared
        let db = dbm.database
        let dbRef = dbm.databaseRef
        XCTAssertNotNil(db)
        XCTAssertNotNil(dbRef)
        
        let db2 = db as! Database2
        XCTAssertFalse(db2.header.isCompressed)
        XCTAssert(db2.header.innerStreamAlgorithm == .ChaCha20)
        XCTAssert(db2.header.formatVersion == .v4)
        XCTAssert(db2.header.kdf is Argon2KDF)

        dbt.close()
        wait(for: [closeExpectation], timeout: 1.0)
        XCTAssertNil(dbm.databaseRef)
        XCTAssertNil(dbm.database)
    }
    
    func testLoadingKP2v4_argon2_twofish_nocompression_password() {
        let loadExpectation = XCTestExpectation(description: "DB loaded OK")
        let failExpectation = XCTestExpectation(description: "DB loading failed")
        let saveExpectation = XCTestExpectation(description: "DB saving OK")
        let closeExpectation = XCTestExpectation(description: "DB closed OK")
        
        let dbt = DatabaseTester(
            load: loadExpectation,
            fail: failExpectation,
            save: saveExpectation,
            close: closeExpectation)
        dbt.load(dbFileName: "v4-ar2-2fi-nocomp.kdbx", password: "demo", keyFileName: nil)
        wait(for: [loadExpectation], timeout: 2.0)
        
        let dbm = DatabaseManager.shared
        let db = dbm.database
        let dbRef = dbm.databaseRef
        XCTAssertNotNil(db)
        XCTAssertNotNil(dbRef)
        
        let db2 = db as! Database2
        XCTAssertFalse(db2.header.isCompressed)
        XCTAssert(db2.header.innerStreamAlgorithm == .ChaCha20)
        XCTAssert(db2.header.formatVersion == .v4)
        XCTAssert(db2.header.kdf is Argon2KDF)
        XCTAssert(db2.header.dataCipher is TwofishDataCipher)
        
        dbt.close()
        wait(for: [closeExpectation], timeout: 1.0)
        XCTAssertNil(dbm.databaseRef)
        XCTAssertNil(dbm.database)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
