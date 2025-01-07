//
//  ContentView.swift
//  MotionSensor
//
//  Created by Nic on 1/6/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var motionService = MotionDetectionService()
    @State private var captureSession = AVCaptureSession()
    @State private var isSetup = false
    
    var body: some View {
        VStack {
            VStack(spacing: 20) {
                Text(motionService.motionDetected ? "Motion Detected!" : "No Motion")
                    .font(.title)
                    .foregroundColor(motionService.motionDetected ? .red : .green)
                
                Text(motionService.personDetected ? "Person Detected!" : "No Person")
                    .font(.title2)
                    .foregroundColor(motionService.personDetected ? .blue : .gray)
            }
            
            Picker("Sensitivity", selection: $motionService.sensitivity) {
                Text("Low").tag(MotionSensitivity.low)
                Text("Medium").tag(MotionSensitivity.medium)
                Text("High").tag(MotionSensitivity.high)
            }
            .pickerStyle(.segmented)
            .padding()
        }
        .onAppear {
            setupCaptureSession()
        }
    }
    
    private func setupCaptureSession() {
        guard !isSetup else { return }
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(CameraDelegate(motionService: motionService), queue: DispatchQueue(label: "videoQueue"))
        
        captureSession.addInput(input)
        captureSession.addOutput(output)
        
        Task.detached {
            captureSession.startRunning()
        }
        
        isSetup = true
    }
}

class CameraDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let motionService: MotionDetectionService
    
    init(motionService: MotionDetectionService) {
        self.motionService = motionService
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        Task { @MainActor in
            motionService.processFrame(pixelBuffer)
        }
    }
}
