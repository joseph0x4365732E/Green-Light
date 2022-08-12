//
//  Light.swift
//  Green Light
//
//  Created by Joseph Cestone on 8/2/22.
//

import Foundation
import CoreLocation

struct Light: Hashable {
    static func == (lhs: Light, rhs: Light) -> Bool { lhs.location == rhs.location }
    func hash(into hasher: inout Hasher) { hasher.combine(location) }
    
    var location: CLLocationCoordinate2D
}

enum LightColor {
    case green
    case yellow
    case red
    case waitingRed
}
