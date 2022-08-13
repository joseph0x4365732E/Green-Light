//
//  CGExtension.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/27/22.
//

import Foundation

public extension CGPoint {
    func offset(deltaX: CGFloat, deltaY: CGFloat) -> CGPoint {
        CGPoint(x: x + deltaX, y: y + deltaY)
    }
}

public extension CGRect {
    init(pt1: CGPoint, pt2: CGPoint) {
        let width = abs(pt2.x - pt1.x)
        let height = abs(pt2.y - pt1.y)
        let x = (pt1.x + pt2.x) / 2
        let y = (pt1.y + pt2.y) / 2
        self.init(x: x, y: y, width: width, height: height)
    }
}
