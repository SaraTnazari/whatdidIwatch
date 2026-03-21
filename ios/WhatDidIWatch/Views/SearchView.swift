import SwiftUI

struct SearchView: View {
    @EnvironmentObject var vm: SearchViewModel
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.039, green: 0.039, blue: 0.059).ignoresSafeArea()
                    .onTapGesture { isTextEditorFocused = false }

                Circle()
                    .fill(Color(red: 0.545, green: 0.361, blue: 0.965))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80).opacity(0.12)
                    .offset(x: 150, y: -300)

                Circle()
                    .fill(Color(red: 0.925, green: 0.286, blue: 0.6))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80).opacity(0.10)
                    .offset(x: -100, y: 400)

                ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(colors: [Color(red: 0.545, green: 0.361, blue: 0.965), Color(red: 0.925, green: 0.286, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 56, height: 56)
                                    .shadow(color: Color.purple.opacity(0.3), radius: 16)
                                Text("🎬").font(.system(size: 28))
                            }
                            Text("What Did I Watch?")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(LinearGradient(colors: [Color(red: 0.545, green: 0.361, blue: 0.965), Color(red: 0.925, green: 0.286, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            Text("Describe a movie, TV show, cartoon, or anime\nin your own words and AI will find it for you")
                                .font(.subheadline)
                                .foregroundColor(Color(white: 0.6))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20).padding(.bottom, 32)

                        // Search box
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DESCRIBE WHAT YOU REMEMBER")
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.655, green: 0.545, blue: 0.980))
                                .tracking(1.5)

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $vm.query)
                                    .focused($isTextEditorFocused)
                                    .frame(minHeight: 100, maxHeight: 160)
                                    .scrollContentBackground(.hidden)
                                    .foregroundColor(.white)
                                    .font(.body)

                                if vm.query.isEmpty && !vm.isRecording {
                                    Text("e.g. There was this cartoon I watched as a kid where kids had spinning tops that battled each other...")
                                        .foregroundColor(Color(white: 0.3))
                                        .font(.body)
                                        .allowsHitTesting(false)
                                        .padding(.top, 8).padding(.leading, 5)
                                }
                            }

                            if vm.isRecording {
                                HStack(spacing: 8) {
                                    Circle().fill(Color.red).frame(width: 8, height: 8)
                                    Text("Listening...").font(.caption).foregroundColor(Color(red: 0.925, green: 0.286, blue: 0.6))
                                }
                            }

                            Divider().background(Color(white: 0.15))

                            HStack {
                                Text("\(vm.query.count) characters")
                                    .font(.caption2).foregroundColor(Color(white: 0.4))
                                Spacer()

                                if !vm.storeService.isPro {
                                    Text("\(vm.storeService.remainingFreeSearches) free left")
                                        .font(.caption2).foregroundColor(Color(red: 0.655, green: 0.545, blue: 0.980))
                                }

                                // Microphone button
                                Button(action: { vm.toggleRecording() }) {
                                    Image(systemName: vm.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(
                                            vm.isRecording
                                                ? AnyShapeStyle(Color.red)
                                                : AnyShapeStyle(LinearGradient(colors: [Color(red: 0.545, green: 0.361, blue: 0.965), Color(red: 0.925, green: 0.286, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        )
                                        .cornerRadius(12)
                                }
                                .buttonStyle(.plain)

                                Button(action: { isTextEditorFocused = false; Task { await vm.search() } }) {
                                    Text(vm.isLoading ? "Searching..." : "Find It")
                                        .fontWeight(.semibold).foregroundColor(.white)
                                        .padding(.horizontal, 28).padding(.vertical, 12)
                                        .background(LinearGradient(colors: [Color(red: 0.545, green: 0.361, blue: 0.965), Color(red: 0.925, green: 0.286, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .cornerRadius(12)
                                        .opacity(vm.isLoading ? 0.6 : 1)
                                }
                                .disabled(vm.isLoading)
                            }
                        }
                        .padding(20)
                        .background(Color(red: 0.071, green: 0.071, blue: 0.102))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(white: 0.15), lineWidth: 1))

                        // Example pills
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Try an example:").font(.caption2).foregroundColor(Color(white: 0.4))
                            FlowLayout(spacing: 8) {
                                ForEach(vm.selectedLanguage.examplePills, id: \.self) { pill in
                                    Button(action: { vm.selectExample(pill) }) {
                                        Text(pill).font(.caption)
                                            .foregroundColor(Color(white: 0.6))
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(Color(red: 0.102, green: 0.102, blue: 0.149))
                                            .cornerRadius(100)
                                            .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color(white: 0.15), lineWidth: 1))
                                    }
                                }
                            }
                        }
                        .padding(.top, 16).padding(.bottom, 24)

                        // Error
                        if let error = vm.errorMessage {
                            HStack(spacing: 12) {
                                Text("⚠️")
                                Text(error).font(.subheadline).foregroundColor(Color(red: 0.988, green: 0.647, blue: 0.647))
                            }
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1)).cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            .padding(.bottom, 16)
                        }

                        // Loading
                        if vm.isLoading {
                            VStack(spacing: 24) {
                                ProgressView().tint(Color(red: 0.545, green: 0.361, blue: 0.965))
                                Text("AI is thinking...").font(.body).foregroundColor(Color(white: 0.6))
                                Text("Analyzing your description to find the best matches").font(.caption).foregroundColor(Color(white: 0.4))
                            }
                            .padding(.vertical, 60)
                        }

                        // Results
                        if vm.hasSearched && !vm.isLoading {
                            ResultsSection()
                                .id("results")
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture { isTextEditorFocused = false }
                .onChange(of: vm.hasSearched) { _, hasResults in
                    if hasResults && !vm.isLoading {
                        withAnimation(.easeOut(duration: 0.5)) {
                            scrollProxy.scrollTo("results", anchor: .top)
                        }
                    }
                }
                } // end ScrollViewReader
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isTextEditorFocused = false }
                        .foregroundColor(Color(red: 0.545, green: 0.361, blue: 0.965))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(AppLanguage.all) { lang in
                            Button(action: { vm.selectedLanguage = lang; vm.saveSettings() }) {
                                HStack {
                                    Text(lang.nativeName)
                                    if vm.selectedLanguage.code == lang.code { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("🌍")
                            Text(vm.selectedLanguage.nativeName).font(.caption).foregroundColor(.white)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color(red: 0.071, green: 0.071, blue: 0.102)).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.15), lineWidth: 1))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { vm.showSettings = true }) {
                        Image(systemName: "gearshape.fill").foregroundColor(Color(white: 0.5))
                    }
                }
            }
            .sheet(isPresented: $vm.showSettings) {
                SettingsView().environmentObject(vm)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var h: CGFloat = 0; var rw: CGFloat = 0; var rh: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if rw + s.width > maxW && rw > 0 { h += rh + spacing; rw = 0; rh = 0 }
            rw += s.width + spacing; rh = max(rh, s.height)
        }
        return CGSize(width: maxW, height: h + rh)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rh: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX && x > bounds.minX { x = bounds.minX; y += rh + spacing; rh = 0 }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; rh = max(rh, s.height)
        }
    }
}
