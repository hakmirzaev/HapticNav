//
//  Bar.swift
//  design_seekers
//
//  Created by Jimena Gallegos on 04/03/25.
//

import SwiftUI
import AVFoundation


struct Bar: View {
    @State private var isTorchOn = false
    var body: some View {
        ZStack {
            Color.black
            
            HStack(spacing: 56.0){
                
                ZStack {
                    Circle()
                        .fill(Color(hue: 1.0, saturation: 0.025, brightness: 0.644))
                        .frame(height: 70)

                    Image(systemName: "gearshape")
                        .foregroundStyle(.white)
                        .font(.system(size: 34))
                }

                
                ZStack {
                    Circle()
                        .fill(Color(hue: 1.0, saturation: 0.025, brightness: 0.644))
                        .frame(height: 70)

                    Image(systemName: "slider.vertical.3")
                        .foregroundStyle(.white)
                        .font(.system(size: 34))
                }
                
                Button(action: {
                            toggleTorch(on: !isTorchOn)
                }) {
                    
                    ZStack {
                        Circle()
                            .fill(Color(hue: 1.0, saturation: 0.025, brightness: 0.644))
                            .frame(height: 70)
                        
                        Image(systemName: "flashlight.on.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 34))
                    }
                }
                            
            }
        }
        .frame(height: 150)
    }
    
    func toggleTorch(on: Bool) {
            guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
            
            do {
                try device.lockForConfiguration()
                device.torchMode = on ? .on : .off
                device.unlockForConfiguration()
                isTorchOn = on
            } catch {
                print("Error al encender la linterna: \(error.localizedDescription)")
            }
        }
}

#Preview {
    Bar()
}
