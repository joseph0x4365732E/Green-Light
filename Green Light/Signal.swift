//
//  Signal.swift
//  Green Light
//
//  Created by Joseph Cestone on 8/7/22.
//

import Foundation

public struct Signal {
    let lights: [Light]
    let roads: [Road]
    private var lightsIndexByRoad: [Road: Int] = [:]
    private let boolCombinations: [SignalBoolean]
    var maxYellowTime: TimeInterval {
        roads.map { $0.yellowLightDuration }.max()!
    }
    var lightsByRoad: [Road:Light] {
        Dictionary(uniqueKeysWithValues: zip(roads, lights))
    }
    var allRed: SignalState { SignalState(allRedCount: lights.count) }
    
    init(lights: [Light], roads: [Road], roadCombinations: [[Road]]) {
        self.lights = lights
        self.roads = roads
        let numRoads = roads.count
        
        let uniqueRoadCount = Set(roads).count
        let uniqueLightCount = Set(roads).count
        assert(roads.count == uniqueRoadCount, "Repeated Roads: Only \(uniqueRoadCount) of the \(roads.count) roads are unique.")
        assert(lights.count == uniqueLightCount, "Repeated lights: Only \(uniqueLightCount) of the \(lights.count) lights are unique.")
        assert(roads.count == lights.count, "Invalid Signal: Different number of roads (\(roads.count)) and lights (\(lights.count)).")
        let localLightsIndex = Dictionary<Road, Int>(uniqueKeysWithValues: zip(roads, lights.indices))
        self.lightsIndexByRoad = localLightsIndex
        
        let boolCombs = roadCombinations.map { movingRoads in
            var roadMovingBools = Array(repeating: false, count: numRoads)
            movingRoads.forEach { movingRoad in
                let idx = localLightsIndex[movingRoad]!
                roadMovingBools[idx] = true
            }
            return SignalBoolean(roadMoving: roadMovingBools)
        }
        self.boolCombinations = boolCombs
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

public struct SignalBoolean {
    let roadMoving: [Bool]
    var greenRed: [LightColor] {
        roadMoving.map { isMoving in
            isMoving ? LightColor.green : .red
        }
    }
}

public struct SignalState {
    var colors: [LightColor]
    var yellowCountdown: TimeInterval
    var hasYellow: Bool { colors.contains([.yellow]) }
    
    var roadMovingBooleans: [Bool] { colors.map { $0 != .red } }
    var signalBoolean: SignalBoolean { SignalBoolean(roadMoving: roadMovingBooleans) }
    
    init(colors: [LightColor], yellowCountdown: TimeInterval) {
        self.colors = colors
        self.yellowCountdown = yellowCountdown
    }
    
    init(allRedCount: Int) {
        colors = Array(repeating: .red, count: allRedCount)
        yellowCountdown = 0
    }
    
    func advanced(byTime dt: TimeInterval) -> SignalState {
        let newColors: [LightColor]
        let newYellowCountdown: TimeInterval = max(0, yellowCountdown - dt)
        if newYellowCountdown == 0 { // yellow will be done
            newColors = colors.replacing([.yellow], with: [.red]).replacing([.waitingRed], with: [.green])
        } else {
            newColors = colors
        }
        return SignalState(colors: newColors, yellowCountdown: newYellowCountdown)
    }
}
