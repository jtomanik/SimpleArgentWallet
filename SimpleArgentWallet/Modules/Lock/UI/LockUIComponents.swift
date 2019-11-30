//
//  LockUIComponents.swift
//  SimpleArgentWallet
//
//  Created by Jakub Tomanik on 30/11/2019.
//  Copyright © 2019 Jakub Tomanik. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class Indicator: UIView {
    var needsClearBackground = true {
        didSet {
            self.setNeedsDisplay()
        }
    }

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.white
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let backgroundColor = needsClearBackground ? UIColor.clear.cgColor : UIColor.lightGray.cgColor
        drawCircle(rect, background: backgroundColor)
    }
}

class PinIndicator: UIButton {

    var digitStream: Observable<Int> {
        return self.rx
            .tap
            .map { self.digit }
    }

    let digit: Int

    init(digit: Int) {
        self.digit = digit
        super.init(frame: CGRect.zero)
        self.setTitle("\(digit)", for: .normal)
        self.setTitleColor(UIColor.black, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawCircle(rect)
    }
}

extension UIView {
    func drawCircle(_ rect:CGRect, background: CGColor = UIColor.clear.cgColor) {
        guard let context = UIGraphicsGetCurrentContext() else {return}
        let rect = CGRect(x: rect.origin.x+0.5,
                          y: rect.origin.y+0.5,
                          width: rect.width-1.5,
                          height: rect.height-1.5)

        context.setLineWidth(1)
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setFillColor(background)
        context.strokeEllipse(in: rect)
        context.fillEllipse(in: rect)
    }

    func shake(delegate: CAAnimationDelegate) {
        let animationKeyPath = "transform.translation.x"
        let shakeAnimation = "shake"
        let duration = 0.6
        let animation = CAKeyframeAnimation(keyPath: animationKeyPath)
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = duration
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        animation.delegate = delegate
        layer.add(animation, forKey: shakeAnimation)
    }
}

