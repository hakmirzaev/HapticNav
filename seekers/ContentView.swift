//
//  ContentView.swift
//  design_seekers
//
//  Created by Jimena Gallegos on 04/03/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var obstacleManager = ObstacleDetectionManager()
    
    var body: some View {
        ZStack {
            DistanceView(obstacleManager: obstacleManager)
            
            VStack {
                Spacer()
                Buttons(obstacleManager: obstacleManager)
                Spacer()
                Bar()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}

