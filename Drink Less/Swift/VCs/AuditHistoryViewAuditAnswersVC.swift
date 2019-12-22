//
//  AuditHistoryViewAuditAnswersVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 11/10/2018.
//  Copyright © 2018 UCL. All rights reserved.
//

import UIKit

@objc 
class AuditHistoryViewAuditAnswersVC: UITableViewController {

    private var questionsData = NSDictionary()
    private var questionsAndAnswers = Array<Dictionary<String,String>>()
    private var auditData : AuditData?
    
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    @objc class func instantiateFromStoryboard() -> AuditHistoryViewAuditAnswersVC {
        let sb = UIStoryboard(name: "Activities", bundle: nil)
        return sb.instantiateViewController(withIdentifier: "AuditHistoryViewAuditAnswersVC") as! AuditHistoryViewAuditAnswersVC
    }
    
    override func viewDidLoad() {
        self.navigationItem.title = "Audit review"
    }
    
    //---------------------------------------------------------------------

    override func viewWillAppear(_ animated: Bool) {
        auditData = VCInjector.shared.workingAuditData!
        
        let file = auditData!.isFollowUp ? "AuditQuestionsFollowUp" : "AuditQuestions"
        let path = Bundle.main.path(forResource: file, ofType: "plist")!
        questionsData = NSDictionary(contentsOfFile: path)!
        
        
        // Create the q&a dict array
        
        let questionIDs = questionsData.allKeys.sorted { (obj1, obj2) -> Bool in
            let s1 = obj1 as! String
            let s2 = obj2 as! String
            return (s1.compare(s2, options: .numeric, range: nil, locale: .current) == .orderedAscending)
        } as! [String]
        
        // Gender-specific q&a not used now. Would need updating if it comes back
//        var genderIndex =  introManager.auditAnswers["gender"]
//        var gender = questionsData["gender"]["answers"][genderIndex]["answer"] as? String
        
        for questionID: String in questionIDs {
            let questionData = questionsData[questionID] as! [String : Any]
            let answerIndex:Int = auditData?.answer(questionId: questionID)?.intValue ?? 0
            let answer = (questionData["answers"] as! [[String:String]])[answerIndex]["answer"]!
            let questionTitle = questionData["questiontitle"] as! String
//            See above
//            if questionTitle == nil {
//                var genderKey = "\("questiontitle")-\(gender?.lowercased() ?? "")"
//                question = questionData?[genderKey] as? String
//            }
            let dictionary = ["question": questionTitle, "answer": answer]
            questionsAndAnswers.append(dictionary)
        }
    }

    //---------------------------------------------------------------------

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DataServer.shared.trackScreenView("Audit History View Audit Answers")
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Fulfillments
    //////////////////////////////////////////////////////////
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.questionsAndAnswers.count;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1;
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let question = questionsAndAnswers[section]["question"]!
        let date = auditData!.date!.inCurrentCalendarsTimezoneMatchingComponentsToThisOne(inTimezone: auditData!.timezone)!
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "EEEE MMMM d, YYYY"
        let dateString = dateFormat.string(from: date)
        
        if section == 0 {
            return "\nYou gave the following answers on \(dateString):\n\n\(question)"
        }
        return question
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "auditReviewCell", for: indexPath)
        cell.textLabel?.text = questionsAndAnswers[indexPath.section]["answer"]
        return cell
    }

}
