//
//  ViewController.swift
//  SOSpeechtoText
//
//  Created by Hitesh on 9/21/16.
//  Copyright © 2016 myCompany. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var txtSpeech: UITextView!
    @IBOutlet weak var btnRecord: UIButton!
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(localeIdentifier: "en-US"))
    
    var regRequest: SFSpeechAudioBufferRecognitionRequest?
    var regTask: SFSpeechRecognitionTask?
    let avEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnRecord.isEnabled = false
        btnRecord.layer.cornerRadius = btnRecord.frame.size.height/2
        btnRecord.layer.masksToBounds = true
        txtSpeech.text = ""
        
        speechRecognizer?.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        getPermissionSpeechRecognizer()
    }
    
    func getPermissionSpeechRecognizer() {
        SFSpeechRecognizer.requestAuthorization { (status) in
            switch status {
            case .authorized:
                self.btnRecord.isEnabled = true
                break
            case .denied:
                self.btnRecord.isEnabled = false
                break
            case .notDetermined:
                self.btnRecord.isEnabled = false
                break
            case .restricted:
                self.btnRecord.isEnabled = false
                break
            }
        }
    }
    

    @IBAction func actionRecording(_ sender: AnyObject) {
        if avEngine.isRunning {
            avEngine.stop()
            regRequest?.endAudio()
            btnRecord.setTitle("Record", for: [])
            txtSpeech.text = ""
        } else {
            startRecording()
            btnRecord.setTitle("Stop", for: [])
        }
    }
    
    
    func startRecording() {
        
        //Cancel task if already running
        if regTask != nil {
            regTask?.cancel()
            regTask = nil
        }
        
        
        //Create and AVAudioSession for audio recording
        let avAudioSession = AVAudioSession.sharedInstance()
        do {
            try avAudioSession.setCategory(AVAudioSessionCategoryRecord)
            try avAudioSession.setMode(AVAudioSessionModeMeasurement)
            try avAudioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Audio Session is not active")
        }
        
        //Check the Audio input.
        guard let inputEngineNode = avEngine.inputNode else {
            fatalError("Some Error")
        }
        
        
        regRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = regRequest else {
            fatalError("SFSpeechAudioBufferRecognitionRequest object is not created")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        //Start task of speech recognition
        regTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isComplete = false
            
            if result != nil {
                self.txtSpeech.text = result?.bestTranscription.formattedString
                isComplete = (result?.isFinal)!
            }
            
            if error != nil || isComplete {
                self.avEngine.stop()
                inputEngineNode.removeTap(onBus: 0)
                
                self.regRequest = nil
                self.regTask = nil
            }
        })
        
        
        //Set Formation of Audio Input
        let recordingFormat = inputEngineNode.outputFormat(forBus: 0)
        inputEngineNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.regRequest?.append(buffer)
        }
        
        avEngine.prepare()
        
        do {
            try avEngine.start()
        } catch {
            print("some error")
        }
    }
    
    //MARK:- SFSpeechRecognizer Delegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

