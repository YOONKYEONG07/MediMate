import SwiftUI
import FirebaseAuth

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
                    let mapped = SupplementMapper.shared.mapToIngredient(med)

                    NavigationLink(destination: MedicationDetailView(medName: mapped, previousScreenTitle: "마이페이지")) {
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
        // UID별로 favoriteMeds를 분리 저장 및 불러오기
        if let uid = Auth.auth().currentUser?.uid {
            let key = "favoriteMeds_\(uid)"
            favoriteMeds = UserDefaults.standard.stringArray(forKey: key) ?? []
        } else {
            favoriteMeds = []
        }
    }
}
