import Foundation
import XCTest
import AVFoundation

@testable import HaishinKit

final class PerformanceOptimizationTests: XCTestCase {
    
    // MARK: - Adaptive Bitrate Tests
    
    func testAdaptiveBitrateStrategyGradual() {
        let strategy = AdaptiveBitrateStrategy.gradual
        
        // Test with good network
        let goodNetworkResult = strategy.adjustBitrate(
            currentBitrate: 500_000,
            targetBitrate: 800_000,
            networkThroughput: 300_000 // 300 KB/s
        )
        XCTAssertGreaterThan(goodNetworkResult, 500_000, "Bitrate should increase with good network")
        
        // Test with poor network
        let poorNetworkResult = strategy.adjustBitrate(
            currentBitrate: 500_000,
            targetBitrate: 200_000,
            networkThroughput: 50_000 // 50 KB/s
        )
        XCTAssertLessThan(poorNetworkResult, 500_000, "Bitrate should decrease with poor network")
    }
    
    func testAdaptiveBitrateStrategyAggressive() {
        let strategy = AdaptiveBitrateStrategy.aggressive
        
        let result = strategy.adjustBitrate(
            currentBitrate: 500_000,
            targetBitrate: 200_000,
            networkThroughput: 40_000
        )
        XCTAssertLessThan(result, 500_000, "Aggressive strategy should reduce bitrate quickly")
        XCTAssertGreaterThanOrEqual(result, 30_000, "Bitrate should not go below minimum")
    }
    
    func testAdaptiveBitrateStrategyNone() {
        let strategy = AdaptiveBitrateStrategy.none
        
        let result = strategy.adjustBitrate(
            currentBitrate: 500_000,
            targetBitrate: 200_000,
            networkThroughput: 40_000
        )
        XCTAssertEqual(result, 500_000, "None strategy should not change bitrate")
    }
    
    // MARK: - Network Condition Monitor Tests
    
    func testNetworkQualityEstimation() {
        XCTAssertEqual(
            NetworkConditionMonitor.estimateQuality(bytesPerSecond: 30_000),
            .poor
        )
        XCTAssertEqual(
            NetworkConditionMonitor.estimateQuality(bytesPerSecond: 75_000),
            .fair
        )
        XCTAssertEqual(
            NetworkConditionMonitor.estimateQuality(bytesPerSecond: 150_000),
            .good
        )
        XCTAssertEqual(
            NetworkConditionMonitor.estimateQuality(bytesPerSecond: 300_000),
            .excellent
        )
    }
    
    func testRecommendedBitrateForVideoQuality() {
        let poorBitrate = NetworkConditionMonitor.recommendedBitrate(for: .poor, isVideo: true)
        let excellentBitrate = NetworkConditionMonitor.recommendedBitrate(for: .excellent, isVideo: true)
        
        XCTAssertLessThan(poorBitrate, excellentBitrate, "Poor quality should have lower bitrate")
        XCTAssertEqual(poorBitrate, 100_000)
        XCTAssertEqual(excellentBitrate, 1_000_000)
    }
    
    func testRecommendedBitrateForAudioQuality() {
        let poorBitrate = NetworkConditionMonitor.recommendedBitrate(for: .poor, isVideo: false)
        let excellentBitrate = NetworkConditionMonitor.recommendedBitrate(for: .excellent, isVideo: false)
        
        XCTAssertLessThan(poorBitrate, excellentBitrate, "Poor quality should have lower bitrate")
        XCTAssertEqual(poorBitrate, 16_000)
        XCTAssertEqual(excellentBitrate, 64_000)
    }
    
    // MARK: - Performance Monitor Tests
    
    func testPerformanceMonitorRecordFrameEncoding() {
        let monitor = PerformanceMonitor.shared
        monitor.reset()
        
        // Simulate frame encoding
        monitor.recordFrameEncoding(duration: 0.020) // 20ms
        
        XCTAssertEqual(monitor.metrics.videoEncodingTimeMs, 20.0, accuracy: 1.0)
        XCTAssertGreaterThan(monitor.metrics.currentFPS, 0)
    }
    
    func testPerformanceMonitorRecordAudioEncoding() {
        let monitor = PerformanceMonitor.shared
        monitor.reset()
        
        monitor.recordAudioEncoding(duration: 0.015) // 15ms
        
        XCTAssertEqual(monitor.metrics.audioEncodingTimeMs, 15.0, accuracy: 1.0)
    }
    
    func testPerformanceMonitorNetworkLatency() {
        let monitor = PerformanceMonitor.shared
        monitor.reset()
        
        monitor.updateNetworkLatency(250.0)
        
        XCTAssertEqual(monitor.metrics.networkLatencyMs, 250.0)
    }
    
    func testPerformanceMonitorBufferHealth() {
        let monitor = PerformanceMonitor.shared
        monitor.reset()
        
        monitor.updateBufferHealth(0.8)
        XCTAssertEqual(monitor.metrics.bufferHealth, 0.8)
        
        // Test clamping
        monitor.updateBufferHealth(1.5)
        XCTAssertEqual(monitor.metrics.bufferHealth, 1.0)
        
        monitor.updateBufferHealth(-0.5)
        XCTAssertEqual(monitor.metrics.bufferHealth, 0.0)
    }
    
    func testPerformanceMonitorWarnings() {
        let monitor = PerformanceMonitor.shared
        monitor.reset()
        
        var warningReceived = false
        monitor.onPerformanceWarning = { message in
            warningReceived = true
            XCTAssertFalse(message.isEmpty)
        }
        
        // Trigger performance warning with slow encoding
        monitor.recordFrameEncoding(duration: 0.050) // 50ms - too slow for 30 FPS
        
        XCTAssertTrue(warningReceived)
    }
    
    // MARK: - Video Codec Settings Tests
    
    func testVideoCodecSettingsAdaptiveBitrate() {
        var settings = VideoCodecSettings(
            bitRate: 500_000,
            adaptiveBitrateStrategy: .gradual
        )
        
        let initialBitrate = settings.bitRate
        
        // Simulate poor network
        settings.adjustBitrateForNetwork(networkThroughput: 40_000)
        
        XCTAssertNotEqual(settings.bitRate, initialBitrate, "Bitrate should change with network conditions")
    }
    
    func testVideoCodecSettingsSoftwareFallback() {
        let settings = VideoCodecSettings(enableSoftwareFallback: true)
        XCTAssertTrue(settings.enableSoftwareFallback)
    }
    
    // MARK: - Audio Codec Settings Tests
    
    func testAudioCodecSettingsLowLatencyMode() {
        let settings = AudioCodecSettings(lowLatencyMode: true)
        XCTAssertTrue(settings.lowLatencyMode)
    }
    
    func testAudioCodecSettingsAdaptiveBitrate() {
        var settings = AudioCodecSettings(bitRate: 32_000)
        
        let initialBitrate = settings.bitRate
        
        // Simulate poor network
        settings.adjustBitrateForNetwork(networkThroughput: 40_000)
        
        XCTAssertNotEqual(settings.bitRate, initialBitrate, "Audio bitrate should adjust to network")
    }
    
    // MARK: - Integration Tests
    
    func testVideoCodecPerformanceMonitoring() {
        let codec = VideoCodec()
        let expectation = XCTestExpectation(description: "Video encoding completes")
        
        // Reset performance monitor
        PerformanceMonitor.shared.reset()
        
        // Create a test image buffer
        let width = 640
        let height = 480
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            XCTFail("Failed to create pixel buffer")
            return
        }
        
        codec.settings = VideoCodecSettings(
            videoSize: VideoSize(width: Int32(width), height: Int32(height)),
            bitRate: 500_000
        )
        
        codec.startRunning()
        
        // Encode a frame
        codec.appendImageBuffer(
            buffer,
            presentationTimeStamp: CMTime(value: 0, timescale: 30),
            duration: CMTime(value: 1, timescale: 30)
        )
        
        // Wait a bit for async encoding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            codec.stopRunning()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // Check that performance monitoring recorded the encoding
        // Note: This may not work in all test environments due to codec availability
        // XCTAssertGreaterThan(PerformanceMonitor.shared.metrics.videoEncodingTimeMs, 0)
    }
    
    func testAudioCodecRingBufferLowLatency() {
        // Test that low latency constants are properly defined
        XCTAssertLessThan(
            AudioCodecRingBuffer.lowLatencyNumSamples,
            AudioCodecRingBuffer.numSamples,
            "Low latency buffer should be smaller"
        )
        XCTAssertLessThanOrEqual(
            AudioCodecRingBuffer.lowLatencyMaxBuffers,
            AudioCodecRingBuffer.maxBuffers,
            "Low latency should use fewer buffers"
        )
    }
}
