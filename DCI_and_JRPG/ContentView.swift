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
    @Published var playerHP: (current: Int, max: Int)
    @Published var enemyHP: (current: Int, max: Int)
    @Published var isAttacking: Bool = false
    @Published var gameOver: Bool = false

    // 戰鬥數值
    private let playerAttackPower: Int
    private let enemyAttackPower: Int

    // 原始數據
    let player: Combatant
    let enemy: Combatant

    // Role assignments
    private var playerAsAttacker: Attacker?
    private var enemyAsDefender: Defender?

    init(attackerName: String, defenderName: String) {
        player = Combatant(name: attackerName)
        enemy = Combatant(name: defenderName)

        // 從 Repository 獲取初始數據
        let playerStats = statsRepo.getInitialStats(for: player.name)
        let enemyStats = statsRepo.getInitialStats(for: enemy.name)

        playerHP = playerStats.hp
        enemyHP = enemyStats.hp
        playerAttackPower = playerStats.attackPower
        enemyAttackPower = enemyStats.attackPower

        playerAsAttacker = player as Attacker

        enemyAsDefender = enemy as Defender

        CombatContext.current = self
    }

    deinit {
        if CombatContext.current === self {
            CombatContext.current = nil
        }
    }

    func performAttack() {
        guard let attacker = playerAsAttacker,
              let defender = enemyAsDefender
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
        case player.name: return playerAttackPower
        case enemy.name: return enemyAttackPower
        default: return 0
        }
    }

    fileprivate func getCurrentHP(for name: String) -> (current: Int, max: Int) {
        switch name {
        case player.name: return playerHP
        case enemy.name: return enemyHP
        default: return (0, 0)
        }
    }

    fileprivate func applyDamage(_ amount: Int, to name: String) {
        switch name {
        case player.name:
            playerHP.current = max(0, playerHP.current - amount)
        case enemy.name:
            enemyHP.current = max(0, enemyHP.current - amount)
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
            player: combat.player,
            enemy: combat.enemy
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
                    HealthBarView(character: combatContext.player,
                                  hp: combatContext.playerHP)
                    Spacer()
                    HealthBarView(character: combatContext.enemy,
                                  hp: combatContext.enemyHP)
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
                        damage: combatContext.getAttackPower(for: combatContext.player.name)
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
