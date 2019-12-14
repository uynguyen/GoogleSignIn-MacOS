//
//  AppDelegate.swift
//  GoogleSignInDemo
//
//  Created by Nguyen Uy on 11/12/19.
//  Copyright © 2019 Nguyen Uy. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handle(getURLEvent:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc
    func handle(getURLEvent event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        if let string = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
            let url = URL(string: string) {
            GoogleSignInService.shared
                .currentAuthorizationFlow?.resumeExternalUserAgentFlow(with: url)
        }
    }
}

