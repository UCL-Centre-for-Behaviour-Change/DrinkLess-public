//
//  Injecter.swift
//  drinkless
//
//  Created by Hari Karam Singh on 27/09/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import UIKit

/**
 Very basic dependency injection for the VC tiers.

 Most of the VCs are instantiated behind the scenes via SB segues so rather than unwind all of that let's just cheat, a little. At least it allows for instantied objects rather then just singletons
 */
@objc
public final class VCInjector: NSObject {
    
    @objc
    public static let shared = VCInjector()
    
    //---------------------------------------------------------------------
    @objc var isOnboarding = false  // Set to true prior to onboarding run and clear afterwards
    @objc var demographicData: DemographicData?
    @objc var workingAuditData: AuditData?  // USed by audit survey in onboarding and followup audits
    
    
    // Singletonise
    override private init() {
        super.init()
    }
    

    
}
