import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var vm: SearchViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.059).ignoresSafeArea()
            Circle().fill(Color.purple).frame(width: 300, height: 300).blur(radius: 80).opacity(0.15).offset(x: 100, y: -200)
            Circle().fill(Color.pink).frame(width: 250, height: 250).blur(radius: 80).opacity(0.12).offset(x: -80, y: 200)

            ScrollView {
                VStack(spacing: 32) {
                    HStack { Spacer(); Button(action: { dismiss() }) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(Color(white: 0.4)) } }

                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80).shadow(color: .purple.opacity(0.4), radius: 20)
                            Text("🎬").font(.system(size: 40))
                        }
                        Text("Unlock Pro").font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                        Text("Unlimited searches. Every language.\nFind any movie or show, anytime.")
                            .font(.body).foregroundColor(Color(white: 0.6)).multilineTextAlignment(.center)
                    }

                    VStack(spacing: 16) {
                        FeatureRow(icon: "infinity", color: .purple, title: "Unlimited Searches", sub: "No daily limit")
                        FeatureRow(icon: "globe", color: .pink, title: "20 Languages", sub: "Describe in any language")
                        FeatureRow(icon: "mic.fill", color: .orange, title: "Voice Search", sub: "Just speak what you remember")
                        FeatureRow(icon: "sparkles", color: .yellow, title: "AI-Powered", sub: "Claude AI understands vague descriptions")
                    }
                    .padding(20).background(Color(red: 0.071, green: 0.071, blue: 0.102)).cornerRadius(20)

                    VStack(spacing: 16) {
                        if let product = vm.storeService.products.first {
                            Text("One-time purchase").font(.caption).foregroundColor(Color(white: 0.6))
                            Text(product.displayPrice).font(.system(size: 42, weight: .bold, design: .rounded)).foregroundColor(.white)
                            Text("Pay once, search forever").font(.caption).foregroundColor(Color(white: 0.4))

                            Button(action: { Task { await vm.storeService.purchasePro() } }) {
                                HStack {
                                    if vm.storeService.isLoading { ProgressView().tint(.white) }
                                    else { Text("Get Pro — \(product.displayPrice)").fontWeight(.bold) }
                                }
                                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(16).shadow(color: .purple.opacity(0.3), radius: 12)
                            }
                            .buttonStyle(.plain)
                            .disabled(vm.storeService.isLoading)
                        } else {
                            ProgressView().tint(.white).padding(.vertical, 20)
                            Text("Loading products...").font(.caption).foregroundColor(Color(white: 0.4))
                        }

                        if let err = vm.storeService.errorMessage {
                            Text(err).font(.caption).foregroundColor(.red).multilineTextAlignment(.center)
                        }

                        Button(action: { Task { await vm.storeService.restorePurchases() } }) {
                            Text("Restore Purchases").font(.subheadline).foregroundColor(Color(red: 0.655, green: 0.545, blue: 0.980))
                        }

                        Text("Free tier: \(StoreService.freeDailyLimit) searches per day")
                            .font(.caption2).foregroundColor(Color(white: 0.4))
                    }
                    Spacer(minLength: 40)
                }
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct FeatureRow: View {
    let icon: String; let color: Color; let title: String; let sub: String
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: icon).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                Text(sub).font(.caption).foregroundColor(Color(white: 0.6))
            }
            Spacer()
        }
    }
}
