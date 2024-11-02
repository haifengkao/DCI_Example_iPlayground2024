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
    var position: CGPoint
    var size: CGSize
    var color: Color
    var maxHP: Int
    var currentHP: Int
    var attack: Int
    var name: String
    
    var healthPercentage: Double {
        Double(currentHP) / Double(maxHP)
    }
    
    mutating func takeDamage(_ amount: Int) {
        currentHP = max(0, currentHP - amount)
    }
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

// MARK: - Roles (Interactions)
protocol Attacker {
    func attack(target: CGPoint) async
}

protocol CombatAnimatable {
    var position: CGPoint { get set }
    mutating func moveForward(by offset: CGFloat)
    mutating func moveBack(to originalPosition: CGPoint)
}

protocol Damageable {
    var currentHP: Int { get set }
    var maxHP: Int { get }
    mutating func takeDamage(_ amount: Int)
}

// MARK: - Context (Use Cases)
class CombatContext: ObservableObject {
    @Published var player: Combatant
    @Published var enemy: Combatant
    @Published var slashEffect: CombatEffect
    @Published var damageNumber: DamageNumber
    @Published var isAttacking: Bool = false
    @Published var gameOver: Bool = false
    
    init() {
        self.player = Combatant(
            position: CGPoint(x: 100, y: 200),
            size: CGSize(width: 50, height: 80),
            color: .blue,
            maxHP: 100,
            currentHP: 100,
            attack: 25,
            name: "勇者"
        )
        
        self.enemy = Combatant(
            position: CGPoint(x: 280, y: 200),
            size: CGSize(width: 60, height: 60),
            color: .red,
            maxHP: 150,
            currentHP: 150,
            attack: 15,
            name: "魔王"
        )
        
        self.slashEffect = CombatEffect(
            position: CGPoint(x: 280, y: 200),
            isVisible: false
        )
        
        self.damageNumber = DamageNumber(
            amount: 0,
            position: CGPoint(x: 280, y: 150),
            isVisible: false
        )
    }
}

// MARK: - Role Extensions
extension Combatant: CombatAnimatable {

    
    mutating func moveForward(by offset: CGFloat) {
        position.x += offset
    }
    
    mutating func moveBack(to originalPosition: CGPoint) {
        position = originalPosition
    }
}

extension CombatContext: Attacker {
    func attack(target: CGPoint) async {
        let originalPosition = player.position
        
        // Move forward
        withAnimation(.easeInOut(duration: 0.3)) {
            isAttacking = true
            player.moveForward(by: 100)
        }
        
        // Show slash effect
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.easeIn(duration: 0.2)) {
            slashEffect.isVisible = true
            enemy.takeDamage(player.attack)
            damageNumber.amount = player.attack
            damageNumber.isVisible = true
        }
        
        // Hide effects and return
        try? await Task.sleep(nanoseconds: 500_000_000)
        withAnimation(.easeOut(duration: 0.2)) {
            slashEffect.isVisible = false
            damageNumber.isVisible = false
            player.moveBack(to: originalPosition)
            isAttacking = false
        }
        
        // Check if enemy is defeated
        if enemy.currentHP <= 0 {
            gameOver = true
        }
    }
}

// MARK: - Views
struct HealthBarView: View {
    let character: Combatant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(character.name) HP: \(character.currentHP)/\(character.maxHP)")
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * character.healthPercentage)
                }
            }
            .frame(height: 20)
            .cornerRadius(10)
        }
        .frame(width: 150)
    }
}

struct CombatView: View {
    @StateObject private var context = CombatContext()
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // Health bars
                HStack {
                    HealthBarView(character: context.player)
                    Spacer()
                    HealthBarView(character: context.enemy)
                }
                .padding()
                
                Spacer()
            }
            
            // Enemy
            Circle()
                .fill(context.enemy.color)
                .frame(width: context.enemy.size.width,
                       height: context.enemy.size.height)
                .position(context.enemy.position)
            
            // Player
            Rectangle()
                .fill(context.player.color)
                .frame(width: context.player.size.width,
                       height: context.player.size.height)
                .position(context.player.position)
            
            // Slash effect
            if context.slashEffect.isVisible {
                SlashEffect()
                    .position(context.slashEffect.position)
                    .transition(.opacity)
            }
            
            // Damage number
            if context.damageNumber.isVisible {
                Text("-\(context.damageNumber.amount)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .position(context.damageNumber.position)
            }
            
            // Attack button
            Button("攻擊") {
                Task {
                    await context.attack(target: context.enemy.position)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.gray)
            .cornerRadius(10)
            .position(x: 200, y: 400)
            .disabled(context.isAttacking || context.gameOver)
            
            // Game over overlay
            if context.gameOver {
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
