import XCTest

import nonStructureLibraryTests

var tests = [XCTestCaseEntry]()
tests += nonStructureLibraryTests.allTests()
XCTMain(tests)
