//
//  Route.swift
//  Green Light
//
//  Created by Joseph Cestone on 8/6/22.
//

import Foundation
import CoreLocation

public class RouteSlice {
    var road: Road
    var carsOldestFirst: [Car]
    
    var totalSpeed: CLLocationSpeed {
        carsOldestFirst.map { $0.speed }.reduce(0, +)
    }
    
    init(road: Road, carsOldestFirst: [Car] = []) {
        self.road = road
        self.carsOldestFirst = carsOldestFirst
    }
    
    func advanced(byTime dt: TimeInterval, watching lightColor: LightColor) -> RouteSlice {
        var lastCar: Car? = nil
        let newCars = carsOldestFirst.map { car in
            lastCar = car.advanced(byTime: Simulation.timeTick, on: road, behind: lastCar, watching: lightColor)
            return lastCar!
        }
        return RouteSlice(road: road, carsOldestFirst: newCars)
    }
}
