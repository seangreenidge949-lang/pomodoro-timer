import AVFoundation

/// Generates a C5-E5 chime using AVAudioEngine sine wave synthesis.
/// Pattern: 4 notes alternating C5/E5, each 0.4s with 0.05s gap, volume fading.
class AudioManager {
    static let shared = AudioManager()

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    private let sampleRate: Double = 44100
    private let c5Freq: Double = 523.25   // C5
    private let e5Freq: Double = 659.25   // E5

    func playChime() {
        stop()

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        // Generate 4-note chime buffer
        let buffer = generateChimeBuffer(format: format)

        do {
            try engine.start()
            player.play()
            player.scheduleBuffer(buffer) { [weak self] in
                DispatchQueue.main.async {
                    self?.stop()
                }
            }
            self.engine = engine
            self.playerNode = player
        } catch {
            print("Audio engine error: \(error)")
        }
    }

    func stop() {
        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil
    }

    private func generateChimeBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer {
        let noteDuration: Double = 0.4
        let gap: Double = 0.05
        let noteInterval = noteDuration + gap
        let totalDuration = noteInterval * 4
        let frameCount = AVAudioFrameCount(totalDuration * sampleRate)

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return buffer }

        let frequencies = [c5Freq, e5Freq, c5Freq, e5Freq]
        let volumes: [Float] = [0.5, 0.4, 0.3, 0.2]

        // Fill with silence first
        for i in 0..<Int(frameCount) {
            data[i] = 0
        }

        for (noteIndex, freq) in frequencies.enumerated() {
            let startSample = Int(Double(noteIndex) * noteInterval * sampleRate)
            let noteSamples = Int(noteDuration * sampleRate)
            let volume = volumes[noteIndex]

            for i in 0..<noteSamples {
                let sampleIndex = startSample + i
                guard sampleIndex < Int(frameCount) else { break }

                let t = Double(i) / sampleRate
                let sine = sin(2.0 * .pi * freq * t)

                // Apply envelope: 10ms attack, 50ms release
                let attackSamples = Int(0.01 * sampleRate)
                let releaseSamples = Int(0.05 * sampleRate)
                var envelope: Double = 1.0

                if i < attackSamples {
                    envelope = Double(i) / Double(attackSamples)
                } else if i > noteSamples - releaseSamples {
                    envelope = Double(noteSamples - i) / Double(releaseSamples)
                }

                data[sampleIndex] = Float(sine * envelope) * volume
            }
        }

        return buffer
    }
}
