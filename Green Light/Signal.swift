//
//  Signal.swift
//  Green Light
//
//  Created by Joseph Cestone on 8/7/22.
//

import Foundation

struct Signal {
    let lights: [Light]
    let roads: [Road]
    private var lightsIndexByRoad: [Road: Int] = [:]
    private let boolCombinations: [SignalBoolean]
    var maxYellowTime: TimeInterval {
        roads.map { $0.yellowLightDuration }.max()!
    }
    
    // transition
    
    // func transition
    
    /// Helper function for init
    private mutating func check(roads r: [Road], lights l: [Light]) -> [Road: Int] {
        let uniqueRoadCount = Set(r).count
        let uniqueLightCount = Set(r).count
        assert(r.count == uniqueRoadCount, "Repeated Roads: Only \(uniqueRoadCount) of the \(r.count) roads are unique.")
        assert(l.count == uniqueLightCount, "Repeated lights: Only \(uniqueLightCount) of the \(l.count) lights are unique.")
        assert(r.count == l.count, "Invalid Signal: Different number of roads (\(r.count)) and lights (\(l.count)).")
        return Dictionary<Road, Int>(uniqueKeysWithValues: zip(roads, lights.indices))
    }
    
    init(lights: [Light], roads: [Road], lightsIndexByRoad: [Road : Int], roadCombinations: [[Road]]) {
        self.lights = lights
        self.roads = roads
        let numRoads = roads.count
        self.boolCombinations = roadCombinations.map { movingRoads in
            var roadMovingBools = Array(repeating: false, count: numRoads)
            movingRoads.forEach { movingRoad in
                let idx = lightsIndexByRoad[movingRoad]!
                roadMovingBools[idx] = true
            }
            return SignalBoolean(roadMoving: roadMovingBools)
        }
        self.lightsIndexByRoad = check(roads: roads, lights: lights)
    }
    
    private func checkStateCompatibleWithSignal(state: SignalState) {
        assert(state.colors.count == lightsIndexByRoad.count, "Signal state has wrong number of lights: has \(state.colors.count), this signal expects \(lightsIndexByRoad.count).")
    }
    
    private func transitionState(from oldBool: SignalBoolean, to newBool: SignalBoolean) -> SignalState {
        let lightColors:[LightColor] =
        zip(oldBool.roadMoving, newBool.roadMoving).map { (old, new) in
            if old {
                if new {
                    return .green // will continue green
                } else {
                    return .yellow // will be stopping
                }
            } else {
                if new {
                    return .waitingRed // waiting for yellow to turn red
                } else {
                    return .red // will stay red
                }
            }
        }
        return SignalState(colors: lightColors, yellowCountdown: maxYellowTime)
    }
    
    func possibleStates(following currentState: SignalState) -> [SignalState] {
        guard !currentState.hasYellow else { return [currentState] }
        let currentBools = currentState.signalBoolean
        return boolCombinations.map { newbools in
            transitionState(from: currentBools, to: newbools)
        }
    }
    
    func read(state: SignalState, road: Road) -> LightColor {
        checkStateCompatibleWithSignal(state: state)
        return state.colors[lightsIndexByRoad[road]!]
    }
}

struct SignalBoolean {
    let roadMoving: [Bool]
    var greenRed: [LightColor] {
        roadMoving.map { isMoving in
            isMoving ? LightColor.green : .red
        }
    }
}

struct SignalState {
    var colors: [LightColor]
    var yellowCountdown: TimeInterval
    var hasYellow: Bool { colors.contains([.yellow]) }
    
    var roadMovingBooleans: [Bool] { colors.map { $0 != .red } }
    var signalBoolean: SignalBoolean { SignalBoolean(roadMoving: roadMovingBooleans) }
    
    func advanced(byTime dt: TimeInterval) -> SignalState {
        let newColors: [LightColor]
        let newYellowCountdown: TimeInterval
        if yellowCountdown <= dt { // yellow will be done
            newYellowCountdown = 0
            newColors = colors.replacing([.yellow], with: [.red]).replacing([.waitingRed], with: [.green])
        } else {
            let newYellowCountdown = yellowCountdown - dt
            newColors = colors
        }
        return SignalState(colors: newColors, yellowCountdown: newYellowCountdown)
    }
}
