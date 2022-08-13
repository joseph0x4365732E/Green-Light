//
//  Intersection.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/14/22.
//

import Foundation
import MapKit

// MARK: Constants

public let laneWidth = 12.0
public let lanesWide = 2.0
public let roadWidth = laneWidth * lanesWide
public let laneCenter = laneWidth / 2
public let halfRoad = roadWidth / 2
public let plotDist = 1320.0 // 1/4 Mile
public let stripeWidth = 0.3
public let fullRoadWidth = roadWidth + stripeWidth
public let stripeLength = 1.5
public let stripeSpacing = 6.0
public let teslaWidth = 82.2 / 12
public let teslaLength = 184.8 / 12
public let carSpacing = 24.0

public let carImage = UIImage(named: "Car")!

public let plotMeters = meters(fromFT: plotDist)
public let fullPlotMeters = meters(fromFT: 2 * plotDist)
public let satZoomMeters = fullPlotMeters / 4
public let zoomedPlotMeters = fullPlotMeters / 25

public let gravity: CLLocationAcceleration = 9.8
public let decelerationGs = 0.4
public let yellowDecelerationRate: CLLocationAcceleration = meters(fromFT: 10)
public let driverReactionTime = 1.0

// MARK: Intersection
public struct Intersection {
    var center: CLLocationCoordinate2D
    var roads: [Road]
    var bounds: [CLLocationCoordinate2D]
    
    init(center: CLLocationCoordinate2D, roads: [Road], bounds: [CLLocationCoordinate2D]) {
        self.center = center
        self.roads = roads
        self.bounds = bounds
    }
    
    init(center: CLLocationCoordinate2D, roads: [Road], bounds: ()->[CLLocationCoordinate2D]) {
        self.center = center
        self.bounds = bounds()
        self.roads = roads
    }
    
    // MARK: Lines
    var boundsLine: ColorPolyline {
        ColorPolyline(
            polyline: MKPolyline(coordinates: bounds, count: bounds.count),
            color: UIColor.systemRed
        )
    }
    var roadsLines: [ColorPolyline] {
        roads.map { road in
            ColorPolyline(polyline: MKPolyline(coordinates: road.points, count: road.points.count), color: UIColor.systemBlue)
        }
    }
    var carLines: [ColorPolyline] {
        []
//        roads.flatMap { rte in
//            rte.cars
//        }.map { car in
//            let points = car.box
//            return ColorPolyline(polyline: MKPolyline(coordinates: points, count: points.count), color: .blue)
//        }
    }
    var lines: [ColorPolyline] { [boundsLine] + roadsLines + carLines }
}

// MARK: arc()

public func arc(radiusFeet: CLLocationDistance, center: CLLocationCoordinate2D, start: CLLocationDirection, end: CLLocationDirection, resolution: CLLocationDistance) -> [CLLocationCoordinate2D] {
    
    let backwards = start > end // goes negative
    
    // Should all be degrees
    let angleResolutionDeg = asin(resolution / radiusFeet) * 180 / .pi
    let totalAngle = abs(start - end)
    let numPoints = Int(ceil(totalAngle / angleResolutionDeg)) + 1 // add one for end point
    let actualResolution = (backwards ? -totalAngle : totalAngle) / Double(numPoints - 1)
    let thetas:[CLLocationDirection] =
    [start] +
    (2..<numPoints).map { pointIndex in
            start + Double(pointIndex) * actualResolution
        } +
    [end]
    
    return thetas.map { theta in
        CLLocationCoordinate2D(radiusFeet: radiusFeet, theta: theta, relativeTo: center)
    }
}

public func line(from startPoint: CLLocationCoordinate2D, to endPoint: CLLocationCoordinate2D, resolution: CLLocationDistance) -> [CLLocationCoordinate2D] {
    let fullDeltaLat = endPoint.latitude - startPoint.latitude
    let fullDeltaLong = endPoint.longitude - startPoint.longitude
    
    let distance = startPoint.distance(to: endPoint)
    let numPoints = ceil(distance / resolution) + 1 // add one for end point
    
    let points: [CLLocationCoordinate2D] =
    (0..<Int(numPoints)).map { numPoint in
        let ratio = Double(numPoint) / numPoints
        let deltaLat = fullDeltaLat * ratio
        let deltaLong = fullDeltaLong * ratio
        return startPoint.offset(deltaLat: deltaLat, deltaLong: deltaLong)
    }
    return points
}

public func meters(fromFT feet: Double) -> Double { feet * 0.304800609601 }

public func mps(fromMPH mph: Double) -> Double { meters(fromFT: mph * 5280) / 3600 }
