
class nonStructureElement{
    var id: Int
    var name: String?
    let type: DefinitionType
    init(withID: Int, type: DefinitionType) {
        self.id = withID
        self.type = type
    }
    init(withName: String, id ID: Int, type t: DefinitionType) {
        name = withName
        id = ID
        type = t
    }
}

class Beam: nonStructureElement, nonStructureFrameProtocol {
    var startPoint: Point3
    var endPoint: Point3
    var localRotationDegree: Float
    var materialType: MaterialType
    var materialDescription: String?
    var sectionType: SectionType
    var frameProperties: [Float]?
    init(withID ID: Int, startPoint sp: Point3, endPoint ep: Point3, materialType mt: MaterialType, sectionType st: SectionType)
    {
        startPoint = sp
        endPoint = ep
        materialType = mt
        sectionType = st
        localRotationDegree = 0.0
        super.init(withID: ID, type: .StructureElement)
    }
}

class Slab: nonStructureElement, nonStructureSlabProtocol {
    var edgePolygon: Polygon
    var thickness: Float
    var materialType: MaterialType
    var materialDescription: String?
    init(withID ID: Int, edge: Polygon, thickness t: Float) {
        edgePolygon = edge
        thickness = t
        materialType = .Concrete
        super.init(withID: ID, type: .StructureElement)
    }
    
}
