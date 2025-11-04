import AVFAudio
import Foundation

/// The AudioCodecSettings class  specifying audio compression settings.
public struct AudioCodecSettings: Codable {
    /// The defualt value.
    public static let `default` = AudioCodecSettings()

    /// Specifies the bitRate of audio output.
    public var bitRate: Int
    /// Specifies whether to use low latency mode with smaller buffers.
    public var lowLatencyMode: Bool
    
    // Constants for bitrate adjustment
    private static let adjustmentStep = 5
    private static let minAudioBitrate = 8_000
    private static let maxAudioBitrate = 64_000

    /// Create an new AudioCodecSettings instance.
    public init(bitRate: Int = 32 * 1000, lowLatencyMode: Bool = false) {
        self.bitRate = bitRate
        self.lowLatencyMode = lowLatencyMode
    }

    func apply(_ converter: AVAudioConverter?, oldValue: AudioCodecSettings?) {
        guard let converter else {
            return
        }
        if bitRate != oldValue?.bitRate {
            let minAvailableBitRate = converter.applicableEncodeBitRates?.min(by: { a, b in
                return a.intValue < b.intValue
            })?.intValue ?? bitRate
            let maxAvailableBitRate = converter.applicableEncodeBitRates?.max(by: { a, b in
                return a.intValue < b.intValue
            })?.intValue ?? bitRate
            converter.bitRate = min(maxAvailableBitRate, max(minAvailableBitRate, bitRate))
        }
    }
    
    /// Adjust bitrate based on network conditions.
    mutating func adjustBitrateForNetwork(networkThroughput: Int32) {
        let quality = NetworkConditionMonitor.estimateQuality(bytesPerSecond: networkThroughput)
        let recommendedBitrate = NetworkConditionMonitor.recommendedBitrate(for: quality, isVideo: false)
        
        // Gradually adjust towards recommended bitrate
        let targetBitrate = Int(recommendedBitrate)
        let diff = targetBitrate - bitRate
        let step = diff / Self.adjustmentStep
        bitRate = max(Self.minAudioBitrate, min(Self.maxAudioBitrate, bitRate + step))
    }
}
