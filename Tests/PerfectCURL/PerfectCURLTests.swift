//
//	PerfectCURLTests.swift
//	PerfectCURL
//
// Created by Kyle Jessup on 2016-06-06.
// Copyright (C) 2016 PerfectlySoft, Inc.
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

		let clientExpectation = self.expectation(withDescription: "client")

		curl.perform {
			code, header, body in

			XCTAssert(0 == code, "Request error code \(code)")

			let response = curl.responseCode
			XCTAssert(response == 200, "\(response)")
			XCTAssert(header.count > 0)
			XCTAssert(body.count > 0)

			clientExpectation.fulfill()
		}

		self.waitForExpectations(withTimeout: 10000) {
			_ in

		}
	}

	func testCURLHeader() {
		let url = "https://httpbin.org/headers"
		let header = ("Accept", "application/json")

		let curl = CURL(url: url)
		let _ = curl.setOption(CURLOPT_HTTPHEADER, s: "\(header.0): \(header.1)" )
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

	func testCURLPost() {
		let url = "https://httpbin.org/post"
		let postParamString = "key1=value1&key2=value2"
		let byteArray = [UInt8](postParamString.utf8)

		do {

			let curl = CURL(url: url)

			let _ = curl.setOption(CURLOPT_POST, int: 1)
			let _ = curl.setOption(CURLOPT_POSTFIELDS, v: UnsafeMutablePointer<UInt8>(byteArray))
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

	static var allTests : [(String, (PerfectCURLTests) -> () throws -> Void)] {
		return [
			("testCURLPost", testCURLPost),
			("testCURLHeader", testCURLHeader),
			("testCURLAsync", testCURLAsync),
			("testCURL", testCURL)
		]
	}
}

