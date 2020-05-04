import Foundation
import XCTest
@testable import nonStructureLibrary

final class nonStructureLibraryTests: XCTestCase {
    func testPoint() {
        var points: [Point3] = []
        for _ in 0..<100 {
            points.append(Point3(Float(CGFloat.random(in: CGFloat.leastNormalMagnitude...CGFloat.greatestFiniteMagnitude)),
                                 Float(CGFloat.random(in: CGFloat.leastNormalMagnitude...CGFloat.greatestFiniteMagnitude)),
                                 Float(CGFloat.random(in: CGFloat.leastNormalMagnitude...CGFloat.greatestFiniteMagnitude))))
        }
    }
    
    func testTriangle() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        // XCTAssertEqual(nonStructureLibrary().text, "Hello, World!")
        //
        
        // test calculation of a normal triangle
        var points = [Point3(0,0,1), Point3(0,0,0), Point3(1,0,0)]
        let simpleTriangle = Triangle(withCorners: points)!
        
        XCTAssertTrue(simpleTriangle.area - 0.5 < 1e-6)
        
        // test when triangle initialized with no area
        points = [Point3.zero, Point3(1,0,0), Point3(2,0,0)]
        XCTAssertNil(Triangle(withCorners: points, allowZeroArea: false))
        if let triangle = try? XCTUnwrap(Triangle(withCorners: points)){
            XCTAssertNotNil(triangle)
        } else {
            fatalError("Failed to unwrap")
        }
    }
    
    func testPolygon() {
        // Create a triangle
        var points = [Point3(0,0,1), Point3(0,0,0), Point3(1,0,0)]
        if let simplePolygon = Polygon(withCorners: points){
            XCTAssertEqual(simplePolygon.numberOfCorners, 3)
            XCTAssertFalse(simplePolygon.concavity)
        }
        else {
            fatalError("Simple triangle as polygon creation failed.")
        }
        
        // Create a square
        points = [Point3.zero, Point3.xUnit, Point3(1,1,0), Point3.yUnit]
        if let simplePolygon = Polygon(withCorners: points){
            XCTAssertEqual(simplePolygon.numberOfCorners, 4)
            XCTAssertFalse(simplePolygon.concavity)
        }
        else {
            fatalError("Simple triangle as polygon creation failed.")
        }
        
        points = [
            Point3(0,0,0),
            Point3(1,0,0),
            Point3(2,0,0),
            Point3(2,1,0),
            Point3(1,1,0),
            Point3(1,2,0),
            Point3(0,2,0),
        ]
        if let simplePolygon = Polygon(withCorners: points){
            XCTAssertEqual(simplePolygon.numberOfCorners, 7)
            XCTAssertTrue(simplePolygon.concavity)
        }
        else {
            fatalError("Simple triangle as polygon creation failed.")
        }
    }
    
    func testBeam() {
        let beam = Beam.init(withID: 9949, startPoint: Point3.zero, endPoint: Point3.one, materialType: .Concrete, sectionType: .Rectangle)
        XCTAssertEqual(beam.id, 9949)
        XCTAssertEqual(beam.startPoint, Point3.zero)
        
    }
    

    static var allTests = [
        ("points", testPoint),
        ("triangle", testTriangle),
        ("polygon", testPolygon)
    ]
}
