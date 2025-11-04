import Foundation

/// Performance monitoring for streaming operations.
public class PerformanceMonitor {
    /// Performance metrics snapshot.
    public struct Metrics {
        /// Video encoding time in milliseconds.
        public var videoEncodingTimeMs: Double = 0
        /// Audio encoding time in milliseconds.
        public var audioEncodingTimeMs: Double = 0
        /// Current frames per second.
        public var currentFPS: Double = 0
        /// Dropped frame count.
        public var droppedFrames: Int = 0
        /// Average network latency in milliseconds.
        public var networkLatencyMs: Double = 0
        /// Buffer health (0.0 to 1.0, where 1.0 is optimal).
        public var bufferHealth: Double = 1.0
    }
    
    /// Singleton instance.
    public static let shared = PerformanceMonitor()
    
    /// Current performance metrics.
    public private(set) var metrics = Metrics()
    
    /// Performance warning threshold callback.
    public var onPerformanceWarning: ((String) -> Void)?
    
    private var frameTimestamps: [TimeInterval] = []
    private let maxFrameHistory = 60
    private var lastFrameTime: TimeInterval?
    
    private init() {}
    
    /// Record a frame encoding event.
    public func recordFrameEncoding(duration: TimeInterval) {
        let now = Date().timeIntervalSince1970
        frameTimestamps.append(now)
        
        // Keep only recent frames
        if frameTimestamps.count > maxFrameHistory {
            frameTimestamps.removeFirst()
        }
        
        // Calculate FPS
        if frameTimestamps.count > 1 {
            let timeSpan = frameTimestamps.last! - frameTimestamps.first!
            if timeSpan > 0 {
                metrics.currentFPS = Double(frameTimestamps.count) / timeSpan
            }
        }
        
        // Check for frame drops
        if let lastTime = lastFrameTime {
            let expectedInterval = 1.0 / 30.0 // Assuming 30 FPS target
            let actualInterval = now - lastTime
            if actualInterval > expectedInterval * 1.5 {
                metrics.droppedFrames += 1
                onPerformanceWarning?("Frame drop detected: interval \(actualInterval * 1000)ms")
            }
        }
        lastFrameTime = now
        
        // Update encoding time
        metrics.videoEncodingTimeMs = duration * 1000
        
        // Check if encoding is taking too long
        if duration > 0.033 { // More than 33ms (30 FPS threshold)
            onPerformanceWarning?("Video encoding taking too long: \(duration * 1000)ms")
        }
    }
    
    /// Record an audio encoding event.
    public func recordAudioEncoding(duration: TimeInterval) {
        metrics.audioEncodingTimeMs = duration * 1000
        
        // Check if audio encoding is taking too long
        if duration > 0.020 { // More than 20ms
            onPerformanceWarning?("Audio encoding taking too long: \(duration * 1000)ms")
        }
    }
    
    /// Update network latency metric.
    public func updateNetworkLatency(_ latencyMs: Double) {
        metrics.networkLatencyMs = latencyMs
        
        // Warn on high latency
        if latencyMs > 500 {
            onPerformanceWarning?("High network latency detected: \(latencyMs)ms")
        }
    }
    
    /// Update buffer health metric.
    public func updateBufferHealth(_ health: Double) {
        metrics.bufferHealth = max(0.0, min(1.0, health))
        
        // Warn on low buffer health
        if health < 0.3 {
            onPerformanceWarning?("Low buffer health: \(Int(health * 100))%")
        }
    }
    
    /// Reset all metrics.
    public func reset() {
        metrics = Metrics()
        frameTimestamps.removeAll()
        lastFrameTime = nil
    }
    
    /// Get a summary of current performance.
    public func getSummary() -> String {
        return """
        Performance Metrics:
        - FPS: \(String(format: "%.1f", metrics.currentFPS))
        - Video Encoding: \(String(format: "%.2f", metrics.videoEncodingTimeMs))ms
        - Audio Encoding: \(String(format: "%.2f", metrics.audioEncodingTimeMs))ms
        - Dropped Frames: \(metrics.droppedFrames)
        - Network Latency: \(String(format: "%.1f", metrics.networkLatencyMs))ms
        - Buffer Health: \(Int(metrics.bufferHealth * 100))%
        """
    }
}
