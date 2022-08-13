//
//  SimulationPlayer.swift
//  Green Light
//
//  Created by Joseph Cestone on 8/12/22.
//

import Foundation

struct SimulationPlayer {
    var simulation: Simulation
    var time: TimeInterval
    var maxTime: TimeInterval { simulation.runTime }
    var intersection: Intersection { simulation.intersection }
    var timeSlice: TimeSlice {
        let index = Int(time / Simulation.timeTick)
        return simulation.slices[index]
    }
    var carsByRoad: [(Road, [Car])] {
        timeSlice.routeSlices.map { rtSlice in
            (rtSlice.road, rtSlice.carsOldestFirst)
        }
    }
    var signal: Signal { simulation.signal }
}
