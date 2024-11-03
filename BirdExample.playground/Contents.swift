class Bird {
    let name: String
}
class FlyableBird: Bird {
    func fly() {
        print("\(name) is flying!")
    }
}
class SwimmableBird: Bird {
    func swim() {
        print("\(name) is swimming!")
    }
}
class Penguin: SwimmableBird {
    func sliding() {
        print("\(name) is sliding!")
    }
}
class FlyableAndSwimmableBird: Bird {
    func ???() {
        // ???
    }
}



// Data - 純粹的 資料
struct BirdData {
    let name: String
}

// Roles (Interactions)
protocol Flyable {
    var name: String { get }
    func fly()
}

protocol Swimmable {
    var name: String { get }
    func swim()
}

// Concrete Interactions
extension BirdData: Flyable {
    func fly() {
        print("\(name) is flying!")
    }
}

extension BirdData: Swimmable {
    func swim() {
        print("\(name) is swimming!")
    }
}

// Context - 負責協調互動的場景
class BirdMovementContext {
    private var flyingBehavior: Flyable?
    private var swimmingBehavior: Swimmable?

    init(bird: BirdData) {
        if bird.name == "企鵝" {
            swimmingBehavior = bird
        } else if bird.name == "烏鴉" {
            flyingBehavior = bird
        } else if bird.name == "鴨子" {
            flyingBehavior = bird
            swimmingBehavior = bird
        }
    }

    func performTravel() {
        print("開始移動...")

        if let flying = flyingBehavior {
            print("嘗試飛行：")
            flying.fly()
        }

        if let swimming = swimmingBehavior {
            print("嘗試游泳：")
            swimming.swim()
        }

        if flyingBehavior == nil, swimmingBehavior == nil {
            print("這隻鳥既不會飛也不會游泳！")
        }

        print("移動結束\n")
    }
}

// 測試代碼
func testBirds() {
    let penguin = BirdData(name: "企鵝")
    let crow = BirdData(name: "烏鴉")
    let duck = BirdData(name: "鴨子")
    let ostrich = BirdData(name: "鴕鳥")

    print("=== 企鵝的移動 ===")
    let penguinContext = BirdMovementContext(bird: penguin)
    penguinContext.performTravel()

    print("=== 烏鴉的移動 ===")
    let crowContext = BirdMovementContext(bird: crow)
    crowContext.performTravel()

    print("=== 鴨子的移動 ===")
    let duckContext = BirdMovementContext(bird: duck)
    duckContext.performTravel()

    print("=== 鴕鳥的移動 ===")
    let ostrichContext = BirdMovementContext(bird: ostrich)
    ostrichContext.performTravel()
}

// 執行測試
testBirds()
