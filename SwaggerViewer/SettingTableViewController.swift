//
//  SettingTableViewController.swift
//  SwaggerViewer
//
//  Created by itok on 2018/03/03.
//

import UIKit

extension Notification.Name {
	static let ResetNotification = Notification.Name("resetNotification")
}

class SettingTableViewController: UITableViewController {

	@IBOutlet weak var disableSleepSw: UISwitch!
	
	
    override func viewDidLoad() {
        super.viewDidLoad()

		let defaults = UserDefaults.standard
		disableSleepSw.isOn = defaults.bool(forKey: "disableSleep")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func changeDisableSleep(_ sender: Any) {
		let defaults = UserDefaults.standard
		defaults.set(disableSleepSw.isOn, forKey: "disableSleep")
		defaults.synchronize()
		
		UIApplication.shared.isIdleTimerDisabled = disableSleepSw.isOn
	}
	
	@IBAction func done(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
	
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return section == 1 ? String(format: "SwaggerViewer v%@ © itok", Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String) : nil
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 1 && indexPath.row == 0 {
			// reset
			NotificationCenter.default.post(name: Notification.Name.ResetNotification, object: nil)
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
}
