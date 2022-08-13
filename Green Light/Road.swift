//
//  Road.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/30/22.
//

import Foundation
import CoreLocation

public class Road: Hashable {
    public static func == (lhs: Road, rhs: Road) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    var name: String
    var speedLimit: CLLocationSpeed
    
    /// Positive is uphill (ft/ft) or (m/m)
    var approachGrade: Double = 0.0 // positive is uphill
    
    var points: [CLLocationCoordinate2D]
    var distances: [CLLocationDistance]
    var directions: [CLLocationDirection]
    
    var startPosition:CLLocationCoordinate2D { points.first! }
    var maxDistance: CLLocationDistance { distances.last! }
    
    var stopLinePosition: CLLocationDistance
    var gradedDeceleration: CLLocationAcceleration { yellowDecelerationRate + gravity * approachGrade }
    /// ΔV=at    so    t=ΔV/a
    var stoppingTime: TimeInterval { speedLimit / gradedDeceleration }
    //http://www.shortyellowlights.com/standards/ assume approach speed is the speed limit
    var yellowLightDuration: TimeInterval { driverReactionTime + stoppingTime }
    var stoppingDistance: CLLocationDistance { pow(speedLimit,2) / (2 * gradedDeceleration) }
    var decisionThreshold: CLLocationDistance { stopLinePosition - stoppingDistance }
    
    init(name: String, speedLimit: CLLocationSpeed, stopLineDistance: CLLocationDistance, points: [CLLocationCoordinate2D]) {
        self.name = name
        self.speedLimit = speedLimit
        self.stopLinePosition = stopLineDistance
        self.points = points
        distances = [0] + points.distances.cumulativeSum
        directions = points.directionsToNext
        directions.append(directions.last!) // assume the last direction is the same as the second to last, since there is no second point to calculate it.
        assert(self.points.count == self.distances.count, "Number of points (\(self.points.count)) ≠ the number of distances (\(self.distances.count)).")
        assert(self.points.count == self.directions.count, "Number of points (\(self.points.count)) ≠ the number of directions (\(self.directions.count)).")
    }
    
    convenience init(name: String, speedLimit: CLLocationSpeed, stopLineDistance: CLLocationDistance, points: () -> [CLLocationCoordinate2D]) {
        self.init(name: name, speedLimit: speedLimit, stopLineDistance: stopLineDistance, points: points())
    }
    
    private func index(of1D position: CLLocationDistance) -> Int {
        guard position <= maxDistance else {
            fatalError("1D position (\(position)) > max allowable (\(maxDistance))")
        }
        return distances.orderedBinarySearch { $0 >= position }
    }
    
    func location(from1D position: CLLocationDistance) -> CLLocationCoordinate2D {
        points[index(of1D: position)]
    }
    
    func direction(at1D position: CLLocationDistance) -> CLLocationDirection {
        directions[index(of1D: position)]
    }
    
    func location(of car: Car) -> CLLocationCoordinate2D { location(from1D: car.position) }
    
    func direction(of car: Car) -> CLLocationDirection { direction(at1D: car.position) }
}
