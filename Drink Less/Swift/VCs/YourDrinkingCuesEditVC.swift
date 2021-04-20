//
//  YourDrinkingCuesEditVC.swift
//  drinkless
//
//  Created by Hari Karam Singh on 09/03/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import UIKit

class YourDrinkingCuesEditVC: PXTrackedViewController, UITableViewDelegate, UITableViewDataSource {
    
    var fadeLyr:CALayer?
    
    let ADD_YOUR_OWN_HEIGHT:CGFloat = 50
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var saveBtn: PXSolidButton!
    
    private var drinkingCues = DrinkingCues()
    
    //////////////////////////////////////////////////////////
    // MARK: - Life Cycle
    //////////////////////////////////////////////////////////
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.dataSource = self
        table.delegate = self
        table.sectionHeaderHeight = ADD_YOUR_OWN_HEIGHT
        table.tintColor = UIColor.drinkLessGreen()
        saveBtn.tintColor = UIColor.drinkLessGreen()
        // Do any additional setup after loading the view.
        
        title = "Edit Your Cues"
        screenName = "Your Drinking Cues Edit" // for tracking
        
        let ins = table.contentInset
        table.contentInset = UIEdgeInsets(top: ins.top, left: ins.left, bottom: 40, right: ins.right)
    }
    
    override func viewDidLayoutSubviews() {
        fadeLyr?.removeFromSuperlayer()
        // Draw scroll indication gradient
        let fade = whiteFadeLayer(referenceView: table, percentSize: 0.21, toBottom: true)
        let y = table.y + table.height - fade.frame.height
        var f = fade.frame
        f.origin.y = y
        f.origin.x = 0 //table.x
        f.size.width = view.width
        fade.frame = f
        view.layer.addSublayer(fade)
        fadeLyr = fade
    }
    
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

    
    //////////////////////////////////////////////////////////
    // MARK: - Data Source & Delegate
    //////////////////////////////////////////////////////////

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drinkingCues.count + 1  // for add your own
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "CellId")!
        cell.backgroundColor = .clear
        let cue = drinkingCues[indexPath.item]
        cell.textLabel!.text = cue.label
        cell.textLabel!.font = cell.textLabel!.font.withBoldToggled(cue.isSelected)
        cell.accessoryType = cue.isSelected ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cont = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: ADD_YOUR_OWN_HEIGHT))
        cont.backgroundColor = self.view.backgroundColor
        let btn = UIButton(type: .system)
        btn.setTitle("Add your own...", for: .normal)
        btn.titleLabel!.font = UIFont.boldSystemFont(ofSize: 17)
        btn.contentHorizontalAlignment = .left
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0);

        btn.sizeToFit()
        btn.x = 0
        btn.width = cont.width - btn.x*2
        btn.height = ADD_YOUR_OWN_HEIGHT
        btn.addTarget(self, action: #selector(YourDrinkingCuesEditVC.addYourOwnPressed), for: .touchUpInside)
        cont.addSubview(btn)
        
        let v = UIView(frame: cont.frame)
        v.height = 1
        v.backgroundColor = UIColor.drinkLessLightGrey()
        v.y = cont.height - v.height
        v.x = 12
        v.width = cont.width - v.x
        cont.addSubview(v)
        
        return cont
    }
    
    //---------------------------------------------------------------------

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = .clear
        let wasTicked = cell!.accessoryType != .none
        cell!.accessoryType = wasTicked ? .none : .checkmark
        cell!.textLabel!.font = cell!.textLabel!.font.withBoldToggled(!wasTicked)
        tableView.deselectRow(at: indexPath, animated: false)
        drinkingCues[indexPath.item].isSelected = !wasTicked
        drinkingCues.save()
        
        let params = [
            "action": wasTicked ? "DESELECT" : "SELECT",
            "label": drinkingCues[indexPath.item].label
        ]
        self.server.saveDataObject(className: "DrinkingCue", objectId: nil, isUser: true, params: params, ensureSave: false, callback: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            table.beginUpdates()
            table.deleteRows(at: [indexPath], with: .fade)
            let cue = drinkingCues[indexPath.item]
            drinkingCues.remove(cue)
            table.endUpdates()
            
            let params = [
                "action": "DELETE",
                "label": cue.label
            ]
            self.server.saveDataObject(className: "DrinkingCue", objectId: nil, isUser: true, params: params, ensureSave: false, callback: nil)
        }
    }
    
    @IBAction func editTable(_ sender: Any) {
        table.setEditing(!table.isEditing, animated: true)
        let bbi = self.navigationItem.rightBarButtonItem
        bbi!.title = table.isEditing ? "Done" : "Edit"
}

    
    //////////////////////////////////////////////////////////
    // MARK: - Event Handlers
    //////////////////////////////////////////////////////////
    
    @IBAction func savePressed(_ sender: Any) {
        //self.dismiss(animated: true, completion: nil)
        self.navigationController!.popViewController(animated: true)
    }
    
    @objc func addYourOwnPressed() {
        let alert = UIAlertController.textPromptAlert(title: "Add your own cue", message: nil) { (userText:String?) in
            guard let cueTxt = userText else { return }
            self.drinkingCues.addCue(cueTxt, isSelected: true)
            let pos = self.drinkingCues.index(of: cueTxt)  // a bit ugly but oh well. I suppose sorting should be handled by the VC really...
            self.table.beginUpdates()
            self.table.insertRows(at: [IndexPath(item: pos, section: 0)], with: .fade)
            self.table.endUpdates()
            
            let params = [
                "action": "ADD+SELECT",
                "label": cueTxt
            ]
            self.server.saveDataObject(className: "DrinkingCue", objectId: nil, isUser: true, params: params, ensureSave: false, callback: nil)
        }
        self.present(alert, animated: true, completion: nil)
    }
}
