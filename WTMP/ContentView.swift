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

struct MusicButton: View {
    var body: some View {
        Image(systemName: "music.note")
            .font(.title)
            .foregroundColor(.black)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
