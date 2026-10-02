//
//  SIPManager.swift
//  DemoSIP
//
//  Created by APPLE on 01/10/26.
//

import Foundation
import AVFoundation

final class SIPManager {
    private let sipDomain = "pbx14.vitelglobal.com"
    private let sipUsername = "5009"
    private let sipPassword = "2s%.ejUB$K9$qsA!XJpt"
    
    private static weak var sharedManager: SIPManager?
    var onRegistrationStatus: ((String) -> Void)?
    var onCallStatus: ((String) -> Void)?
    
    private var sipIDCString: [CChar] = []
    private var registrarCString: [CChar] = []
    private var usernameCString: [CChar] = []
    private var domainCString: [CChar] = []
    private var passwordCString: [CChar] = []
    private var digestCString: [CChar] = []
    
    private func setupCallbacks(_ config: inout pjsua_config) {
        // MARK: - SIP Registration Callback
        config.cb.on_reg_state = { accountID in
            print("SIP registration state changed")
            print("Account ID: \(accountID)")
            var accountInfo = pjsua_acc_info()
            let status = pjsua_acc_get_info(
                accountID,
                &accountInfo
            )
            if status != PJ_SUCCESS.rawValue {
                print("Failed to get account info: \(status)")
                SIPManager.sharedManager?.onRegistrationStatus?(
                    "● Registration Failed"
                )
                return
            }
            
            let statusCode = accountInfo.status.rawValue
            print("SIP Status Code: \(statusCode)")
            if statusCode == 200 {
                SIPManager.sharedManager?.onRegistrationStatus?(
                    "● SIP Registered"
                )
            } else {
                
                SIPManager.sharedManager?.onRegistrationStatus?(
                    "● Not Registered (\(statusCode))"
                )
            }
        }
        // MARK: - Call State Callback
        config.cb.on_call_state = { callID, event in
            var callInfo = pjsua_call_info()
            let status = pjsua_call_get_info(
                callID,
                &callInfo
            )
            if status != PJ_SUCCESS.rawValue {
                print("Failed to get call info")
                return
            }
            let callState = callInfo.state.rawValue
            print("Call State: \(callState)")
            
            switch callState {
            case 1:
                // CALLING
                print("Calling...")
                SIPManager.sharedManager?.onCallStatus?(
                    "Calling..."
                )
            case 3:
                // CONFIRMED / RINGING state mapping for current test
                print("Ringing...")
                SIPManager.sharedManager?.onCallStatus?(
                    "Ringing..."
                )
            case 4:
                // CONNECTED
                print("Connected")
                SIPManager.sharedManager?.onCallStatus?(
                    "Connected"
                )
            case 6:
                // DISCONNECTED
                print("Call Ended")
                SIPManager.sharedManager?.onCallStatus?(
                    "Call Ended"
                )
            default:
                print("Call State: \(callState)")
                SIPManager.sharedManager?.onCallStatus?(
                    "Call Status: \(callState)"
                )
            }
        }
    }
    
    func startPJSIP() {
        SIPManager.sharedManager = self
        // MARK: - Create PJSUA
        var status = pjsua_create()
        if status != PJ_SUCCESS.rawValue {
            print("pjsua_create failed: \(status)")
            return
        }
        print("PJSUA created")
        
        // MARK: - PJSUA Configuration
        var config = pjsua_config()
        pjsua_config_default(&config)
        // Setup all callbacks in one place
        setupCallbacks(&config)
        
        // MARK: - Logging Configuration
        var logConfig = pjsua_logging_config()
        pjsua_logging_config_default(&logConfig)
        logConfig.console_level = 5
        logConfig.level = 5
        
        // MARK: - Media Configuration
        var mediaConfig = pjsua_media_config()
        pjsua_media_config_default(&mediaConfig)
        
        // MARK: - Initialize PJSUA
        status = pjsua_init(
            &config,
            &logConfig,
            &mediaConfig
        )
        
        if status != PJ_SUCCESS.rawValue {
            print("pjsua_init failed: \(status)")
            pjsua_destroy()
            return
        }
        print("PJSUA initialized")
        
        // MARK: - UDP Transport
        var transportConfig = pjsua_transport_config()
        pjsua_transport_config_default(
            &transportConfig
        )
        transportConfig.port = 5060
        var transportID = pjsua_transport_id()
        status = pjsua_transport_create(
            PJSIP_TRANSPORT_UDP,
            &transportConfig,
            &transportID
        )
        
        if status != PJ_SUCCESS.rawValue {
            print("UDP transport creation failed: \(status)")
            pjsua_destroy()
            return
        }
        print("UDP transport created")
        
        // MARK: - Start PJSUA
        status = pjsua_start()
        if status != PJ_SUCCESS.rawValue {
            print("PJSUA start failed: \(status)")
            pjsua_destroy()
            return
        }
        print("PJSUA started")
        // MARK: - SIP Account Configuration
        var accountConfig = pjsua_acc_config()
        pjsua_acc_config_default(
            &accountConfig
        )
        
        //MARK: - SIP Identity
        sipIDCString = Array(
            "sip:\(sipUsername)@\(sipDomain)".utf8CString
        )
        registrarCString = Array(
            "sip:\(sipDomain)".utf8CString
        )
        usernameCString = Array(
            sipUsername.utf8CString
        )
        domainCString = Array(
            sipDomain.utf8CString
        )
        passwordCString = Array(
            sipPassword.utf8CString
        )
        digestCString = Array(
            "digest".utf8CString
        )
        
        //MARK: - SIP ID
        
        sipIDCString.withUnsafeMutableBufferPointer { buffer in
            accountConfig.id = pj_str(
                buffer.baseAddress!
            )
        }
        
        //MARK: - Registrar
        registrarCString.withUnsafeMutableBufferPointer { buffer in
            
            accountConfig.reg_uri = pj_str(
                buffer.baseAddress!
            )
        }
        
        // MARK: - Authentication
        accountConfig.cred_count = 1
        domainCString.withUnsafeMutableBufferPointer { domainBuffer in
            
            usernameCString.withUnsafeMutableBufferPointer { usernameBuffer in
                
                passwordCString.withUnsafeMutableBufferPointer { passwordBuffer in
                    
                    digestCString.withUnsafeMutableBufferPointer { digestBuffer in
                        
                        accountConfig.cred_info.0.realm =
                        pj_str(domainBuffer.baseAddress!)
                        
                        accountConfig.cred_info.0.scheme =
                        pj_str(digestBuffer.baseAddress!)
                        
                        accountConfig.cred_info.0.username =
                        pj_str(usernameBuffer.baseAddress!)
                        
                        accountConfig.cred_info.0.data_type = 0
                        
                        accountConfig.cred_info.0.data =
                        pj_str(passwordBuffer.baseAddress!)
                    }
                }
            }
        }
        // MARK: - Add SIP Account
        var accountID = pjsua_acc_id()
        status = pjsua_acc_add(
            &accountConfig,
            1,
            &accountID
        )
        
        if status != PJ_SUCCESS.rawValue {
            print("SIP account add failed: \(status)")
            return
        }
        print("SIP account added")
        print("Account ID: \(accountID)")
    }
    
    //    MARK: - Make CALL
    func makeCall(to username: String) {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.allowBluetooth]
            )
            
            try audioSession.setActive(true)
            print("AVAudioSession activated")
            
        } catch {
            print("AVAudioSession error: \(error)")
            return
        }
        
        let destination = "sip:\(username)@\(sipDomain)"
        var callID = pjsua_call_id()
        let status = destination.withCString { destinationCString in
            
            var uri = pj_str(
                UnsafeMutablePointer(mutating: destinationCString)
            )
            
            var callSetting = pjsua_call_setting()
            pjsua_call_setting_default(&callSetting)
            
            return pjsua_call_make_call(
                0,
                &uri,
                &callSetting,
                nil,
                nil,
                &callID
            )
        }
        if status != PJ_SUCCESS.rawValue {
            print("Call failed: \(status)")
            return
        }
        print("Calling \(destination)")
        print("Call ID: \(callID)")
    }
    
    func endCall() {
        pjsua_call_hangup_all()
        print("Call ended")
    }
}
