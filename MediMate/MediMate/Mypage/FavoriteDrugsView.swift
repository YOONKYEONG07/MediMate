import SwiftUI

struct FavoriteDrugsView: View {
    @State private var favoriteMeds: [String] = []

    var body: some View {
        List {
            if favoriteMeds.isEmpty {
                Text("즐겨찾기한 약이 없습니다.")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(favoriteMeds, id: \.self) { med in
                    NavigationLink(destination: MedicationDetailView(medName: med, previousScreenTitle: "마이페이지")) {
                        Text(med)
                    }
                }
            }
        }
        .navigationTitle("즐겨찾는 약") // ← 이건 유지 가능!
        .onAppear {
            loadFavorites()
        }
    }

    func loadFavorites() {
        favoriteMeds = UserDefaults.standard.stringArray(forKey: "favoriteMeds") ?? []
    }
}
