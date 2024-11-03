//
//  SmallView.swift
//  DCI_and_JRPG
//
//  Created by Lono on 2024/11/3.
//

import SwiftUI

// MARK: - Visual Components

struct SlashEffect: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: -30, y: -30))
            path.addLine(to: CGPoint(x: 30, y: 30))
            path.move(to: CGPoint(x: 30, y: -30))
            path.addLine(to: CGPoint(x: -30, y: 30))
        }
        .stroke(Color.white, lineWidth: 4)
        .rotationEffect(.degrees(45))
    }
}

struct HealthBarView: View {
    let character: Combatant
    let hp: (current: Int, max: Int)

    var healthPercentage: Double {
        Double(hp.current) / Double(hp.max)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(character.name) HP: \(hp.current)/\(hp.max)")
                .foregroundColor(.white)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))

                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * healthPercentage)
                }
            }
            .frame(height: 20)
            .cornerRadius(10)
        }
        .frame(width: 150)
    }
}
