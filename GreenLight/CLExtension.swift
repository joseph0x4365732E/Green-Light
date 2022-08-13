//
//  CLExtension.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/8/22.
//

import Foundation
import CoreLocation
import Spatial

public let earthRadius = 6_371_000.0

public extension CLLocationCoordinate2D {
    init(radiusFeet: CLLocationDistance, theta: CLLocationDirection, relativeTo: CLLocationCoordinate2D) {
        
        let radiusEarthDeg = meters(fromFT: radiusFeet) / earthRadius * 180 / .pi
        
        // 0° is North, 90° is East, so Y is cos and X is sin
        let deltaLat = radiusEarthDeg * cos(-theta * Double.pi / 180) //y
        let deltaLong = radiusEarthDeg * sin(-theta * Double.pi / 180)//x
        
        self.init(
            latitude: relativeTo.latitude + deltaLat,
            longitude: relativeTo.longitude + deltaLong
        )
    }
    
    init(cgPointFeet: CGPoint, relativeTo location: CLLocationCoordinate2D) {
        self = location.offset(latFeet: cgPointFeet.y, longFeet: cgPointFeet.x)
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
    
    func offset(latFeet: Double, longFeet: Double) -> CLLocationCoordinate2D {
        offset(latMeters: meters(fromFT: latFeet), longMeters: meters(fromFT: longFeet))
    }
    
    func offset(direction: CLLocationDirection, distance: CLLocationDistance) -> CLLocationCoordinate2D {
        let deltaLat = distance * sin(direction * .pi / 180)
        let deltaLong = distance * cos(direction * .pi / 180)
        return offset(latMeters: deltaLat, longMeters: deltaLong)
    }
    
    func mirroredAcross(lat: CLLocationDegrees) -> CLLocationCoordinate2D {
        let deltaLat = latitude - lat
        return CLLocationCoordinate2D(latitude: lat - deltaLat, longitude: longitude)
    }
    
    func mirroredAcross(long: CLLocationDegrees) -> CLLocationCoordinate2D {
        let deltaLong = longitude - long
        return CLLocationCoordinate2D(latitude: latitude, longitude: long - deltaLong)
    }
    
    func cgPoint(relativeTo center: CLLocationCoordinate2D) -> CGPoint {
        CGPoint(x: longitude - center.longitude, y: latitude - center.latitude)
    }
    
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let here:Point3D = Point3D(latitude: latitude, longitude: longitude, radius: earthRadius)
        let there:Point3D = Point3D(latitude: other.latitude, longitude: other.longitude, radius: earthRadius) // assumes constant elevation
        let lineDistance = here.distance(to: there) // line through the two points (goes through the earth)
        let angleRadians = acos((2 * earthRadius - lineDistance)/( 2 * pow(earthRadius, 2))) // law of cosines
        let earthArcLength = angleRadians * earthRadius
        return earthArcLength
    }
    
    func direction(to other: CLLocationCoordinate2D) -> CLLocationDirection {
        let deltaLat = other.latitude - latitude
        let deltaLong = other.longitude - longitude
        let metersLat = deltaLat * .pi / 180 * earthRadius
        let metersLong = deltaLong * .pi / 180 * earthRadius
        return atan(metersLat / metersLong)
    }
}

extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

public extension Point3D {
    init(latitude: Double, longitude: Double, radius: Double) {
        let pitch = latitude * .pi / 180
        var x = radius * cos(pitch)
        var y = 0.0
        var z = radius * sin(pitch)
        let yaw = longitude * .pi / 180
        y = x * sin(yaw)
        x = x * cos(yaw)
        //let angles = EulerAngles(angles: simd_double3(pitch, yaw, 0), order: __SPEulerAngleOrder.pitchYawRoll)
        self = Point3D(x: x, y: y, z: z)//.rotated(by: Rotation3D(eulerAngles: angles))
    }
}

public extension Array {
    func mergingPairs<A>(by merger: (Element, Element) -> (A)) -> [A] {
        var result = [Element]()
        let countMinus1 = count - 1
        result.reserveCapacity(countMinus1)
        return (0..<countMinus1).map { lIdx in
            let lhs = self[lIdx]
            let rhs = self[lIdx + 1]
            return merger(lhs, rhs)
        }
    }
}

public extension Array where Element == CLLocationCoordinate2D {
    var distances: [CLLocationDistance] {
        mergingPairs { lhs, rhs in
            lhs.distance(to: rhs)
        }
    }
    
    var directionsToNext: [CLLocationDirection] {
        mergingPairs { lhs, rhs in
            lhs.direction(to: rhs)
        }
    }
}

public extension Array where Element == Double {
    var cumulativeSum: [Double] {
        var result = [Double]()
        result.reserveCapacity(count)
        var runningSum = 0.0
        for idx in 0..<count {
            runningSum += self[idx]
            result.append(runningSum)
        }
        return result
    }
    
    func orderedBinarySearch(firstIndexWhere: (Double) -> Bool) -> Int {
        var highestFalseYet = -1
        var lowestTrueYet = count
        while true {
            if lowestTrueYet - highestFalseYet == 1 {
                break
            }
            let checkNext = (highestFalseYet + lowestTrueYet) / 2
            if firstIndexWhere(self[checkNext]) {
                // found lowest true yet
                lowestTrueYet = checkNext
            } else {
                // found highest false yet
                highestFalseYet = checkNext
            }
        }
        if lowestTrueYet == count {
            fatalError("None of the \(count) elements satisfied the condition.")
        }
        return lowestTrueYet
    }
}

/// Acceleration, measured in m/s^2
public typealias CLLocationAcceleration = Double
