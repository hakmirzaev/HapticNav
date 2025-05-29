//
//  Buttons.swift
//  design_seekers
//
//  Created by Jimena Gallegos on 04/03/25.
//

import SwiftUI


struct Buttons: View {
    @State private var isAudioEnabled = true
    @State private var isHapticEnabled = true
    @State private var isEnglishLanguage = true
    
    @ObservedObject var obstacleManager: ObstacleDetectionManager
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 20.0) {
                Button(action: {
                    isAudioEnabled.toggle()
                    obstacleManager.isAudioEnabled = isAudioEnabled
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.6))
                            .frame(height: 50)

                        Image(systemName: isAudioEnabled ? "speaker" : "speaker.slash")
                            .foregroundStyle(.black)
                            .font(.system(size: 25))
                    }
                }
                
                Button(action: {
                    isHapticEnabled.toggle()
                    obstacleManager.isHapticEnabled = isHapticEnabled // Cambiar estado de los hápticos
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.6))
                            .frame(height: 50)

                        Image(systemName: isHapticEnabled ? "waveform" : "waveform.slash")
                            .foregroundStyle(.black)
                            .font(.system(size: 25))
                    }
                }
                
                Button(action: {
                    isEnglishLanguage.toggle()
                    obstacleManager.audioEngine.voiceLanguage = isEnglishLanguage ? "en-US" : "uz-UZ"
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.6))
                            .frame(height: 50)
                        Text(isEnglishLanguage ? "EN" : "UZ")
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight: .bold))
                    }
                }
            }
            .padding()
        }
    }
}
