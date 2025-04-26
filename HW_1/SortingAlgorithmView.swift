//
//  SortingAlgorithmView.swift
//  HW_1
//
//  Created by kinjal kathiriya  on 4/8/25.
//


import UIKit

class SortingAlgorithmView: UIView {
    var values: [Int] = [] {
        didSet { setNeedsDisplay() }
    }
    
    var highlightedIndices: Set<Int> = [] {
        didSet { setNeedsDisplay() }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), !values.isEmpty else { return }
        
        let barWidth = bounds.width / CGFloat(values.count)
        let maxValue = CGFloat(values.max() ?? 1)
        
        for (index, value) in values.enumerated() {
            let barHeight = bounds.height * CGFloat(value) / maxValue
            let x = CGFloat(index) * barWidth
            let y = bounds.height - barHeight
            
            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            
            if highlightedIndices.contains(index) {
                context.setFillColor(UIColor.systemRed.cgColor)
            } else {
                context.setFillColor(UIColor.systemBlue.cgColor)
            }
            
            context.fill(barRect)
        }
    }
}
