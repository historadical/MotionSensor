//
//  SendablePixelBuffer.swift
//  MotionSensor
//
//  Created by Nic on 1/6/25.
//

import Foundation
import CoreVideo

@frozen
public struct SendablePixelBuffer: @unchecked Sendable {
    private let buffer: CVPixelBuffer
    
    public init(copying originalBuffer: CVPixelBuffer) {
        var pixelBufferCopy: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                           CVPixelBufferGetWidth(originalBuffer),
                           CVPixelBufferGetHeight(originalBuffer),
                           CVPixelBufferGetPixelFormatType(originalBuffer),
                           nil,
                           &pixelBufferCopy)
        
        guard let safeCopy = pixelBufferCopy else {
            fatalError("Failed to create pixel buffer copy")
        }
        
        CVPixelBufferLockBaseAddress(originalBuffer, [])
        CVPixelBufferLockBaseAddress(safeCopy, [])
        
        memcpy(CVPixelBufferGetBaseAddress(safeCopy),
               CVPixelBufferGetBaseAddress(originalBuffer),
               CVPixelBufferGetDataSize(originalBuffer))
        
        CVPixelBufferUnlockBaseAddress(safeCopy, [])
        CVPixelBufferUnlockBaseAddress(originalBuffer, [])
        
        self.buffer = safeCopy
    }
    
    public var pixelBuffer: CVPixelBuffer {
        buffer
    }
}
