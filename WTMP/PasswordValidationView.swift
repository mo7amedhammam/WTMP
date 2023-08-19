//
//  PasswordValidationView.swift
//  WTMP
//
//  Created by wecancity on 19/08/2023.
//

import SwiftUI

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


struct PasswordValidationView: View {
    @Binding var isPasscodeSettingActive: Bool
    @Binding var enteredPasscode: String
    var stopMotionDetection: () -> Void // Closure to stop motion detection
    var stopSoundPlay: () -> Void // Closure to stop sound play

    @State private var showError: Bool = false // State to control error message visibility

    var body: some View {
        VStack{
            SecureField("Current Passcode", text: $enteredPasscode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Enter") {
                validatePasscode()
            }
            .padding()

            if showError {
                Text("Incorrect passcode. Please try again.")
                    .foregroundColor(.red)
            }
        }
    }

    private func validatePasscode() {
        if let savedPasscode = UserDefaults.standard.string(forKey: "passcode") {
            if enteredPasscode == savedPasscode {
                isPasscodeSettingActive = false
                stopMotionDetection() // Call the closure to stop motion detection
                stopSoundPlay()
            } else {
                showError = true // Set the state to show error message
            }
        }
    }
}
