//
//  VisualContext.swift
//  DCI_and_JRPG
//
//  Created by Lono on 2024/11/3.
//

import SwiftUI

// MARK: - Visual Types

struct CombatantVisuals {
    let position: CGPoint
    let size: CGSize
    let color: Color
}

struct CombatEffect {
    var position: CGPoint
    var isVisible: Bool
}

struct DamageNumber {
    var amount: Int
    var position: CGPoint
    var isVisible: Bool
}


// MARK: - Visual Context

class VisualContext: ObservableObject {
    private let visualRepo = VisualRepository()

    @Published var playerVisuals: CombatantVisuals
    @Published var enemyVisuals: CombatantVisuals
    @Published var slashEffect = CombatEffect(position: CGPoint(x: 280, y: 200), isVisible: false)
    @Published var damageNumber = DamageNumber(amount: 0, position: CGPoint(x: 280, y: 150), isVisible: false)

    init(player: Combatant, enemy: Combatant) {
        playerVisuals = visualRepo.getVisuals(for: player.name)
        enemyVisuals = visualRepo.getVisuals(for: enemy.name)
    }

    func animateAttack(damage: Int) async {
        let originalPosition = playerVisuals.position

        withAnimation(.easeInOut(duration: 0.3)) {
            // 因為 playerVisuals 是 let，我們需要創建一個新的實例
            playerVisuals = CombatantVisuals(
                position: CGPoint(x: playerVisuals.position.x + 100, y: playerVisuals.position.y),
                size: playerVisuals.size,
                color: playerVisuals.color
            )
        }

        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.easeIn(duration: 0.2)) {
            slashEffect.isVisible = true
            damageNumber.amount = damage
            damageNumber.isVisible = true
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        withAnimation(.easeOut(duration: 0.2)) {
            slashEffect.isVisible = false
            damageNumber.isVisible = false
            playerVisuals = CombatantVisuals(
                position: originalPosition,
                size: playerVisuals.size,
                color: playerVisuals.color
            )
        }
    }
}

// MARK: - Visual Repository

class VisualRepository {
    func getVisuals(for name: String) -> CombatantVisuals {
        switch name {
        case "勇者":
            return CombatantVisuals(
                position: CGPoint(x: 100, y: 200),
                size: CGSize(width: 50, height: 80),
                color: .blue
            )
        case "魔王":
            return CombatantVisuals(
                position: CGPoint(x: 280, y: 200),
                size: CGSize(width: 60, height: 60),
                color: .red
            )
        default:
            return CombatantVisuals(
                position: .zero,
                size: CGSize(width: 50, height: 50),
                color: .gray
            )
        }
    }
}
