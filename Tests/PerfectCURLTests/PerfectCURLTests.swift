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
import PerfectLib

class PerfectCURLTests: XCTestCase {
	
	let headersTestURL = "https://httpbin.org/headers"
	let postTestURL = "https://httpbin.org/post"
	let putTestURL = "https://httpbin.org/put"
	let errorTestURL = "https://httpbin.org/status/500"
	
	func testCURLError() {
		let url = errorTestURL
		let request = CURLRequest(url, .failOnError)
		do {
			_ = try request.perform()
			XCTAssert(false, "500 response did not fail.")
		} catch let error as CURLResponse.Error {
			XCTAssertEqual(error.response.responseCode, 500)
		} catch {
			XCTAssert(false, "\(error)")
		}
	}
	
	func testCURLSync() {
		let url = headersTestURL
		let request = CURLRequest(url, .failOnError)
		do {
			let response = try request.perform()
			let responseCode = response.responseCode
			XCTAssertEqual(responseCode, 200)
			XCTAssertEqual(response.url, url)
			XCTAssertEqual(response.get(.connection), "keep-alive")
			XCTAssertGreaterThan(response.get(.totalTime) ?? 0.0, 0.0)
			XCTAssertGreaterThan(response.headers.count, 0)
			XCTAssertGreaterThan(response.bodyBytes.count, 0)
		} catch {
			XCTAssert(false, "\(error)")
		}
		
		request.reset(.url(headersTestURL))
		
		do {
			let response = try request.perform()
			let responseCode = response.responseCode
			XCTAssertEqual(responseCode, 200)
			XCTAssertEqual(response.url, url)
			XCTAssertGreaterThan(response.headers.count, 0)
			XCTAssertGreaterThan(response.bodyBytes.count, 0)
		} catch {
			XCTAssert(false, "\(error)")
		}
	}

	func testCURLAsync() {
		let clientExpectation = self.expectation(description: "client")
		let url = headersTestURL
		
		CURLRequest(url, .failOnError).perform {
			confirmation in
			do {
				let response = try confirmation()
				XCTAssertEqual(response.responseCode, 200)
				XCTAssertGreaterThan(response.headers.count, 0)
				XCTAssertGreaterThan(response.bodyBytes.count, 0)
			} catch {
				XCTAssert(false, "\(error)")
			}
			clientExpectation.fulfill()
		}
		self.waitForExpectations(timeout: 10000)
	}
	
	func testCURLPromise() {
		let url = headersTestURL
		
		do {
			let responseCode = try CURLRequest(url, .failOnError).promise().then {
					return try $0().responseCode
				}.wait()
			XCTAssertNotNil(responseCode)
			XCTAssertEqual(responseCode ?? 0, 200)
		} catch {
			XCTAssert(false, "\(error)")
		}
	}

	func testCURLHeader() {
		let url = headersTestURL
		let accept = CURLRequest.Header.Name.accept
		let custom = CURLRequest.Header.Name.custom(name: "X-Extra")
		let custom2 = CURLRequest.Header.Name.custom(name: "X-Extra-2")
		let customValueFalse = "notValue123"
		let customValue = "value123"
		
		let request = CURLRequest(url, .failOnError,
		                          .addHeader(custom, customValueFalse),
		                          .addHeader(custom2, ""),
		                          .removeHeader(accept),
		                          .replaceHeader(custom, customValue))
		                          
		do {
			let response = try request.perform()
			let json = response.bodyJSON
			guard let headers = json["headers"] as? [String:Any],
					let resCustom = headers[custom.standardName] as? String,
					let resCustom2 = headers[custom2.standardName] as? String else {
				return XCTAssert(false, "\(custom.standardName) not found in \(json)")
			}
			XCTAssertNil(headers[accept.standardName])
			XCTAssertEqual(customValue, resCustom)
			XCTAssertEqual("", resCustom2)
		} catch {
			XCTAssert(false, "\(error)")
		}
	}
	
	func testCURLHeader2() {
		let url = headersTestURL
		let accept = CURLRequest.Header.Name.accept
		let custom = CURLRequest.Header.Name.custom(name: "X-Extra")
		let customValueFalse = "notValue123"
		let customValue = "value123"
		
		let request = CURLRequest(url, .failOnError)
		request.addHeader(custom, value: customValueFalse)
		request.removeHeader(accept)
		request.replaceHeader(custom, value: customValue)
		
		do {
			let response = try request.perform()
			let json = response.bodyJSON
			guard let headers = json["headers"] as? [String:Any],
				let resCustom = headers[custom.standardName] as? String else {
					return XCTAssert(false, "\(accept.standardName) or \(custom.standardName) not found in \(json)")
			}
			XCTAssertNil(headers[accept.standardName])
			XCTAssertEqual(customValue, resCustom)
		} catch {
			XCTAssert(false, "\(error)")
		}
	}
	
	func testCURLPostString() {
		let url = postTestURL
		let postParamString = "key1=value1&key2=value2"
		
		do {
			let json = try CURLRequest(url, .postString(postParamString), .failOnError).perform().bodyJSON
			guard let form = json["form"] as? [String:Any],
				let key1 = form["key1"] as? String,
				let key2 = form["key2"] as? String else {
					return XCTAssert(false, "key1 or key2 not found in \(json)")
			}
			XCTAssertEqual(key1, "value1")
			XCTAssertEqual(key2, "value2")
			return
		} catch {
			XCTAssert(false, "\(error)")
		}
	}
	
	func testCURLPostData() {
		let url = postTestURL
		let postParamString = "key1=value1&key2=value2"
		
		do {
			let json = try CURLRequest(url, .postData(Array(postParamString.utf8)), .failOnError).perform().bodyJSON
			guard let form = json["form"] as? [String:Any],
				let key1 = form["key1"] as? String,
				let key2 = form["key2"] as? String else {
					return XCTAssert(false, "key1 or key2 not found in \(json)")
			}
			XCTAssertEqual(key1, "value1")
			XCTAssertEqual(key2, "value2")
			return
		} catch {
			XCTAssert(false, "\(error)")
		}
	}
	
	func testCURLPutData() {
		let url = putTestURL
		let postParamString = "key1=value1&key2=value2"
		
		do {
			let response = try CURLRequest(url, .httpMethod(.put), .postData(Array(postParamString.utf8))).perform()
			let json = response.bodyJSON
			guard let form = json["form"] as? [String:Any],
				let key1 = form["key1"] as? String,
				let key2 = form["key2"] as? String else {
					return XCTAssert(false, "key1 or key2 not found in \(json)")
			}
			XCTAssertEqual(key1, "value1")
			XCTAssertEqual(key2, "value2")
			return
		} catch {
			XCTAssert(false, "\(error)")
		}
	}
	
	func testCURLHead() {
		let url = headersTestURL
		let postParamString = "key1=value1&key2=value2"
		
		do {
			let response = try CURLRequest(url, .httpMethod(.head), .postData(Array(postParamString.utf8))).perform()
			let json = response.bodyJSON
			let code = response.responseCode
			XCTAssertEqual(code, 200)
			XCTAssertEqual(json.count, 0)
			return
		} catch {
			XCTAssert(false, "\(error)")
		}
	}
	
	func testGithubBadResponse() {
		do {
			// github error responses, at least the 403, is malformed
			// this test ensures that even with a bad response the header parsing is correct
			let url = "https://api.github.com/orgs/perfectlysoft/repos"
			let response = try CURLRequest(url).perform()
			XCTAssert(response.responseCode == 403) // no user-agent caused this request to fail
			XCTAssertEqual(response.get(.connection), "close")
		} catch {
			XCTAssert(false, "\(error)")
		}
	}
	
	func testCURLPostFields() {
		let url = postTestURL
		let testFileContents = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		do {
			let testFile = TemporaryFile(withPrefix: "test")
			try testFile.open(.truncate)
			defer { testFile.delete() }
			try testFile.write(string: testFileContents)
			testFile.close()
			let json = try CURLRequest(url, .failOnError,
			                           .postField(.init(name: "key1", value: "value 1")),
			                           .postField(.init(name: "key2", value: "value 2")),
			                           .postField(.init(name: "file1", filePath: testFile.path, mimeType: "text/plain")))
											.perform().bodyJSON
			guard let form = json["form"] as? [String:Any],
				let key1 = form["key1"] as? String,
				let key2 = form["key2"] as? String else {
					return XCTAssert(false, "key1 or key2 not found in \(json)")
			}
			
			XCTAssertEqual(key1, "value 1")
			XCTAssertEqual(key2, "value 2")
			
			guard let files = json["files"] as? [String:Any],
				let file1 = files["file1"] as? String else {
					return XCTAssert(false, "files or file1 not found in \(json)")
			}
			XCTAssertEqual(file1, testFileContents)
		} catch {
			XCTAssert(false, "\(error)")
		}
	}
	
	func testCURLPostFields2() {
		let url = postTestURL
		let clientExpectation = self.expectation(description: "client")
		let formData = ["key1":"value 1", "key2":"value 2"]
		let options = formData.map { CURLRequest.Option.postField(.init(name: $0, value: $1)) }
		
		CURLRequest(url, options: options).perform {
			confirmation in
			do {
				let response = try confirmation()
				XCTAssertEqual(response.responseCode, 200)
				let json = response.bodyJSON
				guard let form = json["form"] as? [String:Any],
					let key1 = form["key1"] as? String,
					let key2 = form["key2"] as? String else {
						return XCTAssert(false, "key1 or key2 not found in \(json)")
				}
				
				XCTAssertEqual(key1, "value 1")
				XCTAssertEqual(key2, "value 2")
			} catch {
				XCTAssert(false, "\(error)")
			}
			clientExpectation.fulfill()
		}
		self.waitForExpectations(timeout: 10000)
	}

//  func testSMTP () {
//    var timestamp = time(nil)
//    let now = String(cString: asctime(localtime(&timestamp))!)
//    let sender = "judysmith1964@gmx.com"
//    let recipient = sender
//    let u = UnsafeMutablePointer<UInt8>.allocate(capacity:  MemoryLayout<uuid_t>.size)
//    uuid_generate_random(u)
//    let unu = UnsafeMutablePointer<Int8>.allocate(capacity:  37)
//    uuid_unparse_lower(u, unu)
//    let uuid = String(validatingUTF8: unu)!
//    u.deallocate(capacity: MemoryLayout<uuid_t>.size)
//    unu.deallocate(capacity: 37)
//
//    let content = "Date: \(now)To: \(recipient)\r\nFrom: \(sender)\r\nCc:\r\nBcc:\r\n" +
//    "Message-ID: <\(uuid)@perfect.org>\r\n" +
//    "Subject: Hello Perfect-CURL\r\n\r\nSMTP test \(now)\r\n\r\n"
//    let curl = CURL(url: "smtp://smtp.gmx.com")
//    let _ = curl.setOption(CURLOPT_USERNAME, s: sender)
//    let _ = curl.setOption(CURLOPT_PASSWORD, s: "abcd1234")
//    let _ = curl.setOption(CURLOPT_MAIL_FROM, s: sender)
//    let _ = curl.setOption(CURLOPT_MAIL_RCPT, s: recipient)
//    let _ = curl.setOption(CURLOPT_VERBOSE, int: 1)
//    let _ = curl.setOption(CURLOPT_UPLOAD, int: 1)
//    let _ = curl.setOption(CURLOPT_INFILESIZE, int: content.utf8.count)
//    var p:[Int32] = [-1, -1]
//    let result = pipe(&p)
//    XCTAssertEqual(result, 0)
//    let fi = fdopen(p[0], "rb")
//    let fo = fdopen(p[1], "wb")
//    let w = fwrite(content, 1, content.utf8.count, fo)
//    fclose(fo)
//    XCTAssertEqual(w, content.utf8.count)
//    let _ = curl.setOption(CURLOPT_READDATA, v: fi!)
//    let r = curl.performFully()
//    print(r.0)
//    print(String(cString:r.1))
//    print(String(cString:r.2))
//    fclose(fi)
//    XCTAssertEqual(r.0, 0)
//  }
	
	static var allTests : [(String, (PerfectCURLTests) -> () throws -> Void)] {
		return [
			("testCURLSync", testCURLSync),
			("testCURLAsync", testCURLAsync),
			("testCURLHeader", testCURLHeader),
			("testCURLHeader2", testCURLHeader2),
			("testCURLPostString", testCURLPostString),
			("testCURLPostFields", testCURLPostFields)
		]
	}
}

