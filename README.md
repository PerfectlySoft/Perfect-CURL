# Perfect-CURL
cURL support for Perfect

[![GitHub version](https://badge.fury.io/gh/PerfectlySoft%2FPerfect-CURL.svg)](https://badge.fury.io/gh/PerfectlySoft%2FPerfect-CURL)

This project provides a Swift wrapper around the libcurl.

This package builds with Swift Package Manager and is part of the [Perfect](https://github.com/PerfectlySoft/Perfect) project. It was written to be stand-alone and so does not require PerfectLib or any other components.

Ensure you have installed and activated the latest Swift 3.0 tool chain.

Example usage:

```swift
func testCURLAsync() {
    let url = "https://www.treefrog.ca"
    let curl = CURL(url: url)
    
    // set an option
    let _ = curl.setOption(CURLOPT_SSL_VERIFYPEER, int: 0)
    
    // check the url
    XCTAssert(curl.url == url)
    
    // perform the request
    curl.perform {
        code, header, body in
        
        // check the result code, http response code, header and body bytes
        
        XCTAssert(0 == code, "Request error code \(code)")
        
        let response = curl.responseCode
        XCTAssert(response == 200, "\(response)")
        XCTAssert(header.count > 0)
        XCTAssert(body.count > 0)
    }
}
```

## Linux Build Notes

Ensure that you have installed libcurl.

```
sudo apt-get install libcurl-dev
```

## Building

Add this project as a dependency in your Package.swift file.

```
.Package(url: "https://github.com/PerfectlySoft/Perfect-CURL.git", majorVersion: 0, minor: 1)
```
