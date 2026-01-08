import SwiftUI
import Combine
import AVFoundation

struct SnakeGameView: View {
    let userId: String
    @Environment(\.presentationMode) var presentationMode
    
    // Game Constants
    let rows = 20
    let cols = 20
    let boxSize: CGFloat = 15
    let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    
    // Game State
    @State private var snake: [CGPoint] = [CGPoint(x: 10, y: 10)]
    @State private var food: CGPoint = CGPoint(x: 5, y: 5)
    @State private var direction: Direction = .right
    @State private var score: Int = 0
    @State private var isGameOver = false
    @State private var isPaused = false
    
    // Audio
    @State private var audioPlayer: AVAudioPlayer?
    
    enum Direction {
        case up, down, left, right
    }
    
    var body: some View {
        ZStack {
            Color(.mainGreen)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("McSnake")
                        .font(.custom("McDonaldsHelvetica", size: 30))
                        .foregroundColor(.mainYellow)
                        .bold()
                    Spacer()
                    Text("Score: \(score)")
                        .font(.custom("McDonaldsHelvetica", size: 20))
                        .foregroundColor(.white)
                }
                .padding()
                
                // Game Board
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.3))
                        .frame(width: CGFloat(cols) * boxSize, height: CGFloat(rows) * boxSize)
                        .overlay(
                            ZStack {
                                // Food (Burger)
                                Text("🍔")
                                    .font(.system(size: 12))
                                    .position(x: food.x * boxSize + boxSize/2, y: food.y * boxSize + boxSize/2)
                                
                                // Snake
                                ForEach(0..<snake.count, id: \.self) { index in
                                    Rectangle()
                                        .fill(index == 0 ? Color.mainYellow : Color.white)
                                        .frame(width: boxSize, height: boxSize)
                                        .position(x: snake[index].x * boxSize + boxSize/2, y: snake[index].y * boxSize + boxSize/2)
                                }
                            }
                        )
                }
                .frame(width: CGFloat(cols) * boxSize, height: CGFloat(rows) * boxSize)
                
                // Controls
                VStack(spacing: 20) {
                    Button(action: { changeDirection(.up) }) {
                        Image(systemName: "chevron.up.circle.fill")
                            .font(.system(size: 80)) // Larger Controls
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 50) {
                        Button(action: { changeDirection(.left) }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 80)) // Larger Controls
                                .foregroundColor(.white)
                        }
                        
                        Button(action: { changeDirection(.down) }) {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.system(size: 80)) // Larger Controls
                                .foregroundColor(.white)
                        }
                        
                        Button(action: { changeDirection(.right) }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 80)) // Larger Controls
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.top, 30)
                
                Spacer()
            }
            .blur(radius: isGameOver ? 5 : 0)
            
            // Game Over Overlay
            if isGameOver {
                VStack(spacing: 20) {
                    Text("GAME OVER")
                        .font(.custom("McDonaldsHelvetica", size: 40))
                        .foregroundColor(.red)
                        .bold()
                    
                    Text("Score final: \(score)")
                        .font(.custom("McDonaldsHelvetica", size: 24))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        resetGame()
                    }) {
                        Text("Rejouer")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.mainYellow)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Quitter")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .padding(40)
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
            }
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onReceive(timer) { _ in
            if !isGameOver && !isPaused {
                moveSnake()
            }
        }
    }
    
    func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "eat-sound", withExtension: "mp3") else {
            print("Impossible de trouver le fichier audio eat-sound.mp3")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Erreur audio: \(error)")
        }
    }
    
    func playEatSound() {
        if let player = audioPlayer {
             if player.isPlaying {
                 player.stop()
                 player.currentTime = 0
             }
             player.play()
        }
    }
    
    func moveSnake() {
        var newHead = snake[0]
        
        switch direction {
        case .up: newHead.y -= 1
        case .down: newHead.y += 1
        case .left: newHead.x -= 1
        case .right: newHead.x += 1
        }
        
        // Wall Collision
        if newHead.x < 0 || newHead.x >= CGFloat(cols) || newHead.y < 0 || newHead.y >= CGFloat(rows) {
            isGameOver = true
            return
        }
        
        // Self Collision
        if snake.contains(newHead) {
            isGameOver = true
            return
        }
        
        snake.insert(newHead, at: 0)
        
        // Eat Food
        if newHead == food {
            score += 10
            playEatSound() // Play Sound
            
            // Reward: 1 Point every 500 score
            if score > 0 && score % 500 == 0 {
                Task {
                    do {
                        // Assuming LoyaltyService is defined elsewhere or imported
                        _ = try await LoyaltyService.addPoints(userId: userId, points: 1)
                        print("1 point de fidélité gagné !")
                    } catch {
                        print("Erreur ajout points bonus: \(error)")
                    }
                }
            }
            
            generateFood()
        } else {
            snake.removeLast()
        }
    }
    
    func changeDirection(_ newDirection: Direction) {
        // Prevent 180 degree turns
        if (direction == .up && newDirection == .down) ||
           (direction == .down && newDirection == .up) ||
           (direction == .left && newDirection == .right) ||
           (direction == .right && newDirection == .left) {
            return
        }
        direction = newDirection
    }
    
    func generateFood() {
        var newFood: CGPoint
        repeat {
            newFood = CGPoint(x: Int.random(in: 0..<cols), y: Int.random(in: 0..<rows))
        } while snake.contains(newFood)
        food = newFood
    }
    
    func resetGame() {
        snake = [CGPoint(x: 10, y: 10)]
        direction = .right
        score = 0
        isGameOver = false
        generateFood()
    }
}

#Preview {
    SnakeGameView(userId: "preview")
}
