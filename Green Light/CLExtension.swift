//
//  CLExtension.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/8/22.
//

import Foundation
import CoreLocation

let earthRadius = 6_371_000.0

extension CLLocationCoordinate2D {
    public init(radiusFeet: CLLocationDistance, theta: CLLocationDirection, relativeTo: CLLocationCoordinate2D) {
        
        let radiusEarthDeg = meters(from: radiusFeet) / earthRadius * 180 / .pi
        
        // 0° is North, 90° is East, so Y is cos and X is sin
        let deltaLat = radiusEarthDeg * cos(-theta * Double.pi / 180) //y
        let deltaLong = radiusEarthDeg * sin(-theta * Double.pi / 180)//x
        
        self.init(
            latitude: relativeTo.latitude + deltaLat,
            longitude: relativeTo.longitude + deltaLong
        )
    }
    
    func offset(deltaLat: CLLocationDistance, deltaLong: CLLocationDistance) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude + deltaLat, longitude: longitude + deltaLong)
    }
    
    func offset(latMeters: CLLocationDistance, longMeters: CLLocationDistance) -> CLLocationCoordinate2D {
        
        let latRadians = latMeters / earthRadius
        let longRadians = longMeters / earthRadius
        
        let deltaLat = latRadians * 180 / .pi
        let deltaLong = longRadians * 180 / .pi
        
        return CLLocationCoordinate2D(latitude: latitude + deltaLat, longitude: longitude + deltaLong)
    }
    
    func offset(latFeet: CLLocationDistance, longFeet: CLLocationDistance) -> CLLocationCoordinate2D {
        offset(latMeters: meters(from: latFeet), longMeters: meters(from: longFeet))
    }
    
    func mirroredAcross(lat: CLLocationDegrees) -> CLLocationCoordinate2D {
        let deltaLat = latitude - lat
        return CLLocationCoordinate2D(latitude: lat - deltaLat, longitude: longitude)
    }
    
    func mirroredAcross(long: CLLocationDegrees) -> CLLocationCoordinate2D {
        let deltaLong = longitude - long
        return CLLocationCoordinate2D(latitude: latitude, longitude: long - deltaLong)
    }
}
