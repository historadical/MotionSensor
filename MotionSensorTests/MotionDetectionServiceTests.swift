//
//  MotionDetectionServiceTests.swift
//  MotionSensorTests
//
//  Created by Nic on 1/6/25.
//

import XCTest
import CoreImage
import CoreVideo
import Vision
@testable import MotionSensor

@MainActor
final class MotionDetectionServiceTests: XCTestCase {
    var motionService: MotionDetectionService!
    
    override func setUp() async throws {
        try await super.setUp()
        motionService = MotionDetectionService()
    }
    
    override func tearDown() async throws {
        motionService = nil
        try await super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(motionService.motionDetected)
        XCTAssertEqual(motionService.sensitivity, .medium)
    }
    
    func testNoMotionDetection() {
        // Create two identical frames
        let size = CGSize(width: 100, height: 100)
        let frame1 = createPixelBuffer(size: size)
        let frame2 = createPixelBuffer(size: size)
        
        // Process frames
        motionService.processFrame(frame1)
        motionService.processFrame(frame2)
        
        XCTAssertFalse(motionService.motionDetected)
    }
    
    func testMotionDetection() {
        // Create two different frames
        let size = CGSize(width: 100, height: 100)
        let frame1 = createPixelBuffer(size: size)
        let frame2 = createPixelBuffer(size: size)
        
        // Draw different patterns in each frame
        drawTestPattern(in: frame1, offset: 0)
        drawTestPattern(in: frame2, offset: 50) // Significant movement
        
        // Set high sensitivity to ensure detection
        motionService.sensitivity = .high
        
        // Process frames
        motionService.processFrame(frame1)
        motionService.processFrame(frame2)
        
        XCTAssertTrue(motionService.motionDetected)
    }
    
    func testSensitivityLevels() {
        // Create frames with small movement
        let size = CGSize(width: 100, height: 100)
        let frame1 = createPixelBuffer(size: size)
        let frame2 = createPixelBuffer(size: size)
        
        drawTestPattern(in: frame1, offset: 0)
        drawTestPattern(in: frame2, offset: 20) // Small movement
        
        // Test different sensitivity levels
        let sensitivities: [MotionSensitivity] = [.low, .medium, .high]
        var detectionResults: [Bool] = []
        
        for sensitivity in sensitivities {
            motionService.sensitivity = sensitivity
            motionService.processFrame(frame1)
            motionService.processFrame(frame2)
            detectionResults.append(motionService.motionDetected)
        }
        
        // Higher sensitivity should detect more motion
        XCTAssertFalse(detectionResults[0], "Low sensitivity should not detect small movement")
        XCTAssertTrue(detectionResults[2], "High sensitivity should detect small movement")
    }
    
    // MARK: - Helper Methods
    
    private func createPixelBuffer(size: CGSize) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                           Int(size.width),
                           Int(size.height),
                           kCVPixelFormatType_32ARGB,
                           attrs,
                           &pixelBuffer)
        
        guard let buffer = pixelBuffer else {
            fatalError("Could not create pixel buffer")
        }
        
        return buffer
    }
    
    private func drawTestPattern(in pixelBuffer: CVPixelBuffer, offset: CGFloat) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0)) }
        
        let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                              width: CVPixelBufferGetWidth(pixelBuffer),
                              height: CVPixelBufferGetHeight(pixelBuffer),
                              bitsPerComponent: 8,
                              bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
        
        // Draw a simple pattern
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(x: offset, y: offset, width: 30, height: 30))
    }
}
