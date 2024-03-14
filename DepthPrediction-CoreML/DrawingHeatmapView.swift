//
//  DrawingHeatmapView.swift
//  DepthPrediction-CoreML
//
//  Created by Doyoung Gwak on 20/07/2019.
//  Copyright © 2019 Doyoung Gwak. All rights reserved.
//

import UIKit

class DrawingHeatmapView: UIView {
    
    var heatmap: Array<Array<Double>>? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var cellSums: [Float]? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        if let ctx = UIGraphicsGetCurrentContext() {
            
            ctx.clear(rect);
            
            guard let heatmap = self.heatmap else { return }
            guard let cellSums = self.cellSums else { return }
            
            let size = self.bounds.size
            let heatmap_w = heatmap.count
            let heatmap_h = heatmap.first?.count ?? 0
            let w = size.width / CGFloat(heatmap_w)
            let h = size.height / CGFloat(heatmap_h)
            
            for j in 0..<heatmap_h {
                for i in 0..<heatmap_w {
                    let value = heatmap[i][j]
                    var alpha: CGFloat = CGFloat(value)
                    if alpha > 1 {
                        alpha = 1
                    } else if alpha < 0 {
                        alpha = 0
                    }
                    
                    let rect: CGRect = CGRect(x: CGFloat(i) * w, y: CGFloat(j) * h, width: w, height: h)
                                      
                    // gray
                    let color: UIColor = UIColor(white: 1-alpha, alpha: 1)
                    
                    let bpath: UIBezierPath = UIBezierPath(rect: rect)
                    
                    color.set()
                    //bpath.stroke()
                    bpath.fill()
                }
                
            }
            
            ctx.setStrokeColor(UIColor.black.cgColor)
            ctx.setLineWidth(2.0)
            
            // Draw vertical lines
            for i in 1..<3 {
                let x = CGFloat(i) * size.width / 3
                ctx.move(to: CGPoint(x: x, y: 0))
                ctx.addLine(to: CGPoint(x: x, y: size.height))
            }
            
            // Draw horizontal lines
            for j in 1..<3 {
                let y = CGFloat(j) * size.height / 3
                ctx.move(to: CGPoint(x: 0, y: y))
                ctx.addLine(to: CGPoint(x: size.width, y: y))
            }
            
            ctx.strokePath()
            
            for j in 0..<3 {
                for i in 0..<3 {
                    let value = cellSums[j * 3 + i]
                    var textColor: UIColor
                    
                    // Set the font color based on the threshold value
                    if value >= 2500 {
                        textColor = .green
                    } else {
                        textColor = .red
                    }
                    
                    let text = NSString(format: "%.2f", value)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 18),
                        .foregroundColor: textColor
                    ]
                    let textSize = text.size(withAttributes: attributes)
                    let textX = CGFloat(i) * size.width / 3 + (size.width / 3 - textSize.width) / 2
                    let textY = CGFloat(j) * size.height / 3 + (size.height / 3 - textSize.height) / 2
                    let textRect = CGRect(x: textX, y: textY, width: textSize.width, height: textSize.height)
                    text.draw(in: textRect, withAttributes: attributes)
                }
                
            } // end of draw(rect:)
            
        }
    }
}
