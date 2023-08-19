//
//  WTMPView.swift
//  WTMP
//
//  Created by wecancity on 19/08/2023.
//

import SwiftUI
import AVFoundation
import CoreMotion

struct WTMPView: View {
    @State private var motionManager = CMMotionManager()
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isSoundPlaying = false
    @State private var isMotionDetectionActive = false
    @State private var isPasscodeSettingActive = false
    @State private var enteredPasscode = ""
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    var body: some View {
        VStack {
            Text("WTMP")
                .font(.largeTitle)
            
            Spacer()
            
            Button(action: {
                handlePlayStopButtonTap()
            }) {
                Text(isMotionDetectionActive ? "Stop" : "Play")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isMotionDetectionActive ? Color.red : Color.green)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.bottom)
        .onAppear {
            configureAudioSession()
            configureMotionDetection()
        }
        .onDisappear {
            deactivateAudioSession()
            stopMotionDetection()
        }
        .sheet(isPresented: $isPasscodeSettingActive) {
            PasswordValidationView(
                isPasscodeSettingActive: $isPasscodeSettingActive,
                enteredPasscode: $enteredPasscode,
                stopMotionDetection: stopMotionDetection,
                stopSoundPlay: stopSoundPlay)
        }
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error configuring audio session: \(error.localizedDescription)")
        }
    }
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error.localizedDescription)")
        }
    }
    
    private func configureMotionDetection() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.2
            motionManager.startAccelerometerUpdates(to: .main) { accelerometerData, error in
                if let acceleration = accelerometerData?.acceleration {
                    let magnitude = sqrt(acceleration.x * acceleration.x +
                                         acceleration.y * acceleration.y +
                                         acceleration.z * acceleration.z)
                    
                    let movementThreshold: Double = 1.2
                    
                    if magnitude > movementThreshold && !isSoundPlaying && isMotionDetectionActive {
                        playAlarmSound()
                    }
                }
            }
        }
    }
    
    private func handlePlayStopButtonTap() {
        if let savedPasscode = UserDefaults.standard.string(forKey: "passcode"), !savedPasscode.isEmpty {
            if !isSoundPlaying {
                toggleMotionDetection()
            } else {
                isPasscodeSettingActive = true
            }
        } else {
            isPasscodeSettingActive = true
        }
    }
    
    private func toggleMotionDetection() {
        if isMotionDetectionActive {
            stopMotionDetection()
        } else {
            startMotionDetection()
        }
    }
    
    private func startMotionDetection() {
        isMotionDetectionActive = true
        backgroundTask = UIApplication.shared.beginBackgroundTask { [self] in
            self.endBackgroundTask()
        }
    }
    
    private func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
        isMotionDetectionActive = false
        audioPlayer?.stop()
        isSoundPlaying = false
        endBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func playAlarmSound() {
        isSoundPlaying = true
        do {
            let soundURL = try getAlarmSoundURL()
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("Sound is playing")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0.0)) {
                print("Sound is stopped")
                isSoundPlaying = false
            }
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
    
    private func stopSoundPlay() {
        audioPlayer?.stop()
        isSoundPlaying = false
    }
    
    private func getAlarmSoundURL() throws -> URL {
        guard let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else {
            throw NSError(domain: "com.yourapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Alarm sound file not found"])
        }
        return soundURL
    }
}
