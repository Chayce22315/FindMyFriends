import Foundation
import UIKit
import Models
import Views
import Controllers

// MARK: - App Entry Point

@main
struct FindMyFriendsApp {
    
    static func main() {
        print("🚀 Starting FindMyFriends App...")
        
        // initialize app controller
        let appController = AppController()
        
        // start the main UI
        appController.start()
    }
}