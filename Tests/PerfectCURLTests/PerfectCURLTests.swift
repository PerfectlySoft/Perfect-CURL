//
//  PerfectCURLTests.swift
//  PerfectCURL
//
//  Created by Kyle Jessup on 2016-06-06.
//	Copyright (C) 2016 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import XCTest
@testable import PerfectCURL
import cURL
#if os(Linux)
	import LinuxBridge
#endif

class PerfectCURLTests: XCTestCase {

	func testCURL() {
		let url = "https://www.treefrog.ca"
		let curl = CURL(url: url)

		let _ = curl.setOption(CURLOPT_SSL_VERIFYPEER, int: 0)

		XCTAssert(curl.url == url)

		var header = [UInt8]()
		var body = [UInt8]()

		var perf = curl.perform()
		while perf.0 {
			if let h = perf.2 {
				header.append(contentsOf: h)
			}
			if let b = perf.3 {
				body.append(contentsOf: b)
			}
			perf = curl.perform()
		}
		if let h = perf.2 {
			header.append(contentsOf: h)
		}
		if let b = perf.3 {
			body.append(contentsOf: b)
		}
		let perf1 = perf.1
		XCTAssert(perf1 == 0, "\(perf)")

		let response = curl.responseCode
		XCTAssert(response == 200, "\(response)")

		XCTAssert(header.count > 0)
		XCTAssert(body.count > 0)
	}

	func testCURLAsync() {
		let url = "https://www.treefrog.ca"
		let curl = CURL(url: url)

		let _ = curl.setOption(CURLOPT_SSL_VERIFYPEER, int: 0)

		XCTAssert(curl.url == url)

		let clientExpectation = self.expectation(description: "client")

		curl.perform {
			code, header, body in

			XCTAssert(0 == code, "Request error code \(code)")

			let response = curl.responseCode
			XCTAssert(response == 200, "\(response)")
			XCTAssert(header.count > 0)
			XCTAssert(body.count > 0)

			clientExpectation.fulfill()
		}

		self.waitForExpectations(timeout: 10000) {
			_ in

		}
	}

	func testCURLHeader() {
		let url = "https://httpbin.org/headers"
		let header = [("Accept", "application/json"), ("X-Extra", "value123")]

		let curl = CURL(url: url)
        for (n, v) in header {
            let code = curl.setOption(CURLOPT_HTTPHEADER, s: "\(n): \(v)" )
            XCTAssert(code == CURLE_OK)
        }
		let response = curl.performFully()
		XCTAssert(response.0 == 0)

//		let body = UTF8Encoding.encode(bytes: response.2)
//		do {
//			guard
//				let jsonMap = try body.jsonDecode() as? [String: Any],
//				let headers = jsonMap["headers"] as? [String: Any],
//				let accept = headers[header.0] as? String
//				else {
//					XCTAssert(false)
//					return
//			}
//				XCTAssertEqual(accept, header.1)
//		} catch let e {
//			XCTAssert(false, "Exception: \(e)")
//		}
	}
    
    func testPerformFullyShouldReturnResponseCode() {
        let url = "https://httpbin.org/get"
        
        let curl = CURL(url: url)

        let response = curl.performFully()
        XCTAssert(response.0 == 0)
        XCTAssertEqual(response.responseCode, 200)
    }

	func testCURLPost() {
		let url = "https://httpbin.org/post"
		let postParamString = "key1=value1&key2=value2"
		let byteArray = [UInt8](postParamString.utf8)

		do {

			let curl = CURL(url: url)

			let _ = curl.setOption(CURLOPT_POST, int: 1)
			let _ = curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutableRawPointer(mutating: byteArray))
			let _ = curl.setOption(CURLOPT_POSTFIELDSIZE, int: byteArray.count)

			let response = curl.performFully()
			XCTAssert(response.0 == 0)

//			let body = UTF8Encoding.encode(bytes: response.2)
//			do {
//				guard
//					let jsonMap = try body.jsonDecode() as? [String: Any],
//					let form = jsonMap["form"] as? [String: Any],
//					let value1 = form["key1"] as? String,
//					let value2 = form["key2"] as? String
//					else {
//						XCTAssert(false)
//						return
//				}
//				XCTAssertEqual(value1, "value1")
//				XCTAssertEqual(value2, "value2")
//			} catch let e {
//				XCTAssert(false, "Exception: \(e)")
//			}
		}
	}

  func testSMTP () {
    var timestamp = time(nil)
    let now = String(cString: asctime(localtime(&timestamp))!)
    let sender = "judysmith1964@gmx.com"
    let recipient = sender
    let u = UnsafeMutablePointer<UInt8>.allocate(capacity:  MemoryLayout<uuid_t>.size)
    uuid_generate_random(u)
    let unu = UnsafeMutablePointer<Int8>.allocate(capacity:  37)
    uuid_unparse_lower(u, unu)
    let uuid = String(validatingUTF8: unu)!
    u.deallocate(capacity: MemoryLayout<uuid_t>.size)
    unu.deallocate(capacity: 37)

    let content = "Date: \(now)To: \(recipient)\r\nFrom: \(sender)\r\nCc:\r\nBcc:\r\n" +
    "Message-ID: <\(uuid)@perfect.org>\r\n" +
    "Subject: Hello Perfect-CURL\r\n\r\nSMTP test \(now)\r\n\r\n"
    print(content)
    let curl = CURL(url: "smtp://smtp.gmx.com")
    let _ = curl.setOption(CURLOPT_USERNAME, s: sender)
    let _ = curl.setOption(CURLOPT_PASSWORD, s: "abcd1234")
    //let _ = curl.setOption(CURLOPT_USE_SSL, int: Int(CURLUSESSL_ALL.rawValue))
    let _ = curl.setOption(CURLOPT_MAIL_FROM, s: sender)
    let _ = curl.setOption(CURLOPT_MAIL_RCPT, s: recipient)
    let _ = curl.setOption(CURLOPT_VERBOSE, int: 1)
    let _ = curl.setOption(CURLOPT_UPLOAD, int: 1)
    let _ = curl.setOption(CURLOPT_INFILESIZE, int: content.utf8.count)
    var p:[Int32] = [-1, -1]
    let result = pipe(&p)
    XCTAssertEqual(result, 0)
    let fi = fdopen(p[0], "rb")
    let fo = fdopen(p[1], "wb")
    let w = fwrite(content, 1, content.utf8.count, fo)
    fclose(fo)
    XCTAssertEqual(w, content.utf8.count)
    let _ = curl.setOption(CURLOPT_READDATA, v: fi!)
    let r = curl.performFully()
    print(r.0)
    print(String(cString:r.2))
    print(String(cString:r.3))
    fclose(fi)
    XCTAssertEqual(r.0, 0)
  }
	static var allTests : [(String, (PerfectCURLTests) -> () throws -> Void)] {
		return [
			("testCURLPost", testCURLPost),
			("testCURLHeader", testCURLHeader),
			("testPerformFullyShouldReturnResponseCode", testPerformFullyShouldReturnResponseCode),
			("testCURLAsync", testCURLAsync),
			("testSMTP", testSMTP),
			("testCURL", testCURL)
		]
	}
}

