//
//  ViewController.swift
//  ObjectRecognitionCamera
//
//  Created by a on 13/10/2017.
//  Copyright © 2017 Andreyka. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var infoView: UILabel = {
        
        let lb = UILabel()
        lb.backgroundColor = UIColor.black
        lb.textColor = UIColor.white
        lb.font = UIFont.boldSystemFont(ofSize: 22)
        lb.textAlignment = .center
        lb.numberOfLines = 3
        lb.translatesAutoresizingMaskIntoConstraints = false

        return lb
    }()
    
    var probabilityView: UILabel = {
        
        let lb = UILabel()
        lb.backgroundColor = UIColor.black
        lb.textColor = UIColor.white
        lb.font = UIFont.systemFont(ofSize: 18)
        lb.textAlignment = .center
        lb.translatesAutoresizingMaskIntoConstraints = false
        
        return lb
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let session = setCaptureSession() {
            setUi(session: session)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setUi(session: AVCaptureSession) {
        
        view.backgroundColor = UIColor.black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.frame = view.frame
        
        view.layer.addSublayer(previewLayer)
        
        view.addSubview(infoView)
        view.addSubview(probabilityView)
        
        infoView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        infoView.bottomAnchor.constraint(equalTo: probabilityView.topAnchor).isActive = true
        
        infoView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        infoView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        probabilityView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        probabilityView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        probabilityView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        probabilityView.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func setCaptureSession() -> AVCaptureSession? {
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return nil }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return nil }
        
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let dataOutput = AVCaptureVideoDataOutput()
        
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraQueue"))
        
        captureSession.addOutput(dataOutput)
        
        return captureSession
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let resNetModel = Resnet50().model
        
        guard let model = try? VNCoreMLModel(for: resNetModel) else { return }
        
        let request = VNCoreMLRequest(model: model) {
            
            (finishedRequest, error) in
            
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            print(firstObservation.identifier, firstObservation.confidence)
            
            DispatchQueue.main.async {
                self.infoView.text = "\(firstObservation.identifier)"
                self.probabilityView.text = "Confidence: \(Int(firstObservation.confidence * 100))%"
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

