//
//  ViewController.swift
//  DemoSIP
//
//  Created by APPLE on 01/10/26.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    let sipManager = SIPManager()
    @IBOutlet weak var lblSIPStatus: UILabel!
    @IBOutlet weak var tfSIP: UITextField!
    @IBOutlet weak var btnnCall: UIButton!
    @IBOutlet weak var btnEndCall: UIButton!
    @IBOutlet weak var lblCallStatus: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblSIPStatus.text = "● Registering..."
        lblCallStatus.text = "Ready"
        btnnCall.layer.cornerRadius = btnnCall.frame.height / 2
        btnnCall.clipsToBounds = true
        btnEndCall.layer.cornerRadius = btnEndCall.frame.height / 2
        btnEndCall.clipsToBounds = true
        btnnCall.isEnabled = true
        btnEndCall.isEnabled = false
        tfSIP.keyboardType = .numberPad
        tfSIP.delegate = self
        
        sipManager.onRegistrationStatus = { [weak self] status in DispatchQueue.main.async { self?.lblSIPStatus.text = status
        }
        }

        sipManager.onCallStatus = { [weak self] status in

            DispatchQueue.main.async {

                self?.lblCallStatus.text = status

                if status == "Calling..." ||
                   status == "Ringing..." ||
                   status == "Connected" {

                    self?.btnnCall.isEnabled = false
                    self?.btnEndCall.isEnabled = true

                } else if status == "Call Ended" {

                    self?.btnnCall.isEnabled = true
                    self?.btnEndCall.isEnabled = false
                }
            }
        }
        sipManager.startPJSIP()
        addKeyboardToolbar()

    }
    
    @IBAction func buttonCallAction(_ sender: UIButton) {
        guard let number = tfSIP.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !number.isEmpty else {
            
            print("Please enter SIP number")
            let alert = UIAlertController( title: "Invalid SIP Number", message: "Please enter a SIP number.", preferredStyle: .alert )
            alert.addAction( UIAlertAction( title: "OK", style: .default ) )
            present(alert, animated: true)
            return
        }
        
        print("Calling: \(number)")
        sipManager.makeCall(to: number)
        btnnCall.isEnabled = false
        btnEndCall.isEnabled = true

    }
    @IBAction func btnEndCallAction(_ sender: UIButton) {
        sipManager.endCall()
        btnnCall.isEnabled = true
        btnEndCall.isEnabled = false
    }

    private func addKeyboardToolbar() {

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )

        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissKeyboard)
        )

        toolbar.items = [flexibleSpace, doneButton]

        // Your number pad TextField
        tfSIP.inputAccessoryView = toolbar
    }

    @objc private func dismissKeyboard() {
        tfSIP.resignFirstResponder()
    }
}

