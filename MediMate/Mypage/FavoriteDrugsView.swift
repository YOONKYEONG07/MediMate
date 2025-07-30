import SwiftUI

struct FavoriteDrugsView: View {
    @EnvironmentObject var userSession: UserSession  // 🔹 사용자 정보 가져오기
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
        .navigationTitle("즐겨찾는 약")
        .onAppear {
            loadFavorites()
        }
    }

    func loadFavorites() {
        userSession.fetchFavorites { meds in
            DispatchQueue.main.async {
                self.favoriteMeds = meds
            }
        }
    }
}
