//
//  ContentView.swift
//  WTMP
//
//  Created by wecancity on 11/08/2023.
//

import SwiftUI
import CoreMotion
import AVFoundation

struct ContentView: View {
    var body: some View {
        TabView {
            WTMPView()
                .tabItem {
                    Label("WTMP", systemImage: "thermometer.sun.fill")
                }
            
            DTMPView()
                .tabItem {
                    Label("DTMP", systemImage: "thermometer.snowflake")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct WTMPView: View {
    @State private var motionManager = CMMotionManager()
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isSoundPlaying = false
    @State private var isMotionDetectionActive = false
    @State private var isPasscodeSettingActive = false
    @State private var enteredPasscode = ""
    
    var body: some View {
        VStack {
            Text("WTMP")
                .font(.largeTitle)
            
            Spacer()
            
                Button(action: {
//                    if let savedPasscode = UserDefaults.standard.string(forKey: "passcode") {
                    print("savedPasscode",UserDefaults.standard.string(forKey: "passcode") ?? "0000")
                        if UserDefaults.standard.string(forKey: "passcode") == "" || UserDefaults.standard.string(forKey: "passcode") == nil{
                        
                        isPasscodeSettingActive = true
                    } else {
                        if !isSoundPlaying{
                            startMotionDetection()
                        }else{
                            isPasscodeSettingActive = true
                        }
                    }
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
        .sheet(isPresented: $isPasscodeSettingActive){
            PasswordValidationView(isPasscodeSettingActive: $isPasscodeSettingActive,
                                             enteredPasscode: $enteredPasscode,
                                   stopMotionDetection: stopMotionDetection, stopSoundPlay: {}) // Pass the closure here

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
          if motionManager.isAccelerometerAvailable {
              motionManager.accelerometerUpdateInterval = 0.2
              motionManager.startAccelerometerUpdates(to: .main) { accelerometerData, error in
                  if let acceleration = accelerometerData?.acceleration {
                      let magnitude = sqrt(acceleration.x * acceleration.x +
                                           acceleration.y * acceleration.y +
                                           acceleration.z * acceleration.z)
                      
                      let movementThreshold: Double = 1.2
                      
                      if magnitude > movementThreshold && !isSoundPlaying {
                          playAlarmSound()
                      }
                  }
              }
          }
          isMotionDetectionActive = true
           }
    
    private func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
        isMotionDetectionActive = false
        audioPlayer?.stop()
        isSoundPlaying = false
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
    
    private func getAlarmSoundURL() throws -> URL {
        guard let soundURL = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else {
            throw NSError(domain: "com.yourapp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Alarm sound file not found"])
        }
        return soundURL
    }
}

struct PasswordValidationView: View {
    @Binding var isPasscodeSettingActive: Bool
    @Binding var enteredPasscode: String
    var stopMotionDetection: () -> Void // Closure to stop motion detection
    var stopSoundPlay: () -> Void // Closure to stop motion detection

    var body: some View {
        VStack{
            SecureField("Current Passcode", text: $enteredPasscode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Enter") {
                validatePasscode()
            }
            .padding()
        }
    }
    // ... (existing functions)

    private func validatePasscode() {
        if let savedPasscode = UserDefaults.standard.string(forKey: "passcode") {
            if enteredPasscode == savedPasscode {
                isPasscodeSettingActive = false
                stopMotionDetection() // Call the closure to stop motion detection
                stopSoundPlay()
            } else {
                // Show error message or retry logic
            }
        }
    }
}


struct DTMPView: View {
    var body: some View {
        NavigationView {
            
            VStack {

                HStack (){
                    Spacer()
                    Text("DTMP")
                        .font(.largeTitle)
                    Spacer()
//                    .navigationBarItems(trailing:MusicButton())
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundColor(.black)

                }
                    

                Spacer()
                Button(action: {
                    // Action to perform when the "Start" button is tapped
                }) {
                    Text("Start")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                    
                }
                
            }
            .padding(.bottom)
        }
    }
}

struct MusicButton: View {
    var body: some View {
//        NavigationLink(destination: /* Your music view here */) {
            Image(systemName: "music.note")
                .font(.title)
                .foregroundColor(.black)
//        }
    }
}

struct SettingsView: View {
    @State private var isPasscodeEnabled = false
    @State private var isPresentingPasswordSetting = false
    @State private var passcode = ""
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
            
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.black)
                    .font(Font.system(size: 30))
                Text("Passcode")
                    .font(.title)
                    .bold()
                Spacer()
                Toggle("", isOn: $isPasscodeEnabled)
                    .padding(.trailing, 20)
                    .onChange(of: isPasscodeEnabled) { newValue in
                        if newValue {
                            isPresentingPasswordSetting = true
                        } else {
                            // Handle disabling passcode here if needed
                        }
                    }
            }
            .padding(.leading)
            Spacer()
        }
        .onAppear(){
            if UserDefaults.standard.string(forKey: "passcode") == "" || UserDefaults.standard.string(forKey: "passcode") == nil{
                isPasscodeEnabled = false
            }else{
                isPasscodeEnabled = true
            }
        }
        .sheet(isPresented: $isPresentingPasswordSetting) {
            PasswordSettingView(isPresented: $isPresentingPasswordSetting, passcode: $passcode)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
struct PasswordSettingView: View {
    @Binding var isPresented: Bool
    @Binding var passcode: String
    
    var body: some View {
        VStack {
            Text("Set Passcode")
                .font(.largeTitle)
            
            SecureField("Enter Passcode", text: $passcode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Save Passcode") {
                savePasscode()
            }
            .padding()
        }
        .padding()
    }
    
    private func savePasscode() {
        UserDefaults.standard.set(passcode, forKey: "passcode")
        isPresented = false
        print("saved password",passcode)
    }
}
