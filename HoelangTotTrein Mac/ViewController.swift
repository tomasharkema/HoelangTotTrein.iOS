//
//  ViewController.swift
//  HoelangTotTrein Mac
//
//  Created by Tomas Harkema on 04-03-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

  @IBOutlet weak var fromLabel: NSTextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.fromLabel.stringValue = NSUbiquitousKeyValueStore.defaultStore().stringForKey("FromKey") ?? ""
    
    // Do any additional setup after loading the view.
  }

  override var representedObject: AnyObject? {
    didSet {
    // Update the view, if already loaded.
    }
  }


}

