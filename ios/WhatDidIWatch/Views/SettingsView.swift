import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: SearchViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showUpgrade = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.039, green: 0.039, blue: 0.059).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        // Plan section
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Your Plan", systemImage: "crown.fill").font(.headline).foregroundColor(.white)
                            if vm.storeService.isPro {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.seal.fill").font(.title2).foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Pro — Unlimited").font(.body).fontWeight(.semibold).foregroundColor(.white)
                                        Text("Lifetime access active").font(.caption).foregroundColor(.green)
                                    }
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Free Plan").fontWeight(.semibold).foregroundColor(.white)
                                        Spacer()
                                        Text("\(vm.storeService.remainingFreeSearches)/\(StoreService.freeDailyLimit) searches left today").font(.caption).foregroundColor(Color(white: 0.6))
                                    }
                                    Button(action: { showUpgrade = true }) {
                                        Text("Upgrade to Pro").fontWeight(.semibold).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 12)
                                            .background(LinearGradient(colors: [Color(red: 0.545, green: 0.361, blue: 0.965), Color(red: 0.925, green: 0.286, blue: 0.6)], startPoint: .leading, endPoint: .trailing))
                                            .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(20).background(Color(red: 0.102, green: 0.102, blue: 0.149)).cornerRadius(16)

                        // About
                        VStack(alignment: .leading, spacing: 12) {
                            Label("About", systemImage: "info.circle.fill").font(.headline).foregroundColor(.white)
                            Text("What Did I Watch? uses Claude AI to identify movies, TV shows, cartoons, and anime from your vague descriptions.")
                                .font(.subheadline).foregroundColor(Color(white: 0.6)).lineSpacing(4)
                            Divider().background(Color(white: 0.15))
                            HStack { Text("Version").foregroundColor(Color(white: 0.6)); Spacer(); Text("1.0.0").foregroundColor(.white) }.font(.subheadline)
                        }
                        .padding(20).background(Color(red: 0.102, green: 0.102, blue: 0.149)).cornerRadius(16)

                        Button(action: { Task { await vm.storeService.restorePurchases() } }) {
                            Text("Restore Purchases").font(.subheadline).foregroundColor(Color(red: 0.655, green: 0.545, blue: 0.980))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { vm.saveSettings(); dismiss() }
                        .foregroundColor(Color(red: 0.655, green: 0.545, blue: 0.980))
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showUpgrade) {
            PaywallView()
                .environmentObject(vm)
        }
    }
}
