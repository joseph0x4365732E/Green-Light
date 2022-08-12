//
//  Car.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/29/22.
//

import Foundation
import CoreLocation

struct Car {
    //MARK: Vars
    /// How far along the road
    var position: CLLocationDistance
    /// Forward speed of the car, in m/s. Cars cannot go backwards.
    var speed: CLLocationSpeed // m/s
    
    // MARK: Computed Vars
    var stoppingDistance: CLLocationDistance { // figure this out
        let decel = decelerationGs * 9.81
        return -pow(speed, 2) / (2 * decel)
    }
    
    static let maxAcceleration: CLLocationAcceleration = decelerationGs
    static let normalAcceleration: CLLocationAcceleration = 0.1 * 9.8
    static let speedLimitMultiplier = 1.1
    static let carIgnoreDistance:CLLocationDistance = meters(fromFT: plotDist)
    static let lightIgnoreDistance:CLLocationDistance = meters(fromFT: plotDist) / 2
    static let normalFollowingDistane:CLLocationDistance = 30.0
    static let driverNoticableSpeedDifference: CLLocationSpeed = mps(fromMPH: 1)
    
    //func maxSpeed(on road: Road) -> CLLocationSpeed { road.speedLimit * Car.speedLimitMultiplier }
    
    func timeToTravel(distance: CLLocationDistance) -> TimeInterval { distance / speed }
    
    func followingTime(to other: Car) -> TimeInterval {
        let distance = other.position - position
        return timeToTravel(distance: distance)
    }
    
    func relativeSpeed(of other: Car) -> CLLocationSpeed { other.speed - speed }
    
    func accelerationToStop(at stopPosition: CLLocationDistance) -> CLLocationAcceleration {
        -pow(speed, 2) / (2 * (position - stopPosition))
    }
    
    func acceleration(on road: Road, behind leadingCar: Car?, watching lightColor: LightColor) -> CLLocationAcceleration {
        
        var acceleration: CLLocationAcceleration = Car.normalAcceleration
        func limitAcceleration(to limit: CLLocationAcceleration) { acceleration = min(acceleration, limit) }
        
        // Following
        let followingDistance:CLLocationDistance
        let closeToLeading:Bool
        //let leaderPullingAway:Bool
        
        if leadingCar != nil {
            followingDistance = leadingCar!.position - position
            closeToLeading = followingDistance < Car.normalFollowingDistane
            let leaderRelativeSpeed = relativeSpeed(of: leadingCar!)
            let timeToLeader = followingTime(to: leadingCar!)
            //leaderPullingAway = leaderRelativeSpeed > Car.driverNoticableSpeedDifference
            if closeToLeading {
                limitAcceleration(to: leaderRelativeSpeed / timeToLeader) // accelerate or decelerate to match leader in 1 second - figure this out - will need to brake more aggressively
            }
        } else {
            followingDistance = Car.carIgnoreDistance
            closeToLeading = false
            //leaderPullingAway = false
        }
        
        // Light
        let distanceToStopLine = road.stopLinePosition - position
        let beforeStopLine = distanceToStopLine >= 0
        let lightInRange = distanceToStopLine < Car.lightIgnoreDistance
        
        if beforeStopLine && lightInRange {
            // Light is relavent
            let distanceToThreshold = road.decisionThreshold - position
            let reachedThreshold = distanceToThreshold <= 0
            let easing = reachedThreshold ? 1 : road.stoppingDistance / distanceToStopLine
            let canStopOnYellow = accelerationToStop(at: road.stopLinePosition) <= yellowDecelerationRate
            let stopForYellow = lightColor == .yellow && !canStopOnYellow
            if lightColor == .red || stopForYellow {
                limitAcceleration(to: accelerationToStop(at: road.stopLinePosition * easing))
            }
        }
        
        // Limit acceleration to reach speed limit in 1 second, or decelerate if over the speed limit
        limitAcceleration(to: road.speedLimit - speed)
        
        // Limit to car physical max Acceleration
        acceleration = max(acceleration, -Car.maxAcceleration)
        return acceleration
    }
    
    func advanced(byTime dt: TimeInterval, on road: Road, behind otherCar: Car?, watching lightColor: LightColor) -> Car {
        let acc = acceleration(on: road, behind: otherCar, watching: lightColor)
        let newSpeed = speed + acc * dt
        let newPos = position + newSpeed*dt
        return Car(position: newPos, speed: newSpeed)
    }
    
    func box(on road: Road) -> [CLLocationCoordinate2D] {
        let location = road.location(from1D: position)
        let direction = road.direction(at1D: position)
        let halfWidth = teslaWidth / 2
        let halfHeight = teslaLength / 2
        // points moving clockwise starting with upper right
        let points = [CGPoint(x: halfWidth, y: halfHeight),
                      CGPoint(x: halfWidth, y: -halfHeight),
                      CGPoint(x: -halfWidth, y: -halfHeight),
                      CGPoint(x: -halfWidth, y: halfHeight),
                      CGPoint(x: halfWidth, y: halfHeight)]
        let rotation = CGAffineTransform(rotationAngle: direction * .pi / 180)
        return points.map { point in
            CLLocationCoordinate2D(cgPointFeet: point.applying(rotation), relativeTo: location)
        }
    }
}
