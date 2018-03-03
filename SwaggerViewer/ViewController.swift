//
//  ViewController.swift
//  SwaggerViewer
//
//  Created by itok on 2018/03/03.
//

import UIKit
import WebKit
import GCDWebServer
import MobileCoreServices

class ViewController: UIViewController {
	@IBOutlet weak var webView: WKWebView!
	
	lazy var server: GCDWebServer! = {
		return GCDWebServer()
	}()
	lazy var rootDirectory: String! = {
		guard let cache = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
			return nil
		}
		return cache + "/www"
	}()
	lazy var fileDirectory: String! = {
		return rootDirectory + "/files"
	}()
	var filename: String?

	override func viewDidLoad() {
		super.viewDidLoad()
		
		start()
		
		NotificationCenter.default.addObserver(forName: Notification.Name.ResetNotification, object: nil, queue: nil) { (_) in
			self.clear()
			self.start()
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func start() {
		let fileMgr = FileManager.default
		if !fileMgr.fileExists(atPath: rootDirectory) {
			if let root = Bundle.main.path(forResource: "swagger-ui", ofType: nil) {
				do {
					try fileMgr.copyItem(atPath: root, toPath: rootDirectory)
				} catch let e {
					print("\(e)")
				}
			}
		}
		
		server.delegate = self
		server.addGETHandler(forBasePath: "/", directoryPath: rootDirectory, indexFilename: nil, cacheAge: 3600, allowRangeRequests: true)
		server.start()
	}

	func clear() {
		server.stop()
		let defaults = UserDefaults.standard
		defaults.removeObject(forKey: "lastFilename")
		defaults.synchronize()
		
		let fileMgr = FileManager.default
		do {
			try fileMgr.removeItem(atPath: rootDirectory)
		} catch let e {
			print("\(e)")
		}
	}
	
	func explore(_ filename: String) {
		self.filename = filename
		webView.navigationDelegate = self
		webView.load(URLRequest(url: server.serverURL!.appendingPathComponent("index.html")))
	}
	
	@IBAction func open(_ sender: Any) {
		let ctl = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String], in: .import)
		ctl.delegate = self
		ctl.allowsMultipleSelection = false
		present(ctl, animated: true, completion: nil)
	}
}


extension ViewController: GCDWebServerDelegate {
	func webServerDidStart(_ server: GCDWebServer) {
		let filename = UserDefaults.standard.object(forKey: "lastFilename") as? String ?? "swagger.json"
		explore(filename)
	}
}

extension ViewController: WKNavigationDelegate {
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		guard let filename = filename else {
			return
		}
		
		let script = """
		const ui = SwaggerUIBundle({
			url: 'files/\(filename)',
			dom_id: '#swagger-ui',
		
			deepLinking: true,
			presets: [
				SwaggerUIBundle.presets.apis,
				SwaggerUIStandalonePreset
			],
			plugins: [
				SwaggerUIBundle.plugins.DownloadUrl
			],
			layout: "StandaloneLayout"
		})
		
		window.ui = ui;
		"""
		
		webView.evaluateJavaScript(script) { (_, error) in
			if let err = error {
				print("\(err)")
			}
		}
		
		let defaults = UserDefaults.standard
		defaults.set(filename, forKey: "lastFilename")
		defaults.synchronize()
	}
}

extension ViewController: UIDocumentPickerDelegate {
	func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
		guard let src = urls.first else {
			controller.dismiss(animated: true, completion: nil)
			return
		}
		
		let filename = src.lastPathComponent
		let dst = URL(fileURLWithPath: fileDirectory + "/" + filename)
		do {
			try FileManager.default.copyItem(at: src, to: dst)
		} catch let e {
			print("\(e)")
		}
		explore(filename)
	}
	
	func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
		controller.dismiss(animated: true, completion: nil)
	}
}
