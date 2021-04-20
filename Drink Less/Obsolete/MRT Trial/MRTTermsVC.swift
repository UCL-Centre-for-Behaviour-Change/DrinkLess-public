//
//  MRTTermsVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 06/12/2019.
//  Copyright © 2019 Greg Plumbly. All rights reserved.
//

import UIKit

class MRTTermsVC: WebVCBase {

    
    override func viewDidLoad() {
        // Set this before super
        resource = "mrt-terms"
        super.viewDidLoad()
    }
    
    
    override func handleAppSchemeRequest(_ resourceId: String) {
        assert(resourceId == "submit")
        
        // Validate the form fields have been completed
        let consent1 = formFieldValue(for: "consent1") ?? ""
        let consent2 = formFieldValue(for: "consent2") ?? ""
        let understand1 = formFieldValue(for: "understand1") ?? ""
        let understand2 = formFieldValue(for: "understand2") ?? ""
        
        if consent1.count == 0 || consent2.count == 0 ||
            understand1.count == 0 || understand2.count == 0 {
            UIAlertController.simpleAlert(title: nil, msg: "Please complete the form above before continuing").show(in: self)
            return
        }

        // Save these in the manager and they've be saved with the user profile upon registration which is triggered at the end of onboarding.  @see MRTNotificationsManager.setup
        MRTNotificationsManager.shared.mrtTermsAnswers = ["consent1": consent1=="1", "consent2": consent2=="1", "understanding1": understand1=="1", "understand2": understand2=="1"]
        Log.i("MRT -- MRT Terms Answers: \(MRTNotificationsManager.shared.mrtTermsAnswers).")
        
        performSegue(withIdentifier: "MRTTermsAcknowledgedSegue", sender: self)
    }
    
//    @IBAction func handleContinue(_ sender: Any) {
//        performSegue(withIdentifier: "MRTTermsAcknowledgedSegue", sender: self)
//    }
    

}
