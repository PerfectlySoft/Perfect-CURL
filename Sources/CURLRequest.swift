//
//  CURLRequest.swift
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
import PerfectNet
import PerfectThread

/// Creates and configures a CURL request.
/// init with a URL and zero or more options.
/// Call .perform to get the CURLResponse
open class CURLRequest {
	typealias POSTFields = CURL.POSTFields
	/// A header which can be added to the request.
	public typealias Header = HTTPRequestHeader
	/// A POST name/value field. Can indicate a file upload by giving a file path.
	public struct POSTField {
		enum FieldType { case value, file }
		let name: String
		let value: String
		let mimeType: String?
		let type: FieldType
		/// Init with a name, value and optional mime-type.
		public init(name: String, value: String, mimeType: String? = nil) {
			self.name = name
			self.value = value
			self.type = .value
			self.mimeType = mimeType
		}
		/// Init with a name, file path and optional mime-type.
		public init(name: String, filePath: String, mimeType: String? = nil) {
			self.name = name
			self.value = filePath
			self.type = .file
			self.mimeType = mimeType
		}
	}
	/// The HTTP method to set explicitly.
	public typealias HTTPMethod = PerfectHTTP.HTTPMethod
	/// The numerous options which can be set. Each enum case indicates the parameter type(s) for the option.
	public enum Option {
		case url(String),
		port(Int),
		failOnError, // fail on http error codes >= 400
		
		userPwd(String),
		
		proxy(String), proxyUserPwd(String), proxyPort(Int),
		
		timeout(Int),
		connectTimeout(Int),
		lowSpeedLimit(Int), lowSpeedTime(Int),
		
		range(String),
		resumeFrom(Int),
		
		cookie(String), cookieFile(String), cookieJar(String),
		
		followLocation(Bool), maxRedirects(Int),
		
		maxConnects(Int),
		autoReferer(Bool),
		krbLevel(String),
		
		addHeader(Header.Name, String), // add header
		addHeaders([(Header.Name, String)]), // add headers
		replaceHeader(Header.Name, String), // add/replace header
		removeHeader(Header.Name),
		
		sslCert(String), sslCertType(String),
		sslKey(String), sslKeyPwd(String), sslKeyType(String),
		sslVersion(TLSMethod),
		sslVerifyPeer(Bool), sslVerifyHost(Bool),
		sslCAInfo(String), sslCAPath(String),
		sslCiphers([String]), sslPinnedPublicKey(String),
		
		ftpPreCommands([String]), ftpPostCommands([String]),
		ftpPort(String), ftpResponseTimeout(Int),
		
		sshPublicKey(String), sshPrivateKey(String),
		
		httpMethod(HTTPMethod),
		postField(POSTField), postData([UInt8]), postString(String),
		
		mailFrom(String), mailRcpt(String)
	}
	
	let curl: CURL
	/// Mutable options array for the request. These options are cleared when the request is .reset()
	public var options: [Option]
	var postFields: POSTFields?
	/// Init with a url and options array.
	public convenience init(_ url: String, options: [Option] = []) {
		self.init(options: [.url(url)] + options)
	}
	/// Init with url and one or more options.
	public convenience init(_ url: String, _ option1: Option, _ options: Option...) {
		self.init(options: [.url(url)] + [option1] + options)
	}
	/// Init with array of options.
	public init(options: [Option] = []) {
		curl = CURL()
		self.options = options
	}
	
	func applyOptions() {
		options.forEach { $0.apply(to: self) }
		if let postFields = self.postFields {
			curl.formAddPost(fields: postFields)
		}
	}
}

public extension CURLRequest {
	/// Execute the request synchronously. 
	/// Returns the response or throws an Error.
	func perform() throws -> CURLResponse {
		applyOptions()
		let resp = CURLResponse(curl)
		try resp.complete()
		return resp
	}
	
	/// Execute the request asynchronously.
	/// The parameter passed to the completion callback must be called to obtain the response or throw an Error.
	func perform(_ completion: @escaping (CURLResponse.Confirmation) -> ()) {
		applyOptions()
		CURLResponse(curl).complete(completion)
	}
	
	/// Execute the request asynchronously. 
	/// Returns a Promise object which can be used to monitor the operation.
	func promise() -> Promise<CURLResponse> {
		return Promise {
			p in
			self.perform {
				confirmation in
				do {
					p.set(try confirmation())
				} catch {
					p.fail(error)
				}
			}
		}
	}
	
	/// Reset the request. Clears all options so that the object can be reused.
	/// New options can be provided.
	func reset(_ options: [Option] = []) {
		curl.reset()
		postFields = nil
		self.options = options
	}
	
	/// Reset the request. Clears all options so that the object can be reused.
	/// New options can be provided.
	func reset(_ option: Option, _ options: Option...) {
		reset([option] + options)
	}
}

public extension CURLRequest {
	/// Add a header to the response.
	/// No check for duplicate or repeated headers will be made.
	func addHeader(_ named: Header.Name, value: String) {
		options.append(.addHeader(named, value))
	}
	/// Set the indicated header value.
	/// If the header already exists then the existing value will be replaced.
	func replaceHeader(_ named: Header.Name, value: String) {
		options.append(.replaceHeader(named, value))
	}
	/// Remove the indicated header.
	func removeHeader(_ named: Header.Name) {
		options.append(.removeHeader(named))
	}
}

