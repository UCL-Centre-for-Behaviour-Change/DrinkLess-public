//
//  TrialParticipantRegisterVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 15/06/2020.
//  Copyright © 2020 UCL. All rights reserved.
//

import UIKit

class TrialParticipantRegisterVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var yesContinueBtn: PXSolidButton!
    @IBOutlet var noBtn: PXSolidButton!
    @IBOutlet weak var formHConstr: NSLayoutConstraint!
    @IBOutlet weak var formCont: UIView!
    @IBOutlet weak var emailInput: UITextField!
    
    @IBOutlet weak var topLevelStack: UIStackView!
    @IBOutlet weak var buttonsStack: UIStackView!
    
    @IBOutlet weak var dummyView: UIView!
    @IBOutlet weak var formContView: UIView!
    
    var formH:CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dummyView.backgroundColor = .clear
        formContView.backgroundColor = .clear
        emailInput.delegate = self
        
        noBtn.backgroundColor = UIColor.drinkLessRed()
        
        formH = formHConstr.constant
    }

    override func viewWillAppear(_ animated: Bool) {
        formHConstr.constant = 0
        self.topLevelStack.removeArrangedSubview(formCont) // note, it is still in the view stack
        
        // Re init buttons in case of BACK
        yesContinueBtn.removeTarget(self, action: nil, for: .touchUpInside)
        yesContinueBtn.addTarget(self, action: #selector(handleYesButton), for: .touchUpInside)
        yesContinueBtn.setTitle("Yes", for: .normal)
        
        //        noBtn.width = 0
        if !buttonsStack.arrangedSubviews.contains(noBtn) {
            buttonsStack.addArrangedSubview(noBtn)
//            noBtn.removeFromSuperview()
        }
        
        
    }
    
    
    @IBAction private func handleYesButton() {
        // Update the buttons. Hide No and chnage Yes to Submit
        yesContinueBtn.removeTarget(self, action: nil, for: .touchUpInside)
        yesContinueBtn.setTitle("Submit", for: .normal)
        yesContinueBtn.addTarget(self, action: #selector(handleContinueButton), for: .touchUpInside)
//        noBtn.width = 0
        buttonsStack.removeArrangedSubview(noBtn)
        noBtn.removeFromSuperview()
        
        formCont.y = 110;
        formCont.alpha = 0;
        topLevelStack.insertArrangedSubview(formCont, at: 2)
        formHConstr.constant = formH
    
        // Animate it
        self.view.setNeedsUpdateConstraints()
        self.view.setNeedsLayout()
        UIView.animate(withDuration: 0.35) {
            self.formCont.alpha = 1;
            self.view.updateConstraintsIfNeeded()
            self.view.layoutIfNeeded()
        }
        
    }
    
    @objc private func handleContinueButton() {
        // Validate and save, segue or alert user to error
        let emailStr = emailInput.text ?? ""
        if !validateEmail(emailStr) {
            UIAlertController.simpleAlert(title: "Please enter a valid email", msg: nil).show(in: self)
        } else {
            let params = ["email": emailStr]
            DataServer.shared.saveDataObject(className: "IdeasTrialParticipant", objectId: nil, isUser: true, params: params, ensureSave: true) { (success, objectId, error) in
                if success {
                    Log.i("Successly logged trial participant email \(emailStr), (\(objectId ?? ""))")
                } else {
                    Log.e("Error logging trial participant email: \(String(describing:error))")
                }
            }
                
            self.performSegue(withIdentifier: "TrialParticipantRegisterDoneSegue", sender: self)
            
            let introMan = PXIntroManager.shared()!
            introMan.stage = .auditQuestions
            introMan.save()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        emailInput.resignFirstResponder()
        return true
    }
   
    
    private func validateEmail(_ candidate: String?) -> Bool {
        // thx: http://emailregex.com/
        guard let email = candidate else { return false }
        if email.count == 0 { return false }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with:email)
    }
    
}
