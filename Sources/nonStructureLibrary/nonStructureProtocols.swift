//
//  NonStructureBIM.swift
//  NSInspire
//
//  Created by Fodan Deng on 4/28/20.
//  Copyright © 2020 FoiOS. All rights reserved.
//
import Foundation

extension Array {
    subscript(allowOutOfBoundIndex index: Int) -> Element {
        get {
            if index < 0 {
                return self[count + index % count]
            }
            if index < count && index >= 0 {
                return self[index]
            } else {
                return self[index % count]
            }
        }
        set(newVal) {
            if index < 0 {
                self[count - index % count] = newVal
            }
            if index < count && index >= 0 {
                self[index] = newVal
            } else {
                self[index % count] = newVal
            }
        }
    }
    
    mutating func shiftBackwards(forSteps step: Int) {
        let tmpArr = self[0..<step]
        self.removeSubrange(0..<step)
        self.append(contentsOf: tmpArr)
    }
    
    mutating func shiftForwards(forSteps step: Int) {
        let tmpArr = self[(count - step)..<count]
        self.removeSubrange((count - step)..<count)
        self.insert(contentsOf: tmpArr, at: 0)
    }
}

enum DefinitionType {
    case Geometry
    case StructureElement
    case Section
    case StructureElementProperty
}

enum MaterialType {
    case Concrete
    case Steel
    case Aluminum
}

enum SectionType {
    case Rectangle
    case Circle
    case Pipe
    case HBeam
    case Tube
    case Cross
    case LSize
    case TSize
    case HBeamReinforced
    case TubeReinforced
    case PipeReinforced
}

enum MeshFaceType {
    case triangles
    case quads
}

enum nonStructureError: Error {
    case polygon
    case mesh
    case section
}


struct Point3: Hashable, Equatable {
    var id: Int
    var type: DefinitionType { get{.Geometry} }
    var x, y, z: Float
    var length: Float {
        get {
            return getLengthAsVector()
            }
    }
    static var zero: Point3 {get{Point3(0.0, 0.0, 0.0)}}
    static var one: Point3 {get{Point3(1.0, 1.0, 1.0)}}
    static var xUnit: Point3 {get{Point3(1.0, 0.0, 0.0)}}
    static var yUnit: Point3 {get{Point3(0.0, 1.0, 0.0)}}
    static var zUnit: Point3 {get{Point3(0.0, 0.0, 1.0)}}
    
    init(_ withX: Float,_ Y: Float,_ Z: Float, id ID: Int = 0) {
        x = withX
        y = Y
        z = Z
        id = ID
    }
    
    static func +(left: Point3, right: Point3) -> Point3 { Point3(left.x + right.x, left.y + right.y, left.z + right.z) }
    static func -(left: Point3, right: Point3) -> Point3 { Point3(left.x - right.x, left.y - right.y, left.z - right.z) }
    static func *(p1: Point3, p2: Point3) -> Float { p1.x * p2.x + p1.y * p2.y + p1.z * p2.z }
    static func /(left: Point3, right: Float) -> Point3 { Point3(left.x / right, left.y / right, left.z / right) }
    static func /(left: Point3, right: Point3) -> Point3 { Point3(left.x / right.x, left.y / right.y, left.z / right.z) }
    static func +=(left: inout Point3, right: Point3) { left = left + right }
    static func /=(left: inout Point3, right: Float) { left = left / right }
    static func ==(left: Point3, right: Point3) -> Bool { left.id == right.id && left.x == right.x && left.y == right.y && left.z == right.z }
    
    func getLengthAsVectorSquared() -> Float { powf(self.x, 2) + powf(self.y, 2) + powf(self.z, 2) }
    func getLengthAsVector() -> Float { sqrtf(self.getLengthAsVectorSquared()) }
    func distanceToSquared(point: Point3) -> Float { powf(x - point.x, 2) + powf(y - point.y, 2) + powf(z - point.z, 2)}
    func distanceTo(point: Point3) -> Float { sqrtf(distanceToSquared(point: point)) }
    static func crossProduct(left: Point3, right: Point3) -> Point3 {
        Point3( left.y * right.z - left.z * right.y,
                left.z * right.x - left.x * right.z,
                left.x * right.y - left.y * right.x)
    }
    func hash(into hasher: inout Hasher){
        hasher.combine(id)
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(z)
    }
}

struct Triangle {
    var id: Int
    var type: DefinitionType {
        get{
            return .Geometry
        }
    }
    var corners: [Point3] {
        get {
            return _corners
        }
    }
    private var _corners: [Point3]

    var faceNormal: Point3 {
        get {
            return _faceNormal
        }
    }
    private var _faceNormal: Point3

    var area: Float {
        get {
            return _area
        }
    }
    private var _area: Float

    var cornersX: [Float] { get{ [self.corners[0].x, self.corners[1].x, self.corners[2].x] } }
    var cornersY: [Float] { get{ [self.corners[0].y, self.corners[1].y, self.corners[2].y] } }
    var cornersZ: [Float] { get{ [self.corners[0].z, self.corners[1].z, self.corners[2].z] } }

    init?(withCorners: [Point3], id ID: Int = 0, allowZeroArea: Bool = true) {
        
        // validate the corner number
        guard withCorners.count == 3 else { return nil }
        _corners = withCorners
        
        // validate the data
        // triangle should have a area > 0
        let a = withCorners[0].distanceTo(point: withCorners[1])
        let b = withCorners[1].distanceTo(point: withCorners[2])
        let c = withCorners[2].distanceTo(point: withCorners[0])
        let p = (a + b + c) / 2.0
        let areaCalculated = sqrtf(p * (p - a) * (p - b) * (p - c))
        if !allowZeroArea {
            guard areaCalculated > 0 else { return nil }
        }
        _area = areaCalculated
        
        // calculate the face normal
        let faceNormalCalculated = Point3.crossProduct(
            left: withCorners[1] - withCorners[0],
            right: withCorners[2] - withCorners[1]
        )
        let vecLength = faceNormalCalculated.length
        _faceNormal = faceNormalCalculated / vecLength
        id = ID
    }
}

struct Polygon {
    var id: Int
    var type: DefinitionType { get{return .Geometry} }
    var cornerPoints: [Point3]
    var numberOfCorners: Int { get{cornerPoints.count} }
    var concavity: Bool {get{_concavity}}
    private var _concavity: Bool
    private var isConcavePoint: [Bool]?
    
    
    init?(withCorners: [Point3], id ID: Int = 0){
        // Sort the corners with the angle between the vector from center point to this corner and the (1,0,0) vector [i.e. x- axis]
        // Project all calculation to WorldXY to save computational power
        var centerPoint = Point3(0,0,0)
        for point in withCorners {
            centerPoint.x += point.x
            centerPoint.y += point.y
        }
        centerPoint /= Float(withCorners.count)
        
        // Create a dictionary to store the angle calculation result
        var calculationResult: [Point3 : Float] = [:]
        for corner in withCorners {
            let vectorTowardsCenter = Point3(centerPoint.x - corner.x,
                                             centerPoint.y - corner.y, 0.0)
            calculationResult[corner] = tan(vectorTowardsCenter.y / vectorTowardsCenter.x)
        }
        
        // --- not sorting anymore -2020.4.29
        //
        // now sorting the point array with calculation results
//        let sortedPoint3Array: [Point3]
//        sortedPoint3Array = withCorners.sorted(by:){
//            guard let left = calculationResult[$0] else { fatalError("The polygon initialization had failed.") }
//            guard let right = calculationResult[$1] else { fatalError("The polygon initialization had failed.") }
//            return left > right }
//        _cornerPoints = sortedPoint3Array
        cornerPoints = withCorners
        id = ID
        
        // check for concavity
        do {
            (_concavity, isConcavePoint) = try Polygon.checkConcavity(forPolygonWithCornerPoints: cornerPoints)
        }
        catch {
            print("Something went wrong when checking concavity, just treat this polygon as a convex polygon")
            _concavity = false
        }
    }

    private static func checkConcavity(forPolygonWithCornerPoints points: [Point3]) throws -> (isConcavePolygon: Bool, concavePoint: [Bool]?) {
        
        if points.count < 4 { return (false, nil) }
        var concavity = false
        var endIndex = points.count
        
        var theFirstCrossProduct: Point3
        var sameDirectionAsFirstCrossProduct: [Bool] = Array.init(repeating: false, count: points.count)
        sameDirectionAsFirstCrossProduct[0] = true
        
        // calculat the first non-zero cross product
        var currentPointIndex = 0
        repeat {
            if (currentPointIndex == points.count){
                throw nonStructureError.polygon
            }
            let prevVec = points[allowOutOfBoundIndex: currentPointIndex - 1]
                - points[allowOutOfBoundIndex: currentPointIndex]
            let nextVec = points[allowOutOfBoundIndex: currentPointIndex + 1]
            - points[allowOutOfBoundIndex: currentPointIndex]
            theFirstCrossProduct = Point3.crossProduct(left: prevVec, right: nextVec)
            currentPointIndex += 1
            endIndex += 1
        } while theFirstCrossProduct.getLengthAsVectorSquared() < 1e-6
        
        // now with the first cross product settled, calculate all other vectors (which connect two adjecent points),
        //      to see if they match the first cross product.
        // if one do match the first cross product, it means the point maintains the direction, the polygon continues to be convex
        // otherwise, the point does not maintain the direction anymore, the polygon edge turned the opposite direction and become concave
        for index in currentPointIndex..<endIndex {
            let prevVec = points[allowOutOfBoundIndex: index - 1]
                - points[allowOutOfBoundIndex: index]
            let nextVec = points[allowOutOfBoundIndex: index + 1]
            - points[allowOutOfBoundIndex: index]
            let crossProduct = Point3.crossProduct(left: prevVec, right: nextVec)
            let scale = crossProduct / theFirstCrossProduct
            // check if the cross product of these two vector matches the first product,
            //  if not, it means those points are not co-plannar
            if abs(scale.x - scale.y) > 1e-6 || abs(scale.y - scale.z) > 1e-6 {
                // not a plannar polygon
                // here, if it only
                // if it only have 4 nodes, it can be divided into two triangles to display.
                if points.count == 4 { return (false, nil) }
                // otherwise throw an exception.
                //  ..... or maybe not :]
            } else if crossProduct * theFirstCrossProduct >= 0 {
                // same direction!
                sameDirectionAsFirstCrossProduct[allowOutOfBoundIndex: index] = true
            } else {
                // not same direction, and we got a concave point here
                sameDirectionAsFirstCrossProduct[allowOutOfBoundIndex: index] = false
                concavity = true
            }
        }
        
        // go thru all the members of "sameDirectionAsFirstCrossProduct",
        //  if there are more "true"s than "false"s, it means that the first point itself is a concave point
        //  we need fix that
        var trueCount = 0
        for val in sameDirectionAsFirstCrossProduct {
            if val { trueCount += 1 }
        }
        if trueCount > points.count - trueCount {
            for index in 0..<points.count {
                sameDirectionAsFirstCrossProduct[index] = !sameDirectionAsFirstCrossProduct[index]
            }
        }
        
        // now concavity checking is finished, return the result
        if (concavity) {
            return (true, sameDirectionAsFirstCrossProduct)
        }
        return (false, nil)
    }
    
    // slide a concave polygon into two polygons, at one of the concave point.
    private static func cutConcavePolygon(_ p: Polygon) -> (Polygon?, Polygon?) {
        guard let concavityAtIndex = p.isConcavePoint else {fatalError("cutConcavePolygon was called for a convex polygon")}
        var concavePointIndexes: [Int] = []
        // get the indexes of all concave points
        for index in 0..<p.numberOfCorners {
            if concavityAtIndex[index] {
                concavePointIndexes.append(index)
            }
        }
        // set the first cutting point
        var concavePointIndex = concavePointIndexes[0]
        if concavePointIndexes.count > 1 {
            // more than two concave points, connect the first two concave points to create two polygons
            // ensure the next point in polygon of the current concave point dealing with is not a concave point
            for cornerPointIndex in concavePointIndexes {
                if concavityAtIndex[allowOutOfBoundIndex: cornerPointIndex + 1] {
                    continue
                } else {
                    concavePointIndex = cornerPointIndex
                    break
                }
            }
        }
        let newPolygon1 = Polygon(withCorners: [
            p.cornerPoints[allowOutOfBoundIndex: concavePointIndex],
            p.cornerPoints[allowOutOfBoundIndex: concavePointIndex + 1],
            p.cornerPoints[allowOutOfBoundIndex: concavePointIndex + 2]
        ])
        var newPolygon2_CornerPoints = p.cornerPoints
        if concavePointIndex == 0 {
            _ = newPolygon2_CornerPoints.popLast()
        } else {
            newPolygon2_CornerPoints.remove(at: concavePointIndex + 1)
        }
        let newPolygon2 = Polygon(withCorners: newPolygon2_CornerPoints)
        return (newPolygon1, newPolygon2)
    }
    
    private static func createMeshTrianglesForConvexPolygon(_ polygon: Polygon) -> [(Int, Int, Int)] {
        // return a list of triangle point indexes (Mesh Faces) for given polygon
        var triangleArray: [(Int, Int, Int)] = []
        return [(1,2,3)]
    }
}

protocol nonStructureFrameProtocol {
    var startPoint: Point3 {get set}
    var endPoint: Point3 {get set}
    var localRotationDegree: Float {get set}
    var materialType: MaterialType {get set}
    var sectionType: SectionType {get set}
    var frameProperties: [Float]? {get set}
    var materialDescription: String? {get set}
}

protocol nonStructureWallProtocol {
    var startPoint: Point3 {get set}
    var endPoint: Point3 {get set}
    var height: Float {get set}
    var thickness: Float {get set}
    var materialType: MaterialType {get set}
    var materialDescription: String? {get set}
}

protocol nonStructureSlabProtocol {
    var edgePolygon: Polygon {get set}
    var thickness: Float {get set}
    var materialType: MaterialType {get set}
    var materialDescription: String? {get set}
}

protocol nonStructureMeshGenerateProtocol {
    func getVertices() -> [Point3]
    func getQuadsFaces() -> ([[Int]], MeshFaceType)
}


