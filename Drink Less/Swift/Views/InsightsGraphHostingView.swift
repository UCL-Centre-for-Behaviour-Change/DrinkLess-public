//
//  InsightsGraphHostingView.swift
//  drinkless
//
//  Created by Hari Karam Singh on 17/12/2019.
//  Copyright © 2019 Greg Plumbly. All rights reserved.
//

import UIKit

@objc
class InsightsGraphHostingView: CPTGraphHostingView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    public var onGraphTouchDidBegin: ()->Void = {}
    public var onGraphTouchDidEnd: ()->Void = {}
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        onGraphTouchDidBegin()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        sendTouchEnded()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        sendTouchEnded()
    }
    
    private func sendTouchEnded() {
        onGraphTouchDidEnd()
    }
    
    
}
