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

// MARK: - Roles (Interactions)
protocol Attacker {
    var name: String { get }
    func attack(_ target: Defender)
}

extension Attacker {
    func attack(_ target: Defender) {
        guard let context = CombatContext.current else { return }
        let damage = context.getAttackPower(for: name)
        target.takeDamage(damage)
    }
}

protocol Defender {
    var name: String { get }
    func takeDamage(_ amount: Int)
}

extension Defender {
    
    func takeDamage(_ amount: Int) {
        guard let context = CombatContext.current else { return }
        context.applyDamage(amount, to: name)
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
        self.playerVisuals = visualRepo.getVisuals(for: player.name)
        self.enemyVisuals = visualRepo.getVisuals(for: enemy.name)
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

// MARK: - Context
class CombatContext: ObservableObject {
    static private(set) var current: CombatContext?
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
    
    init() {
        self.player = Combatant(name: "勇者")
        self.enemy = Combatant(name: "魔王")
        
        // 從 Repository 獲取初始數據
        let playerStats = statsRepo.getInitialStats(for: player.name)
        let enemyStats = statsRepo.getInitialStats(for: enemy.name)
        
        self.playerHP = playerStats.hp
        self.enemyHP = enemyStats.hp
        self.playerAttackPower = playerStats.attackPower
        self.enemyAttackPower = enemyStats.attackPower
        
        playerAsAttacker =  player as Attacker
  
        enemyAsDefender = enemy  as Defender
        
        
        CombatContext.current = self
    }
    
    deinit {
        if CombatContext.current === self {
            CombatContext.current = nil
        }
    }
    
    
    func performAttack() {
        guard let attacker = playerAsAttacker,
              let defender = enemyAsDefender else {
            return
        }
        
        attacker.attack(defender)
        
        if enemyHP.current <= 0 {
            gameOver = true
        }
    }
    
    // Context methods for roles to access data
    func getAttackPower(for name: String) -> Int {
        switch name {
        case player.name: return playerAttackPower
        case enemy.name: return enemyAttackPower
        default: return 0
        }
    }
    
    func getCurrentHP(for name: String) -> (current: Int, max: Int) {
        switch name {
        case player.name: return playerHP
        case enemy.name: return enemyHP
        default: return (0, 0)
        }
    }
    
    func applyDamage(_ amount: Int, to name: String) {
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

struct CombatView_Previews: PreviewProvider {
    static var previews: some View {
        CombatView()
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
