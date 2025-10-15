import SwiftUI
import Foundation

struct AudioWaveformView: View {
    @Binding var audioSamples: [Float]
    @State private var animationOffset: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    private let maxBars = 10
    private let barWidth: CGFloat = 3.5
    private let barSpacing: CGFloat = 2.5
    private let maxHeight: CGFloat = 10
    private let minHeight: CGFloat = 3
    
    var body: some View {
        HStack(alignment: .center, spacing: barSpacing) {
            ForEach(0..<maxBars, id: \.self) { index in
                WaveformBar(
                    height: barHeight(for: index),
                    maxHeight: maxHeight,
                    index: index,
                    totalBars: maxBars,
                    colorScheme: colorScheme
                )
                .frame(width: barWidth)
            }
        }
        .frame(height: maxHeight)
        .padding(.bottom, 1)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        guard !audioSamples.isEmpty else { return minHeight }
        
        let sampleIndex = Int(Double(index) / Double(maxBars) * Double(audioSamples.count))
        guard sampleIndex < audioSamples.count else { return minHeight }
        
        let sample = abs(audioSamples[sampleIndex])
        
        let smoothedSample: Float
        if sampleIndex > 0 && sampleIndex < audioSamples.count - 1 {
            smoothedSample = (audioSamples[sampleIndex - 1] + sample + audioSamples[sampleIndex + 1]) / 3.0
        } else {
            smoothedSample = sample
        }
        
        let normalizedHeight = min(abs(smoothedSample) * 15.0, 1.0)
        let calculatedHeight = CGFloat(normalizedHeight) * maxHeight
        
        return max(calculatedHeight, minHeight)
    }
}

struct WaveformBar: View {
    let height: CGFloat
    let maxHeight: CGFloat
    let index: Int
    let totalBars: Int
    let colorScheme: ColorScheme
    
    @State private var animatedHeight: CGFloat = 3
    
    private var barColor: LinearGradient {
        let baseColor = Color(hex: "1CA485")
        let intensity = height / maxHeight
        
        let topColor = baseColor.opacity(0.6 + Double(intensity) * 0.4)
        let bottomColor = baseColor
        
        return LinearGradient(
            gradient: Gradient(colors: [topColor, bottomColor]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(barColor)
            .frame(height: animatedHeight)
            .shadow(color: Color(hex: "1CA485").opacity(0.3), radius: 2, x: 0, y: 1)
            .onChange(of: height) { oldValue, newValue in
                withAnimation(.spring(response: 0.15, dampingFraction: 0.7, blendDuration: 0)) {
                    animatedHeight = newValue
                }
            }
            .onAppear {
                animatedHeight = height
            }
    }
}

struct EnergyValue {
    let index: Int
    let value: Float
}

struct AudioWaveformView_Previews: PreviewProvider {
    static var previews: some View {
        AudioWaveformView(audioSamples: .constant([0.1, 0.3, 0.5, 0.2, 0.8, 0.4, 0.6, 0.3]))
            .frame(height: 30)
    }
}
