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

    override func viewDidLoad() {
        super.viewDidLoad()

        if let session = setCaptureSession() {
            setUi(session: session)
        }
    }
    
    private func setUi(session: AVCaptureSession) {
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.frame = view.frame
        
        view.layer.addSublayer(previewLayer)
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
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

