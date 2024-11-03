//
//  ContentView.swift
//  DCI_and_JRPG
//
//  Created by Lono on 2024/11/2.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            CombatView()
        }
        .padding()
    }
}

// MARK: - Data (Objects)

struct Combatant {
    let name: String
}

// MARK: - Roles (Interactions)

protocol Attacker {
    var name: String { get }
}

extension Attacker {
    func attack(_ target: Defender) {
        target.takeDamage(attackPower)
    }
    
    private var attackPower: Int {
        guard let context = CombatContext.current else { return 0 }
        return context.getAttackPower(for: name)
    }
}

protocol Defender {
    var name: String { get }
}

extension Defender {
    func takeDamage(_ amount: Int) {
        guard let context = CombatContext.current else { return }
       
        applyDamage(amount)

        // 如果自己死了，通知 context
        if isDead {
            context.notifyDefenderDied()
        }
    }

   
    private func applyDamage(_ amount: Int) {
        guard let context = CombatContext.current else { return }
        context.applyDamage(amount, to: name)
    }
    
    var isDead: Bool {
        guard let context = CombatContext.current else { return false }
        let hp = context.getCurrentHP(for: name)
        return hp.current <= 0
    }
}

extension Combatant: Attacker, Defender {}

// MARK: - Repositories

class CombatStatsRepository {
    func getInitialStats(for name: String) -> (hp: (current: Int, max: Int), attackPower: Int) {
        switch name {
        case "勇者":
            return ((current: 100, max: 100), attackPower: 25)
        case "魔王":
            return ((current: 150, max: 150), attackPower: 15)
        default:
            return ((current: 100, max: 100), attackPower: 10)
        }
    }
}

// MARK: - Context

class CombatContext: ObservableObject {
    private(set) static var current: CombatContext?
    private let statsRepo = CombatStatsRepository()

    // 戰鬥狀態
    @Published var attackerHP: (current: Int, max: Int)
    @Published var defenderHP: (current: Int, max: Int)
    @Published var isAttacking: Bool = false
    @Published var gameOver: Bool = false

    // 戰鬥數值
    private let attackerAttackPower: Int
    private let defenderAttackPower: Int

    // 原始數據
    let attacker: Combatant
    let defender: Combatant

    // Role assignments
    private var attackerRole: Attacker?
    private var defenderRole: Defender?

    init(attackerName: String, defenderName: String) {
        attacker = Combatant(name: attackerName)
        defender = Combatant(name: defenderName)

        // 從 Repository 獲取初始數據
        let attackerStats = statsRepo.getInitialStats(for: attacker.name)
        let defenderStats = statsRepo.getInitialStats(for: defender.name)

        attackerHP = attackerStats.hp
        defenderHP = defenderStats.hp
        attackerAttackPower = attackerStats.attackPower
        defenderAttackPower = defenderStats.attackPower

        attackerRole = attacker as Attacker
        defenderRole = defender as Defender

        CombatContext.current = self
    }

    deinit {
        if CombatContext.current === self {
            CombatContext.current = nil
        }
    }

    func performAttack() {
        guard let attacker = attackerRole,
              let defender = defenderRole
        else {
            return
        }

        attacker.attack(defender)
    }

    fileprivate func notifyDefenderDied() {
        gameOver = true
    }

    // Context methods for roles to access data
    fileprivate func getAttackPower(for name: String) -> Int {
        switch name {
        case attacker.name: return attackerAttackPower
        case defender.name: return defenderAttackPower
        default: return 0
        }
    }

    fileprivate func getCurrentHP(for name: String) -> (current: Int, max: Int) {
        switch name {
        case attacker.name: return attackerHP
        case defender.name: return defenderHP
        default: return (0, 0)
        }
    }

    fileprivate func applyDamage(_ amount: Int, to name: String) {
        switch name {
        case attacker.name:
            attackerHP.current = max(0, attackerHP.current - amount)
        case defender.name:
            defenderHP.current = max(0, defenderHP.current - amount)
        default:
            break
        }
    }
}

// MARK: - Views

struct CombatView: View {
    @StateObject private var combatContext = CombatContext(attackerName: "勇者", defenderName: "魔王")
    @StateObject private var visualContext: VisualContext

    init() {
        let combat = CombatContext(attackerName: "勇者", defenderName: "魔王")
        _combatContext = StateObject(wrappedValue: combat)
        _visualContext = StateObject(wrappedValue: VisualContext(
            player: combat.attacker,
            enemy: combat.defender
        ))
    }

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            VStack {
                // Health bars
                HStack {
                    HealthBarView(character: combatContext.attacker,
                                  hp: combatContext.attackerHP)
                    Spacer()
                    HealthBarView(character: combatContext.defender,
                                  hp: combatContext.defenderHP)
                }
                .padding()

                Spacer()
            }

            // Enemy
            Circle()
                .fill(visualContext.enemyVisuals.color)
                .frame(width: visualContext.enemyVisuals.size.width,
                       height: visualContext.enemyVisuals.size.height)
                .position(visualContext.enemyVisuals.position)

            // Player
            Rectangle()
                .fill(visualContext.playerVisuals.color)
                .frame(width: visualContext.playerVisuals.size.width,
                       height: visualContext.playerVisuals.size.height)
                .position(visualContext.playerVisuals.position)

            // Slash effect
            if visualContext.slashEffect.isVisible {
                SlashEffect()
                    .position(visualContext.slashEffect.position)
                    .transition(.opacity)
            }

            // Damage number
            if visualContext.damageNumber.isVisible {
                Text("-\(visualContext.damageNumber.amount)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .position(visualContext.damageNumber.position)
            }

            // Attack button
            Button("攻擊") {
                Task {
                    combatContext.isAttacking = true
                    await visualContext.animateAttack(
                        damage: combatContext.getAttackPower(for: combatContext.attacker.name)
                    )
                    combatContext.performAttack()
                    combatContext.isAttacking = false
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.gray)
            .cornerRadius(10)
            .position(x: 200, y: 400)
            .disabled(combatContext.isAttacking || combatContext.gameOver)

            // Game over overlay
            if combatContext.gameOver {
                Text("戰鬥勝利！")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(10)
            }
        }
    }
}

#Preview {
    ContentView()
}
