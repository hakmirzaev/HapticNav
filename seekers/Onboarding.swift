//
//  Onboarding.swift
//  seekers
//
//  Created by Harnish Devani on 13/03/25.
//

import SwiftUI

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isOnboardingComplete = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                

                
                if isOnboardingComplete {
                    ContentView()
                } else {
                    VStack(spacing: 0) {
                        TabView(selection: $currentPage) {
                            OnboardingPageView(
                                title: "Welcome to HaptiRad",
                                subtitle: "Smart Indoor Navigation Assistant for Visually Impaired",
                                imageName: "welcome",
                                description: "Experience a new way to navigate indoor spaces with confidence and independence."
                            )
                            .tag(0)
                            
                            OnboardingPageView(
                                title: "Obstacle Detection",
                                subtitle: "Advanced Sensing Technology",
                                imageName: "obstacle",
                                description: "Real-time obstacle detection by levaraging your Device's camera and sensor helps you navigate safely through complex indoor environments."
                            )
                            .tag(1)
                            
                            OnboardingPageView(
                                title: "Audio Guidance",
                                subtitle: "Clear Voice Instructions",
                                imageName: "audio",
                                description: "Receive clear audio instructions for obstacles, and points of interest."
                            )
                            .tag(2)
                            
                            OnboardingPageView(
                                title: "Haptic Feedback",
                                subtitle: "Feel Your Way",
                                imageName: "haptics",
                                description: "Intuitive vibration patterns help you understand your surroundings without looking at your device."
                            )
                            .tag(3)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        
                        // Page indicators
                        HStack(spacing: 10) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.white : Color.gray.opacity(0.5))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Button
                        Button(action: {
                            if currentPage < 3 {
                                withAnimation {
                                    currentPage += 1
                                }
                            } else {
                                isOnboardingComplete = true
                            }
                        }) {
                            Text(currentPage < 3 ? "NEXT" : "TRY NOW")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(width: 280, height: 56)
                                .background(Color.white)
                                .cornerRadius(28)
                                .shadow(radius: 8)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal)
                }
            }
            .background(.orange.gradient)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    var title: String
    var subtitle: String
    var imageName: String
    var description: String
    
    var body: some View {
        VStack(spacing: 30) {
            Text(title)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 200)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .shadow(radius: 10)
            
            Text(description)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
            
        }
        .padding(.top, 60)
        Spacer()
    }
}




// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

