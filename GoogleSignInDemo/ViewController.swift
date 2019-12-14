//
//  ViewController.swift
//  GoogleSignInDemo
//
//  Created by Nguyen Uy on 11/12/19.
//  Copyright © 2019 Nguyen Uy. All rights reserved.
//

import Cocoa
import PromiseKit
import SnapKit
import Kingfisher

class ViewController: NSViewController {
    lazy var btnSignIn: NSButton = {
        let btn = NSButton()
        btn.bezelStyle = .smallSquare
        btn.title = "Log out"
        btn.wantsLayer = true
        btn.layer?.backgroundColor = NSColor.red.cgColor
        btn.layer?.masksToBounds = true
        btn.action = #selector(btnClick)
        btn.target = self
        btn.layer?.cornerRadius = 5.0
        return btn
    }()
    
    lazy var avatar: RoundedImageView = {
        let imageView = RoundedImageView()
        return imageView
    }()
    
    lazy var lblName: NSTextField = {
        let txt = NSTextField()
        txt.alignment = .center
        txt.font = NSFont.systemFont(ofSize: 12)
        txt.layer?.backgroundColor = .clear
        txt.isEditable = false
        txt.isBezeled = false
        txt.drawsBackground = false
        txt.textColor = .white
        return txt
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = GoogleSignInService.shared
        
        view.addSubview(avatar)
        avatar.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(75)
        }
        
        view.addSubview(lblName)
        lblName.snp.makeConstraints { (make) in
            make.top.equalTo(avatar.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(20)
        }
        
        view.addSubview(btnSignIn)
        btnSignIn.snp.makeConstraints { (make) in
            make.top.equalTo(lblName.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(35)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.updateState()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func updateState() {
        if GoogleSignInService.shared.isAuthed {
            btnSignIn.title = "Log out"
            btnSignIn.layer?.backgroundColor = NSColor.red.cgColor
        } else {
            btnSignIn.title = "Log in"
            btnSignIn.layer?.backgroundColor = NSColor.blue.cgColor
            avatar.image = nil
            lblName.stringValue = "Not signed in"
        }
    }

    func show(profile: GoogleSignInProfile) {
        if let url = URL(string: profile.picture) {
            avatar.kf.setImage(with: url)
        }
        lblName.stringValue = profile.email
    }

    @objc
    func btnClick() {
        if GoogleSignInService.shared.isAuthed {
            _ = GoogleSignInService.shared.signOut()
            updateState()
        } else {
            GoogleSignInService.shared.signIn().then({ (_) -> Promise<GoogleSignInProfile> in
                return GoogleSignInService.shared.loadProfile()
            }).done({ (profile) in
                self.show(profile: profile)
            }).catch { (error) in
                // Handle error here
            }.finally {
                self.updateState()
            }
        }
    }
}

