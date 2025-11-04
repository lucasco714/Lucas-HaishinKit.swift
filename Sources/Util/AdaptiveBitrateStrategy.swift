import Foundation

/// Strategy for adapting bitrate based on network conditions.
public enum AdaptiveBitrateStrategy: Codable {
    /// No adaptive bitrate adjustment.
    case none
    /// Gradual bitrate adjustment based on network throughput.
    case gradual
    /// Aggressive bitrate adjustment for poor network conditions.
    case aggressive
    
    /// Calculate the adjusted bitrate based on current conditions.
    func adjustBitrate(currentBitrate: UInt32, targetBitrate: UInt32, networkThroughput: Int32) -> UInt32 {
        switch self {
        case .none:
            return currentBitrate
        case .gradual:
            return gradualAdjustment(currentBitrate: currentBitrate, targetBitrate: targetBitrate, networkThroughput: networkThroughput)
        case .aggressive:
            return aggressiveAdjustment(currentBitrate: currentBitrate, targetBitrate: targetBitrate, networkThroughput: networkThroughput)
        }
    }
    
    private func gradualAdjustment(currentBitrate: UInt32, targetBitrate: UInt32, networkThroughput: Int32) -> UInt32 {
        let throughputBitrate = UInt32(max(0, networkThroughput * 8))
        let safeTarget = UInt32(Double(throughputBitrate) * 0.85) // Use 85% of available bandwidth
        
        // Gradually move towards target
        let diff = Int32(targetBitrate) - Int32(currentBitrate)
        let step = diff / 10 // Adjust by 10% each time
        let newBitrate = Int32(currentBitrate) + step
        
        // Clamp to safe range
        return UInt32(max(50_000, min(Int32(safeTarget), newBitrate)))
    }
    
    private func aggressiveAdjustment(currentBitrate: UInt32, targetBitrate: UInt32, networkThroughput: Int32) -> UInt32 {
        let throughputBitrate = UInt32(max(0, networkThroughput * 8))
        let safeTarget = UInt32(Double(throughputBitrate) * 0.75) // Use 75% of available bandwidth
        
        // More aggressive adjustment
        let diff = Int32(targetBitrate) - Int32(currentBitrate)
        let step = diff / 5 // Adjust by 20% each time
        let newBitrate = Int32(currentBitrate) + step
        
        // Clamp to safe range with lower minimum
        return UInt32(max(30_000, min(Int32(safeTarget), newBitrate)))
    }
}

/// Network condition monitoring for adaptive streaming.
public class NetworkConditionMonitor {
    /// Threshold for poor network detection (bytes per second).
    public static let poorNetworkThreshold: Int32 = 50_000
    /// Threshold for good network detection (bytes per second).
    public static let goodNetworkThreshold: Int32 = 200_000
    
    /// Current network quality estimate.
    public enum NetworkQuality {
        case poor
        case fair
        case good
        case excellent
    }
    
    /// Estimate network quality based on throughput.
    public static func estimateQuality(bytesPerSecond: Int32) -> NetworkQuality {
        switch bytesPerSecond {
        case ..<poorNetworkThreshold:
            return .poor
        case poorNetworkThreshold..<100_000:
            return .fair
        case 100_000..<goodNetworkThreshold:
            return .good
        default:
            return .excellent
        }
    }
    
    /// Calculate recommended bitrate based on network quality.
    public static func recommendedBitrate(for quality: NetworkQuality, isVideo: Bool = true) -> UInt32 {
        if isVideo {
            switch quality {
            case .poor:
                return 100_000 // 100 kbps
            case .fair:
                return 250_000 // 250 kbps
            case .good:
                return 500_000 // 500 kbps
            case .excellent:
                return 1_000_000 // 1 Mbps
            }
        } else {
            // Audio bitrates
            switch quality {
            case .poor:
                return 16_000 // 16 kbps
            case .fair:
                return 24_000 // 24 kbps
            case .good:
                return 32_000 // 32 kbps
            case .excellent:
                return 64_000 // 64 kbps
            }
        }
    }
}
