//
//  SettingsView.swift
//  WTMP
//
//  Created by wecancity on 19/08/2023.
//

import SwiftUI

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
                                if UserDefaults.standard.string(forKey: "passcode") == "" || UserDefaults.standard.string(forKey: "passcode") == nil{

                                isPresentingPasswordSetting = true
                            } else {
                                // Handle disabling passcode here if needed
                            }
                            }else{
                                UserDefaults.standard.removeObject (forKey: "passcode")
                                UserDefaults.standard.synchronize()

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
