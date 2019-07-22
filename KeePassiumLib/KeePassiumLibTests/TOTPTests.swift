//
//  TOTPTests.swift
//  KeePassiumLibTests
//
//  Created by Andrei Popleteev on 2019-07-11.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import XCTest
@testable import KeePassiumLib

class TOTPTests: XCTestCase {
    let seedString = "HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ"
    var seed: ByteArray!
    
    override func setUp() {
        seed = ByteArray(bytes: base32Decode(seedString)!)
    }
    
    private func asFields(_ settingsString: String) -> [EntryField] {
        return [EntryField(name: "otp", value: settingsString, isProtected: true)]
    }
    
    private func asFields(_ seedString: String, _ settingsString: String) -> [EntryField] {
        return [
            EntryField(name: "TOTP Seed", value: seedString, isProtected: true),
            EntryField(name: "TOTP Settings", value: settingsString, isProtected: false)
        ]
    }
    
    // MARK: - Google Auth format
    
    func test1() {
        let uri = "otpauth://totp/ACME%20Co:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co&algorithm=SHA1&digits=4&period=60"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        
        if gen == nil { XCTFail(); return }
        XCTAssert(gen!.seed == seed)
        XCTAssert(gen!.length == 4)
        XCTAssert(gen!.timeStep == 60)
    }

    func test1a() {
        let uri = "otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        
        if gen == nil { XCTFail(); return }
        let trueSeed = ByteArray(bytes: base32Decode("JBSWY3DPEHPK3PXP")!)
        XCTAssert(gen!.seed == trueSeed)
        XCTAssert(gen!.length == 6)
        XCTAssert(gen!.timeStep == 30)
    }

    func test2() {
        let uri = "otpauth://totp/ACME%20Co:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME%20Co"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        
        if gen == nil { XCTFail(); return }
        XCTAssert(gen!.seed == seed)
        XCTAssert(gen!.length == 6)
        XCTAssert(gen!.timeStep == 30)
    }

    func test3() {
        let uri = "otpauth://totp/?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&digits=8&period=123"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        
        if gen == nil { XCTFail(); return }
        XCTAssert(gen!.seed == seed)
        XCTAssert(gen!.length == 8)
        XCTAssert(gen!.timeStep == 123)
    }
    
    func test4() {
        let uri = "otpauth://totp/?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        
        if gen == nil { XCTFail(); return }
        XCTAssert(gen!.seed == seed)
        XCTAssert(gen!.length == 6)
        XCTAssert(gen!.timeStep == 30)
    }
    
    func testMisformat1() {
        let uri = "hello world"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testMisformat2() {
        let uri = "otpauth://something"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testMisformat3() {
        let uri = "otpauth://hotp"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testMisformat4() {
        let uri = "otpauth://totp"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testMisformat5() {
        let uri = "otpauth://totp/?secret="
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testMisformat6() {
        let uri = "otpauth://totp/?secret=WRONG_ONE"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testMisformat7() {
        let uri = "otpauth://totp?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&algorithm=SHA512"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testMisformat8() {
        let uri = "otpauth://totp/ACME%20Co:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&algorithm=SHA1&digits=BBB"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testMisformat9() {
        let uri = "otpauth://totp/ACME%20Co:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&period=AAA"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testMisformat10() {
        let uri = "otpauth://totp/ACME%20Co:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&digits=&period="
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    
    // MARK: - KeeOtp format
    func testKeeOtpFormat1() {
        let uri = "key=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        
        if gen == nil { XCTFail(); return }
        XCTAssert(gen!.seed == seed)
        XCTAssert(gen!.length == 6)
        XCTAssert(gen!.timeStep == 30)
    }
    
    func testKeeOtpFormat2() {
        let uri = "key=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&size=8&step=123"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        
        if gen == nil { XCTFail(); return }
        XCTAssert(gen!.seed == seed)
        XCTAssert(gen!.length == 8)
        XCTAssert(gen!.timeStep == 123)
    }
    
    func testKeeOtpFormat3() {
        let uri = "key=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&size=8&step=123&type=totp&otpHashMode=SHA1"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        
        if gen == nil { XCTFail(); return }
        XCTAssert(gen!.seed == seed)
        XCTAssert(gen!.length == 8)
        XCTAssert(gen!.timeStep == 123)
    }

    func testKeeOtpMisformat1() {
        let uri = "key=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&size=8&step=123&type=totp&otpHashMode=SHA256"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testKeeOtpMisformat2() {
        let uri = "key=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&size=8&step=123&type=hotp"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testKeeOtpMisformat3() {
        let uri = "key=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&size=8&step=-123"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testKeeOtpMisformat4() {
        let uri = "key=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&size=-1&step=123"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testKeeOtpMisformat5() {
        let uri = "key=NOT_A_VALID_BASE32"
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(uri)) as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }

    
    // MARK: - Split format

    func testSplitFormat1() {
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(seedString, "33;6"))
            as? TOTPGeneratorRFC6238
        if gen == nil { XCTFail(); return }
        XCTAssert(gen!.seed == seed)
        XCTAssert(gen!.length == 6)
        XCTAssert(gen!.timeStep == 33)
    }

    func testSplitFormat2() {
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(seedString, "20;8;http://example.com"))
            as? TOTPGeneratorRFC6238
        if gen == nil { XCTFail(); return }
        XCTAssert(gen!.seed == seed)
        XCTAssert(gen!.length == 8)
        XCTAssert(gen!.timeStep == 20)
    }

    func testSplitMisformat1() {
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields("not_a_valid_seed", "20;6"))
            as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testSplitMisformat2() {
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(seedString, "20;"))
            as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
    func testSplitMisformat3() {
        let gen = TOTPGeneratorFactory.makeGenerator(from: asFields(seedString, "-1;8"))
            as? TOTPGeneratorRFC6238
        XCTAssertNil(gen)
    }
}
