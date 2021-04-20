//
//  PopoverVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 31/03/2020.
//  Copyright © 2020 UCL. All rights reserved.
//

import UIKit

class PopoverVC: UIViewController, UIPopoverPresentationControllerDelegate {

    @objc
    convenience init(contentVC:UIViewController, preferredSize:CGSize, sourceView:UIView, sourceRect:CGRect) {
        self.init()
        
        view.frame = contentVC.view.frame
        view.addSubview(contentVC.view)
        addChild(contentVC)
        preferredContentSize = preferredSize
        view.tintColor = .white
        modalPresentationStyle = .popover
        popoverPresentationController!.permittedArrowDirections = [.left, .right]
        popoverPresentationController!.sourceView = sourceView
        popoverPresentationController!.sourceRect = sourceRect
        popoverPresentationController!.delegate = self
    }
    
    /** Reverts the iPhone/compact default of making it into an action sheet. */
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
