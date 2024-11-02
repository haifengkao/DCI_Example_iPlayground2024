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

#Preview {
    ContentView()
}


import SwiftUI

// MARK: - Data (Objects)
struct Combatant {
    let name: String
}

// MARK: - Repositories
class CombatStatsRepository {
    func getStats(for name: String) -> CombatStats {
        switch name {
        case "勇者":
            return CombatStats(maxHP: 100, currentHP: 100, attack: 25)
        case "魔王":
            return CombatStats(maxHP: 150, currentHP: 150, attack: 15)
        default:
            return CombatStats(maxHP: 100, currentHP: 100, attack: 10)
        }
    }
}

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

// MARK: - Value Types
struct CombatStats {
    var maxHP: Int
    var currentHP: Int
    var attack: Int
    
    var healthPercentage: Double {
        Double(currentHP) / Double(maxHP)
    }
    
    mutating func takeDamage(_ amount: Int) {
        currentHP = max(0, currentHP - amount)
    }
}

struct CombatantVisuals {
    var position: CGPoint
    var size: CGSize
    var color: Color
}

// MARK: - Roles (Interactions)
protocol Attacker {
    var attackStats: CombatStats { get }
    func attack(_ target: Defender)
}

protocol Defender {
    var defenseStats: CombatStats { get }
    func takeDamage(_ amount: Int)
    func updateStats(_ newStats: CombatStats)
}

// MARK: - Role Extensions
extension Combatant: Attacker {
    var attackStats: CombatStats {
        CombatStatsRepository().getStats(for: name)
    }
    
    func attack(_ target: Defender) {
        target.takeDamage(attackStats.attack)
    }
}

extension Combatant: Defender {
    var defenseStats: CombatStats {
        CombatStatsRepository().getStats(for: name)
    }
    
    func takeDamage(_ amount: Int) {
        var newStats = defenseStats
        newStats.takeDamage(amount)
        updateStats(newStats)
    }
    
    func updateStats(_ newStats: CombatStats) {
        // 在實際應用中，這裡應該要保存到某個持久化存儲
        // 現在我們通過 CombatContext 來管理狀態
    }
}

// MARK: - Context
class CombatContext: ObservableObject {
    private let statsRepo = CombatStatsRepository()
    
    @Published var playerStats: CombatStats
    @Published var enemyStats: CombatStats
    @Published var isAttacking: Bool = false
    @Published var gameOver: Bool = false
    
    let player: Combatant
    let enemy: Combatant
    
    init() {
        self.player = Combatant(name: "勇者")
        self.enemy = Combatant(name: "魔王")
        
        self.playerStats = statsRepo.getStats(for: player.name)
        self.enemyStats = statsRepo.getStats(for: enemy.name)
    }
    
    func performAttack() {
        // 使用 Role 來執行攻擊
        let attacker = player as Attacker
        var newEnemyStats = enemyStats
        newEnemyStats.takeDamage(attacker.attackStats.attack)
        enemyStats = newEnemyStats
        
        if enemyStats.currentHP <= 0 {
            gameOver = true
        }
    }
}

class VisualContext: ObservableObject {
    private let visualRepo = VisualRepository()
    
    @Published var playerVisuals: CombatantVisuals
    @Published var enemyVisuals: CombatantVisuals
    @Published var slashEffect = CombatEffect(position: CGPoint(x: 280, y: 200), isVisible: false)
    @Published var damageNumber = DamageNumber(amount: 0, position: CGPoint(x: 280, y: 150), isVisible: false)
    
    init(player: Combatant, enemy: Combatant) {
        self.playerVisuals = visualRepo.getVisuals(for: player.name)
        self.enemyVisuals = visualRepo.getVisuals(for: enemy.name)
    }
    
    func animateAttack(damage: Int) async {
        let originalPosition = playerVisuals.position
        
        withAnimation(.easeInOut(duration: 0.3)) {
            playerVisuals.position.x += 100
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
            playerVisuals.position = originalPosition
        }
    }
}

// MARK: - Views
struct CombatEffect {
    var position: CGPoint
    var isVisible: Bool
}

struct DamageNumber {
    var amount: Int
    var position: CGPoint
    var isVisible: Bool
}

struct HealthBarView: View {
    let character: Combatant
    let stats: CombatStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(character.name) HP: \(stats.currentHP)/\(stats.maxHP)")
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * stats.healthPercentage)
                }
            }
            .frame(height: 20)
            .cornerRadius(10)
        }
        .frame(width: 150)
    }
}

struct CombatView: View {
    @StateObject private var combatContext = CombatContext()
    @StateObject private var visualContext: VisualContext
    
    init() {
        let combat = CombatContext()
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
                                stats: combatContext.playerStats)
                    Spacer()
                    HealthBarView(character: combatContext.enemy, 
                                stats: combatContext.enemyStats)
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
                    await visualContext.animateAttack(damage: combatContext.playerStats.attack)
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

struct CombatView_Previews: PreviewProvider {
    static var previews: some View {
        CombatView()
    }
}
