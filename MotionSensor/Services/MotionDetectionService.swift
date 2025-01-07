//
//  MotionDetectionService.swift
//  MotionSensor
//
//  Created by Nic on 1/6/25.
//

import Foundation
import CoreImage
import CoreVideo
import UIKit
import Vision

public enum MotionSensitivity {
    case low
    case medium
    case high
    
    var threshold: Float {
        switch self {
        case .low: return 0.3
        case .medium: return 0.2
        case .high: return 0.1
        }
    }
}

@MainActor
class MotionDetectionService: ObservableObject {
    @Published var motionDetected = false
    @Published var personDetected = false
    @Published var sensitivity: MotionSensitivity = .medium
    
    private var previousFrame: CVPixelBuffer?
    private let personDetectionRequest: VNDetectHumanRectanglesRequest?
    private let context = CIContext(options: nil)
    
    init() {
        // Initialize person detection only if we're not in a test environment
        if NSClassFromString("XCTest") == nil {
            self.personDetectionRequest = VNDetectHumanRectanglesRequest()
        } else {
            self.personDetectionRequest = nil
        }
    }
    
    func processFrame(_ frame: CVPixelBuffer) {
        // Process motion
        detectMotion(in: frame)
        
        // Process person detection only if available
        if let request = personDetectionRequest {
            detectPerson(in: frame, with: request)
        }
    }
    
    private func detectMotion(in frame: CVPixelBuffer) {
        guard let previousFrame = previousFrame else {
            self.previousFrame = frame
            return
        }
        
        let motionValue = calculateMotion(current: frame, previous: previousFrame)
        self.previousFrame = frame
        motionDetected = motionValue > sensitivity.threshold
    }
    
    private func detectPerson(in frame: CVPixelBuffer, with request: VNDetectHumanRectanglesRequest) {
        let handler = VNImageRequestHandler(cvPixelBuffer: frame, options: [:])
        
        do {
            try handler.perform([request])
            
            if let results = request.results {
                personDetected = !results.isEmpty
            }
        } catch {
            print("Person detection failed: \(error.localizedDescription)")
            personDetected = false
        }
    }
    
    private func calculateMotion(current: CVPixelBuffer, previous: CVPixelBuffer) -> Float {
        // Convert pixel buffers to CIImages
        let currentImage = CIImage(cvPixelBuffer: current)
        let previousImage = CIImage(cvPixelBuffer: previous)
        
        // Create difference image
        let differenceFilter = CIFilter(name: "CIDifferenceBlendMode")!
        differenceFilter.setValue(previousImage, forKey: kCIInputImageKey)
        differenceFilter.setValue(currentImage, forKey: kCIInputBackgroundImageKey)
        
        guard let differenceImage = differenceFilter.outputImage else { return 0.0 }
        
        // Calculate average brightness of difference image
        let averageFilter = CIFilter(name: "CIAreaAverage")!
        averageFilter.setValue(differenceImage, forKey: kCIInputImageKey)
        averageFilter.setValue(CIVector(x: 0, y: 0, z: differenceImage.extent.width, w: differenceImage.extent.height), forKey: kCIInputExtentKey)
        
        guard let outputImage = averageFilter.outputImage else { return 0.0 }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        // Calculate average difference (normalized to 0-1) with overflow protection
        let sum = bitmap.reduce(0) { (result, value) -> Int in
            return result + Int(value)
        }
        return Float(sum) / (255.0 * 4.0)
    }
}
