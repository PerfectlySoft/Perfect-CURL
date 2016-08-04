# Perfect-CURL

[![GitHub version](https://badge.fury.io/gh/PerfectlySoft%2FPerfect-CURL.svg)](https://badge.fury.io/gh/PerfectlySoft%2FPerfect-CURL)
[![Gitter](https://badges.gitter.im/PerfectlySoft/PerfectDocs.svg)](https://gitter.im/PerfectlySoft/PerfectDocs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

cURL support for Perfect



This project provides a Swift wrapper around the libcurl.

This package builds with Swift Package Manager and is part of the [Perfect](https://github.com/PerfectlySoft/Perfect) project. It was written to be stand-alone and so does not require PerfectLib or any other components.

Ensure you have installed and activated the latest Swift 3.0 tool chain.

## Issues

We are transitioning to using JIRA for all bugs and support related issues, therefore the GitHub issues has been disabled.

If you find a mistake, bug, or any other helpful suggestion you'd like to make on the docs please head over to [http://jira.perfect.org:8080/servicedesk/customer/portal/1](http://jira.perfect.org:8080/servicedesk/customer/portal/1) and raise it.

A comprehensive list of open issues can be found at [http://jira.perfect.org:8080/projects/ISS/issues](http://jira.perfect.org:8080/projects/ISS/issues)

## Example usage:

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
sudo apt-get install libcurl4-openssl-dev
```

## Building

Add this project as a dependency in your Package.swift file.

```
.Package(url: "https://github.com/PerfectlySoft/Perfect-CURL.git", versions: Version(0,0,0)..<Version(10,0,0))
```


## Further Information
For more information on the Perfect project, please visit [perfect.org](http://perfect.org).
