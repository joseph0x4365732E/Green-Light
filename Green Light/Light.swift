//
//  Light.swift
//  Green Light
//
//  Created by Joseph Cestone on 8/2/22.
//

import Foundation
import CoreLocation

public struct Light: Hashable {
    public static func == (lhs: Light, rhs: Light) -> Bool { lhs.location == rhs.location }
    public func hash(into hasher: inout Hasher) { hasher.combine(location) }
    
    var location: CLLocationCoordinate2D
}

public enum LightColor {
    case green
    case yellow
    case red
    case waitingRed
}
