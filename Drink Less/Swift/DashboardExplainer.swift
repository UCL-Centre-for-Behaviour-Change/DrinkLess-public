//
//  DashboardExplainer.swift
//  drinkless
//
//  Created by Hari Karam Singh on 25/09/2019.
//  Copyright © 2019 Greg Plumbly. All rights reserved.
//

import UIKit
import QuartzCore

@objc 
class DashboardExplainer: ExplainerOverlayBase {
    
    // Page related config data
    final private let ARROW_ANIM_DISTANCE:CGFloat = 11
    final private let INFO_VIEW_TAGS = [101, 401, 201, 301]
    final private let INFO_VIEW_PADDING = 20.0
    final private let ALIGN_BOTTOM_EDGE = [true, true, true, false]
    final private let ARROW_ANIM_DURATION:TimeInterval = 0.8
    //---------------------------------------------------------------------

    @objc public static let shared = DashboardExplainer();
    
    /** These need assiging before launch is called */
    @objc weak public var addDrinkBtn: UIView?
    @objc weak public var calendarBtn: UIView?
    @objc weak public var moodLinkCell: UIView?
    @objc weak public var graphView: UIView?
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Overrides
    //////////////////////////////////////////////////////////

    @objc override public func numPages() -> Int { return 4; }
    
    override public func gradientPortalConfiguration(page: Int, bounds: inout CGRect, type: inout CAGradientLayerType) {
        type = CAGradientLayerType.axial as CAGradientLayerType
        bounds = self.highlightViewBounds(for: page)
    }
    
    @objc override public func configureExplainerViewForDisplay(view: UIView, page: Int, portalBounds: CGRect) {
        
        // Tags for extracting the view components
        let viewTag = INFO_VIEW_TAGS[page]
        let arrowTag = viewTag + 1
        let doAlignBottomEdge = ALIGN_BOTTOM_EDGE[page]
        
        let sb = UIStoryboard(name: "Explainers", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "DashboardExplainerViewsVC")
        let infoView = vc.view.viewWithTag(viewTag)!  // the container
        let arrowView = infoView.viewWithTag(arrowTag)!
        
        // Flip the arrow for top edge alignment
        if !doAlignBottomEdge {
            arrowView.transform = CGAffineTransform(rotationAngle:CGFloat.pi)
            
            // fixes dodgy ipod touch bug
            arrowView.translatesAutoresizingMaskIntoConstraints = true
            arrowView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        }
        
        
        view.addSubview(infoView)
        infoView.translatesAutoresizingMaskIntoConstraints = true
        infoView.width = view.width
        infoView.x = 0
        let pad = CGFloat(INFO_VIEW_PADDING)
        infoView.y = doAlignBottomEdge ? portalBounds.minY - infoView.height - pad : portalBounds.maxY + pad
        
        // Animate the arrow
        UIView.animate(withDuration: ARROW_ANIM_DURATION, delay: 0, options:[.autoreverse, .repeat, .curveEaseInOut], animations: {
            // up or down initially depending on the alignment
            arrowView.y = arrowView.y + (self.ARROW_ANIM_DISTANCE * (doAlignBottomEdge ? 1.0 : -1.0))
        }, completion: nil)
    }
    
    
    //---------------------------------------------------------------------

    private func highlightViewBounds(for pageNum:Int) -> CGRect {
        return self.frameForView([addDrinkBtn!, calendarBtn!, moodLinkCell!, graphView!][pageNum])
    }
    
    
    
}
