//
//  InsightsSectionVCBase.swift
//  drinkless
//
//  Created by Hari Karam Singh on 09/10/2019.
//  Copyright © 2019 Greg Plumbly. All rights reserved.
//

import UIKit

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////

enum InsightsSectionState : Int {
    case expanded
    case collapsed
}

//////////////////////////////////////////////////////////
// MARK: -
//////////////////////////////////////////////////////////


/** Base class for the 3 sections' VCs */
class InsightsSectionVCBase: UIViewController {

    // Setting triggers the subclasses refresh override
    public var allStatistics:PXAllStatistics? {
        didSet {
            self.refresh()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // Resize and return the
    
    /** @abstract */
    public func sectionHeightForState(_ state:InsightsSectionState) -> CGFloat {
        assert(false, "Must override")
        return 0.0
    }
    
    public func refresh() {
        assert(false, "Must override")
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
