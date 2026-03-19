import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        SearchView()
            .environmentObject(viewModel)
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView()
                    .environmentObject(viewModel)
            }
    }
}
