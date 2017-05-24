# Perfect-CURL

<p align="center">
    <a href="http://perfect.org/get-involved.html" target="_blank">
        <img src="http://perfect.org/assets/github/perfect_github_2_0_0.jpg" alt="Get Involed with Perfect!" width="854" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/PerfectlySoft/Perfect" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_1_Star.jpg" alt="Star Perfect On Github" />
    </a>  
    <a href="http://stackoverflow.com/questions/tagged/perfect" target="_blank">
        <img src="http://www.perfect.org/github/perfect_gh_button_2_SO.jpg" alt="Stack Overflow" />
    </a>  
    <a href="https://twitter.com/perfectlysoft" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_3_twit.jpg" alt="Follow Perfect on Twitter" />
    </a>  
    <a href="http://perfect.ly" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_4_slack.jpg" alt="Join the Perfect Slack" />
    </a>
</p>

<p align="center">
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat" alt="Swift 3.0">
    </a>
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Platforms-OS%20X%20%7C%20Linux%20-lightgray.svg?style=flat" alt="Platforms OS X | Linux">
    </a>
    <a href="http://perfect.org/licensing.html" target="_blank">
        <img src="https://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat" alt="License Apache">
    </a>
    <a href="http://twitter.com/PerfectlySoft" target="_blank">
        <img src="https://img.shields.io/badge/Twitter-@PerfectlySoft-blue.svg?style=flat" alt="PerfectlySoft Twitter">
    </a>
    <a href="http://perfect.ly" target="_blank">
        <img src="http://perfect.ly/badge.svg" alt="Slack Status">
    </a>
</p>

This package provides support for [curl](https://curl.haxx.se) in Swift. This package builds with Swift Package Manager and is part of the [Perfect](https://github.com/PerfectlySoft/Perfect) project.

Ensure you have installed and activated the latest Swift 3.1+ tool chain.

## Building

Add this project as a dependency in your Package.swift file.

```
.Package(url: "https://github.com/PerfectlySoft/Perfect-CURL.git", majorVersion: 2)
```

### Linux Build Notes

Ensure that you have installed libcurl.

```
sudo apt-get install libcurl4-openssl-dev
```

## Usage

This package uses a simple request/response model to access URL contents. Start by creating a `CURLRequest` object and configure it according to your needs, then ask it to perform the request and return a response. Responses are represented by `CURLResponse` objects.

Requests can be executed either synchronously - blocking the calling thread until the request completes, asynchronously - delivering the response to a callback, or through a Promise object - performing the request on a background thread giving you a means to chain additional tasks, poll, or wait for completion.

### Creating Requests

`CURLRequest` objects can be created with a URL and a series of options, or they can be created blank and then fully configured. `CURLRequest` provides the following initializers:

```swift
open class CURLRequest {
	// Init with a url and options array.
	public convenience init(_ url: String, options: [Option] = [])
	/// Init with url and one or more options.
	public convenience init(_ url: String, _ option1: Option, _ options: Option...)
	/// Init with array of options.
	public init(options: [Option] = [])
}
```

Options can be provided using either `Array<Option>` or variadic parameters. Options can also be directly added to the `CURLRequest.options` property before the request is executed.

### Configuring Requests

`CURLRequest` options are represented by the `CURLRequest.Option` enum. Each enum case will have zero or more associated values which indicate the parameters for the particular option. For example, the URL for the request could be indicated with the option `.url("https://httpbin.org/post")`.

### Fetching Responses

To perform a request, call one of the `CURLRequest.perform` or `CURLRequest.promise` functions. If the request is successful then you will be provided a `CURLResponse` object which can be used to get response data. If the request fails then a `CURLResponse.Error` will be thrown. A request may fail if it is unable to connect, times out, receives a malformed response, or receives a HTTP response with a status code equal to or greater than 400 when the `.failOnError` option is given. If the `.failOnError` option is not given then any valid HTTP response will be a success, regardless of the response status code.

The three functions for obtaining a response are as follows:

```swift
public extension CURLRequest {
	/// Execute the request synchronously. 
	/// Returns the response or throws an Error.
	func perform() throws -> CURLResponse
	/// Execute the request asynchronously.
	/// The parameter passed to the completion callback must be called to obtain the response or throw an Error.
	func perform(_ completion: @escaping (CURLResponse.Confirmation) -> ())
	/// Execute the request asynchronously. 
	/// Returns a Promise object which can be used to monitor the operation.
	func promise() -> Promise<CURLResponse>
}
```

The first `CURLRequest.perform` function executes the request synchronously on the calling thread. The function call will block until the request succeeds or fails. On failure, a `CURLResponse.Error` will be thrown.

The second `CURLRequest.perform` function executes the request asynchronously on background threads as necessary. The parameter passed to this function is a callback which will be given a `CURLResponse.Confirmation` once the request completes or fails. Calling the confirmation parameter from within your callback will either return the `CURLResponse` or throw a `CURLResponse.Error`. 

The third function, `CURLRequest.perform`, will return a `Promise<CURLResponse>` object which can be used to chain further activities and poll or wait for the request to complete. As with the other response generating functions, a `CURLResponse.Error` will be thrown if an error occurs. Information on the Promise object in general can be found in the [Perfect-Thread](http://www.perfect.org/docs/thread.html) documentation.

The following three example shows how each of the functions are used. Each will perform a request and convert the resulting response body from JSON into a [String:Any] dictionary.

• Synchronously fetch an API endpoint and decode it from JSON:

```swift
let url = "https://httpbin.org/get?p1=v1&p2=v2"
let json: [String:Any] = try CURLRequest(url).perform().bodyJSON
```

• Asynchronously fetch an API endpoint and decode it from JSON:

```swift
let url = "https://httpbin.org/post"
CURLRequest(url).perform {
	confirmation in
	do {
		let response = try confirmation()
		let json: [String:Any] = response.bodyJSON
		
	} catch let error as CURLResponse.Error {
			print("Failed: response code \(error.response.responseCode)")
	} catch {
			print("Fatal error \(error)")
	}
}
```

• Asynchronously fetch an API endpoint using a Promise and decode it from JSON:

```swift
let url = "https://httpbin.org/get?p1=v1&p2=v2"
if let json = try CURLRequest(url).promise().then { return try $0().bodyJSON }.wait() {
	// ...
}
```

The three available functions ranked according to efficiency would be ordered as:

1. Asynchronous `perform`
2. Asynchronous `promise`
3. Synchronous `perform`

When performing CURL requests on a high-traffic server it is advised that one of the asynchronous response functions be used.

### Response Data

A `CURLResponse` object provides access to the response's content body as either raw bytes, a String or as a JSON decoded [String:Any] dictionary. In addition, meta-information such as the response HTTP headers and status code can be retrieved.

Response body data is made available through a series of get-only `CURLResponse` properties:

```swift
public extension CURLResponse {
	/// The response's raw content body bytes.
	public var bodyBytes: [UInt8]
	/// Get the response body converted from UTF-8.
	public var bodyString: String
	/// Get the response body decoded from JSON into a [String:Any] dictionary.
	/// Invalid/non-JSON body data will result in an empty dictionary being returned.
	public var bodyJSON: [String:Any]
}
```

The remaining response data can be retrieved by calling one of the `CURLResponse.get` functions and passing in an enum value corresponding to the desired data. The enums indicating these values are separated into three groups, each according to the type of data that would be returned; one of String, Int or Double. The enum types are `CURLResponse.Info.StringValue`, `CURLResponse.Info.IntValue`, and `CURLResponse.Info.DoubleValue`. In addition, `get` functions are provided for directly pulling header values from the response.

```swift
public extension CURLResponse {
	/// Get an response info String value.
	func get(_ stringValue: Info.StringValue) -> String?
	/// Get an response info Int value.
	func get(_ intValue: Info.IntValue) -> Int?
	/// Get an response info Double value.
	func get(_ doubleValue: Info.DoubleValue) -> Double?
	/// Get a response header value. Returns the first found instance or nil.
	func get(_ header: Header.Name) -> String?
	/// Get a response header's values. Returns all found instances.
	func get(all header: Header.Name) -> [String]
}
```

In addition, a few convenience properties have been added for pulling commonly requested data from a response such as `url` and `responseCode`.

The following examples show how to pull header and other meta-data from the request:

```swift
// get the response code
let code = response.get(.responseCode)
```

```swift
// get the response code using the accessor
let code = response.responseCode
```

```swift
// get the "Last-Modified" header from the response
if let lastMod = response.get(.lastModified) {
	...
}
```

### Failures

When a failure occurs a `CURLResponse.Error` object will be thrown. This object provides the CURL error code which was generated (not that this is different from any HTTP response code and is CURL specific). It also provides access to an error message string, and a CURLResponse object which can be used to further inquire about the resulting error.

Note that, depending on the options which were set on the request, the response object obtained after an error may not have any associated content body data.

`CURLResponse.Error` is defined as follows:

```swift
open class CURLResponse {
	/// An error thrown while retrieving a response.
	public struct Error: Swift.Error {
		/// The curl specific request response code.
		public let code: Int
		/// The string message for the curl response code.
		public let description: String
		/// The response object for this error.
		public let response: CURLResponse
	}
}
```

## Reporting Issues

We have transitioning to using JIRA for all bugs and support related issues, therefore the GitHub issues have been disabled.

If you find a mistake, bug, or any other helpful suggestion you'd like to make on the docs please head over to [http://jira.perfect.org:8080/servicedesk/customer/portal/1](http://jira.perfect.org:8080/servicedesk/customer/portal/1) and raise it.

A comprehensive list of open issues can be found at [http://jira.perfect.org:8080/projects/ISS/issues](http://jira.perfect.org:8080/projects/ISS/issues)

## Further Information
For more information on the Perfect project, please visit [perfect.org](http://perfect.org).
