//
//  YourDrinkingCuesIntroVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 09/03/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import UIKit
import AttributedTextView

class YourDrinkingCuesIntroVC: PXTrackedViewController {

    var fadeLyr:CALayer?

    @IBOutlet weak var editBtn: PXSolidButton!
    @IBOutlet weak var myCuesHeaderLbl: UILabel!
    @IBOutlet weak var myCuesListLbl: UILabel!
    @IBOutlet weak var introTextLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        editBtn.tintColor = UIColor.drinkLessGreen()
        // Do any additional setup after loading the view.
        
        self.navigationItem.title = "Your Cues"
        
        screenName = "Your Drinking Cues Intro" // for tracking
        
        myCuesHeaderLbl.textColor = UIColor.drinkLessGreen()
    }
    
    
    //---------------------------------------------------------------------

    /** Defaults to right side */
    private func whiteFadeLayer(referenceView:UIView, percentSize:CGFloat, toBottom:Bool=false) -> CALayer {
        let view = referenceView
        let gradLayer = CAGradientLayer()
        let wh = 240.0/255.0
        gradLayer.colors = [UIColor(white: CGFloat(wh), alpha: 0).cgColor, UIColor(white: CGFloat(wh), alpha: 1).cgColor]
        gradLayer.startPoint = CGPoint(x: 0, y: 0)
        gradLayer.endPoint = CGPoint(x: toBottom ? 0 : 1, y: toBottom ? 1 : 0)
        gradLayer.locations = [0, 1]
        let x = toBottom ? 0 : view.width - view.width * percentSize
        let y = toBottom ? view.height - view.height * percentSize : 0
        let w = toBottom ? view.width : view.width * percentSize
        let h = toBottom ? view.height * percentSize : view.height
        gradLayer.frame = CGRect(x: x, y: y, width: w, height: h)
        return gradLayer
    }
    
    //---------------------------------------------------------------------
    override func viewDidLayoutSubviews() {
        fadeLyr?.removeFromSuperlayer()
        // Draw scroll indication gradient
        let cont = myCuesListLbl.superview!
        let fade = whiteFadeLayer(referenceView: cont, percentSize: 0.21, toBottom: true)
        let y = cont.y + cont.height - fade.frame.height
        var f = fade.frame
        f.origin.y = y
        f.origin.x = 0
        f.size.width = view.width
        fade.frame = f
        view.layer.addSublayer(fade)
        fadeLyr = fade
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let cues = DrinkingCues()
        
        // Assemble text of selected Cues
        var cuesText = ""
        for cue in cues {
            if !cue.isSelected {
                continue
            }
            cuesText += (cue.label + "\n\n")
        }
        cuesText += "\n\n\n"
        let hasCues = cuesText.count > 0
        myCuesHeaderLbl.isHidden = !hasCues
        myCuesListLbl.isHidden = !hasCues
        myCuesListLbl.text = String(cuesText.dropLast(2))
        myCuesListLbl.sizeToFit()
        let btnTxt = hasCues ? "Edit Drinking Cues" : "Identify Drinking Cues"
        editBtn.setTitle(btnTxt, for: .normal)
        
        
        // Set the intro text
        let fontSize = self.introTextLbl.font.pointSize;
        let noCuesIntro = "Do you recognise the situations and events, or how you’re feeling that happen before drinking?\n\nIdentifying these high risk situations for your own drinking can help you drink less."
        let hasCuesIntro = "Do you recognise the situations and events, or how you’re feeling that happen before drinking? Identifying these high risk situations for your own drinking can help you drink less.\n\nNow you’ve identified your drinking cues, why not make a plan for how to deal with them?"
        
        var introText = NSMutableAttributedString()
        if (cuesText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count == 0) {
            introText = NSMutableAttributedString(string:noCuesIntro)
            introTextLbl.attributedText = introText
        } else {
            introText = NSMutableAttributedString(attributedString:(hasCuesIntro
                .match("plan")
// ios13 bug?                .font(UIFont.systemFont(ofSize: fontSize))
                .font(UIFont(name: "HelveticaNeue-Bold", size: fontSize)!)
                .color(UIColor.drinkLessGreen())
                .underline).attributedText)
            introTextLbl.attributedText = introText
            
            // Create plan segue with
            let gr = UITapGestureRecognizer(target: self, action: #selector(handlePlanTapped))
            introTextLbl.addGestureRecognizer(gr)
            introTextLbl.isUserInteractionEnabled = true
        }
        
    PXDailyTaskManager.shared().completeTask(withID:"drinking-cues")
    }
    
    @objc private func handlePlanTapped() {
        let actionPlansVC = UIStoryboard(name: "Activities", bundle: nil).instantiateViewController(withIdentifier: "PXActionPlansViewController")
        self.navigationController!.pushViewController(actionPlansVC, animated: true)

//        let tabVC = self.tabBarController as! PXTabBarController
//        self.navigationController?.popToRootViewController(animated: false)
//        tabVC.showCalendarTab()
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
