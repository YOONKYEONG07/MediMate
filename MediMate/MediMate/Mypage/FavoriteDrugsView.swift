import SwiftUI

struct FavoriteDrugsView: View {
    @State private var favoriteMeds: [String] = []

    var body: some View {
        NavigationView {
            List {
                if favoriteMeds.isEmpty {
                    Text("즐겨찾기한 약이 없습니다.")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(favoriteMeds, id: \.self) { med in
                        NavigationLink(destination: MedicationDetailView(medName: med)) {
                            Text(med)
                        }
                    }
                }
            }
            .navigationTitle("즐겨찾는 약")
            .onAppear {
                loadFavorites()
            }
        }
    }

    // MARK: - UserDefaults에서 즐겨찾기 불러오기
    func loadFavorites() {
        favoriteMeds = UserDefaults.standard.stringArray(forKey: "favoriteMeds") ?? []
    }
}

#Preview {
    FavoriteDrugsView()
}
