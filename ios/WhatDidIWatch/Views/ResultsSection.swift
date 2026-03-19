import SwiftUI

struct ResultsSection: View {
    @EnvironmentObject var vm: SearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if vm.results.isEmpty {
                VStack(spacing: 12) {
                    Text("🤔").font(.system(size: 48))
                    Text("Couldn't find a match").font(.title3).fontWeight(.semibold).foregroundColor(.white)
                    Text("Try adding more details!").font(.subheadline).foregroundColor(Color(white: 0.6))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
            } else {
                HStack(spacing: 8) {
                    Text("Here's what I found").font(.title2).fontWeight(.semibold).foregroundColor(.white)
                    Text("\(vm.results.count) matches").font(.caption2).fontWeight(.bold).foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Color(red: 0.545, green: 0.361, blue: 0.965)).cornerRadius(100)
                }

                ForEach(Array(vm.results.enumerated()), id: \.element.id) { index, match in
                    ResultCard(match: match, isBestMatch: index == 0 && match.confidence == "high")
                }
            }
        }
    }
}

struct ResultCard: View {
    let match: MatchResult
    let isBestMatch: Bool
    @State private var showLinks = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isBestMatch {
                HStack {
                    Spacer()
                    Text("🎯 BEST MATCH").font(.system(size: 10, weight: .bold)).tracking(1).foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(LinearGradient(colors: [Color(red: 0.545, green: 0.361, blue: 0.965), Color(red: 0.925, green: 0.286, blue: 0.6)], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(100)
                }
                .padding(.top, 12).padding(.trailing, 16)
            }

            HStack(alignment: .top, spacing: 16) {
                if let url = match.posterURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill).frame(width: 90, height: 135).cornerRadius(12)
                        } else {
                            PosterPlaceholder()
                        }
                    }
                } else { PosterPlaceholder() }

                VStack(alignment: .leading, spacing: 8) {
                    Text(match.title).font(.title3).fontWeight(.bold).foregroundColor(.white).lineLimit(2)

                    HStack(spacing: 8) {
                        Text("\(match.typeEmoji) \(match.type.uppercased())").font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.655, green: 0.545, blue: 0.980))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(red: 0.039, green: 0.039, blue: 0.059)).cornerRadius(6)

                        if let year = match.year { Text("📅 \(String(year))").font(.caption).foregroundColor(Color(white: 0.6)) }
                        if let r = match.rating, r > 0 { Text("⭐ \(String(format: "%.1f", r))/10").font(.caption).foregroundColor(Color(white: 0.6)) }
                    }

                    let c = match.confidenceColor
                    Text(match.confidence.uppercased()).font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: c.r, green: c.g, blue: c.b))
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Color(red: c.r, green: c.g, blue: c.b).opacity(0.15)).cornerRadius(100)
                }
            }
            .padding(isBestMatch ? .horizontal : .all, 16)
            .padding(.top, isBestMatch ? 8 : 0)

            HStack(spacing: 8) {
                Text("💡"); Text(match.explanation).font(.subheadline).foregroundColor(.white).lineSpacing(4)
            }
            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(0.08)).cornerRadius(12)
            .overlay(HStack { Rectangle().fill(Color.purple).frame(width: 3); Spacer() }.cornerRadius(12))
            .padding(.horizontal, 16).padding(.top, 12)

            if let overview = match.overview, !overview.isEmpty {
                Text(overview).font(.caption).foregroundColor(Color(white: 0.6)).lineSpacing(3).lineLimit(3)
                    .padding(.horizontal, 16).padding(.top, 8)
            }

            Button(action: { withAnimation { showLinks.toggle() } }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Where to Watch").font(.subheadline).fontWeight(.medium)
                    Spacer()
                    Image(systemName: showLinks ? "chevron.up" : "chevron.down").font(.caption)
                }
                .foregroundColor(Color(red: 0.655, green: 0.545, blue: 0.980))
                .padding(.horizontal, 16).padding(.top, 12)
            }

            if showLinks {
                let links = MatchResult.WatchLinks.build(title: match.tmdbTitle ?? match.title, year: match.year)
                VStack(spacing: 8) {
                    WatchLinkBtn(name: "JustWatch", icon: "magnifyingglass", url: links.justwatch, color: .yellow)
                    WatchLinkBtn(name: "Amazon", icon: "cart.fill", url: links.amazon, color: .orange)
                    WatchLinkBtn(name: "Apple TV", icon: "appletv.fill", url: links.appleTV, color: .white)
                    WatchLinkBtn(name: "YouTube", icon: "play.rectangle.fill", url: links.youtube, color: .red)
                    WatchLinkBtn(name: "Google", icon: "globe", url: links.google, color: .blue)
                }
                .padding(.horizontal, 16).padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer().frame(height: 16)
        }
        .background(Color(red: 0.102, green: 0.102, blue: 0.149)).cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(isBestMatch ? Color.purple.opacity(0.4) : Color(white: 0.15), lineWidth: 1))
    }
}

struct PosterPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.071, green: 0.071, blue: 0.102)).frame(width: 90, height: 135)
            Image(systemName: "film").font(.title2).foregroundColor(Color(white: 0.35))
        }
    }
}

struct WatchLinkBtn: View {
    let name: String; let icon: String; let url: URL?; let color: Color
    var body: some View {
        if let url = url {
            Link(destination: url) {
                HStack(spacing: 12) {
                    Image(systemName: icon).foregroundColor(color).frame(width: 24)
                    Text(name).font(.subheadline).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.caption).foregroundColor(Color(white: 0.35))
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(red: 0.039, green: 0.039, blue: 0.059)).cornerRadius(10)
            }
        }
    }
}
