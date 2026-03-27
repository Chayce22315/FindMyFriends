import SwiftUI

struct ContentView: View {
    @State private var friends = [
        Friend(name: "Alice", location: "Home"),
        Friend(name: "Bob", location: "School")
    ]
    
    var body: some View {
        NavigationView {
            List(friends, id: \.name) { friend in
                HStack {
                    Text(friend.name)
                        .font(.headline)
                    Spacer()
                    Text(friend.location)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("FindMyFriends")
        }
    }
}