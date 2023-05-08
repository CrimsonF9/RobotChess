//
//  UIView+Jiggle.swift
//  RobotChess.FC-and-CZ
//
//  Created by Fernando Castro on 4/23/23.
//
import UIKit
// This extension adds a jiggle animation to UIView objects.
extension UIView {
    // This function animates the view by jiggling it horizontally.
       // - Parameters:
       //     - amount: The amount of horizontal displacement in points.
       //     - duration: The duration of the animation in seconds.
    func jiggle(amount: CGFloat = 5, duration: TimeInterval = 0.5) {
        // Create a keyframe animation for the translation on the x-axis.
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        // Set the timing function to linear.
        animation.timingFunction = CAMediaTimingFunction(
            name: CAMediaTimingFunctionName.linear
        )
        // Set the duration of the animation.
        animation.duration = duration
        // Set the values for the horizontal displacement during the animation.
        animation.values = [
            -amount, amount,
             -amount, amount,
             -amount / 2, amount / 2,
             -amount / 4, amount / 4,
             0
        ]
        // Add the animation to the view's layer and give it a unique key.
        layer.add(animation, forKey: "shake")
    }
}

