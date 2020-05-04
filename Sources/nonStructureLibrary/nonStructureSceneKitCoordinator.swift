//
//  File.swift
//  
//
//  Created by Fodan Deng on 5/2/20.
//

import Foundation
import SceneKit

enum generateMode {
    case lazy
    case accurate
}
protocol nonStructureSCNGeometryTransferrable {
    // capable of generating the SCNGeometry
    func getSCNGeometry(mode: generateMode) -> SCNGeometry?
}
protocol nonStructureGenerateLazySCNGeometryCapable {
    func getSCNGeometryAsBoxLazy(frameProperty: [Float]?) -> SCNBox?
}

extension SectionType: nonStructureGenerateLazySCNGeometryCapable {
    // add more
    func getSCNGeometryAsBoxLazy(frameProperty: [Float]?) -> SCNBox? {
        guard let properties = frameProperty else {return nil}
        let box : SCNBox
        switch self {
        case .Rectangle:
            box = SCNBox.init(width: 1.0,
                                  height: CGFloat(properties[2]),
                                  length: CGFloat(properties[1]),
                                  chamferRadius: 0)
            
        case .Circle:
            box = SCNBox.init(width: 1.0,
                              height: CGFloat(properties[1]),
                              length: CGFloat(properties[1]),
                              chamferRadius: 0)
        default:
            return nil
        }
        box.widthSegmentCount = 1
        box.heightSegmentCount = 1
        box.lengthSegmentCount = 1
        return box
    }
}

extension Beam: nonStructureSCNGeometryTransferrable {
    // add additional functions that is capable of directly transfer the SCNGeometry
    func getSCNGeometry(mode: generateMode) -> SCNGeometry? {
        if (mode == .lazy){
            guard let box = self.sectionType.getSCNGeometryAsBoxLazy(frameProperty: self.frameProperties) else {
                fatalError("box creation in lazy mode failed, element ID: \(self.id)")
            }
            box.width = CGFloat(self.length)
            return box
        }
        return nil
    }
    // default running mode in lazy mode
    func getSCNGeometry() -> SCNGeometry? {
        return getSCNGeometry(mode: .lazy)
    }
}
