import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello from sePingMenu2!")
                .font(.headline)
                .padding()
            Text("Check your menu bar on the top-right for the ping results.")
                .padding()
        }
        .frame(width: 300, height: 200)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
