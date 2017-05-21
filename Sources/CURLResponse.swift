//
//  CURLResponse.swift
//  PerfectCURL
//
//  Created by Kyle Jessup on 2017-05-10.
//	Copyright (C) 2017 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2017 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import cURL
import PerfectHTTP
import PerfectCrypto
import PerfectLib

enum ResponseReadState {
	case status, headers, body
}

/// Response for a CURLRequest. 
/// Obtained by calling CURLResponse.perform.
open class CURLResponse {
	/// A response header that can be retreived.
	public typealias Header = HTTPResponseHeader
	/// A confirmation func thats used to obtain an asynchrnous response.
	public typealias Confirmation = () throws -> CURLResponse
	
	// TODO
//	public struct ProgressReport {
//		let downloadTotal: Int
//		let downloadNow: Int
//		let uploadTotal: Int
//		let uploadNow: Int
//	}
	
	/// An error thrown while retrieving a response.
	public struct Error: Swift.Error {
		/// The curl specific request response code.
		public let code: Int
		/// The string message for the curl response code.
		public let description: String
		/// The response object for this error.
		public let response: CURLResponse
		
		init(_ response: CURLResponse, code: CURLcode) {
			self.code = Int(code.rawValue)
			self.description = response.curl.strError(code: code)
			self.response = response
		}
	}
	
	/// Enum wrapping the typed response info keys.
	public enum Info {
		/// Info keys with String values.
		public enum StringValue {
			case url,
				ftpEntryPath,
				redirectURL,
				localIP,
				primaryIP,
				contentType
		}
		/// Info keys with Int values.
		public enum IntValue {
			case responseCode,
				headerSize,
				requestSize,
				sslVerifyResult,
				fileTime,
				redirectCount,
				httpConnectCode,
				httpAuthAvail,
				proxyAuthAvail,
				osErrno,
				numConnects,
				conditionUnmet,
				primaryPort,
				localPort
//				httpVersion // not supported on ubuntu 16 curl??
		}
		/// Info keys with Double values.
		public enum DoubleValue {
			case totalTime,
			nameLookupTime,
			connectTime,
			preTransferTime,
			sizeUpload,
			sizeDownload,
			speedDownload,
			speedUpload,
			contentLengthDownload,
			contentLengthUpload,
			startTransferTime,
			redirectTime,
			appConnectTime 
		}
//		cookieList, // SLIST
//		certInfo // SLIST
	}
	
	let curl: CURL
	var headers = Array<(Header.Name, String)>()
	/// The response's raw content body bytes.
	public internal(set) var bodyBytes = [UInt8]()
	
	var readState = ResponseReadState.status
	
	init(_ curl: CURL) {
		self.curl = curl
	}
}

public extension CURLResponse {
	/// Get an response info String value.
	func get(_ stringValue: Info.StringValue) -> String? {
		return stringValue.get(self)
	}
	/// Get an response info Int value.
	func get(_ intValue: Info.IntValue) -> Int? {
		return intValue.get(self)
	}
	/// Get an response info Double value.
	func get(_ doubleValue: Info.DoubleValue) -> Double? {
		return doubleValue.get(self)
	}
	/// Get a response header value. Returns the first found instance or nil.
	func get(_ header: Header.Name) -> String? {
		return headers.first { header.standardName == $0.0.standardName }?.1
	}
	/// Get a response header's values. Returns all found instances.
	func get(all header: Header.Name) -> [String] {
		return headers.filter { header.standardName == $0.0.standardName }.map { $0.1 }
	}
}

extension CURLResponse {
	func complete() throws {
		setCURLOpts()
		curl.addSLists()
		let resultCode = curl_easy_perform(curl.curl)
		guard CURLE_OK == resultCode else {
			throw Error(self, code: resultCode)
		}
	}
	
	func complete(_ callback: @escaping (Confirmation) -> ()) {
		setCURLOpts()
		innerComplete(callback)
	}
	
	private func innerComplete(_ callback: @escaping (Confirmation) -> ()) {
		let (notDone, resultCode, _, _) = curl.perform()
		guard Int(CURLE_OK.rawValue) == resultCode else {
			return callback({ throw Error(self, code: CURLcode(rawValue: UInt32(resultCode))) })
		}
		if notDone {
			curl.ioWait {
				self.innerComplete(callback)
			}
		} else {
			callback({ return self })
		}
	}
	
	private func addHeaderLine(_ ptr: UnsafeBufferPointer<UInt8>) {
		if readState == .status {
			readState = .headers
		} else if ptr.count == 0 {
			readState = .body
		} else {
			let colon = 58 as UInt8, space = 32 as UInt8
			var pos = 0
			let max = ptr.count
			
			var tstNamePtr: UnsafeBufferPointer<UInt8>?
			
			while pos < max {
				defer {	pos += 1 }
				if ptr[pos] == colon {
					tstNamePtr = UnsafeBufferPointer(start: ptr.baseAddress, count: pos)
					if ptr[pos+1] == space {
						pos += 1
					}
					break
				}
			}
			guard let namePtr = tstNamePtr, let base = ptr.baseAddress else {
				return
			}
			
			let valuePtr = UnsafeBufferPointer(start: base+pos, count: max-pos)			
			let name = UTF8Encoding.encode(generator: namePtr.makeIterator())
			let value = UTF8Encoding.encode(generator: valuePtr.makeIterator())
			headers.append((Header.Name.fromStandard(name: name), value))
		}
	}
	
	private func addBodyData(_ ptr: UnsafeBufferPointer<UInt8>) {
		bodyBytes.append(contentsOf: ptr)
	}
	
	private func setCURLOpts() {
		let opaqueMe = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
		curl.setOption(CURLOPT_HEADERDATA, v: opaqueMe)
		curl.setOption(CURLOPT_WRITEDATA, v: opaqueMe)
		
		do {
			let readFunc: curl_func = {
				a, size, num, p -> Int in
				let crl = Unmanaged<CURLResponse>.fromOpaque(p!).takeUnretainedValue()
				if let bytes = a?.assumingMemoryBound(to: UInt8.self) {
					let fullCount = size*num
					crl.addHeaderLine(UnsafeBufferPointer(start: bytes, count: fullCount-2))
					return fullCount
				}
				return 0
			}
			curl.setOption(CURLOPT_HEADERFUNCTION, f: readFunc)
		}
		
		do {
			let readFunc: curl_func = {
				a, size, num, p -> Int in
				let crl = Unmanaged<CURLResponse>.fromOpaque(p!).takeUnretainedValue()
				if let bytes = a?.assumingMemoryBound(to: UInt8.self) {
					let fullCount = size*num
					crl.addBodyData(UnsafeBufferPointer(start: bytes, count: fullCount))
					return fullCount
				}
				return 0
			}
			curl.setOption(CURLOPT_WRITEFUNCTION, f: readFunc)
		}
	}
}

public extension CURLResponse {
	/// Get the URL which the request may have been redirected to.
	public var url: String { return get(.url) ?? "" }
	/// Get the HTTP response code
	public var responseCode: Int { return get(.responseCode) ?? 0 }
	/// Get the response body converted from UTF-8.
	public var bodyString: String { return UTF8Encoding.encode(bytes: self.bodyBytes) }
	/// Get the response body decoded from JSON into a [String:Any] dictionary.
	/// Invalid/non-JSON body data will result in an empty dictionary being returned.
	public var bodyJSON: [String:Any] { do { return try bodyString.jsonDecode() as? [String:Any] ?? [:] } catch { return [:] } }
}









