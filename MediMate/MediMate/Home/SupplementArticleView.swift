import SwiftUI

struct SupplementArticleView: View {
    let supplementName: String

    var body: some View {
        ScrollView {
            if let info = SupplementInfoDB.all[supplementName] {
                VStack(alignment: .leading, spacing: 16) {
                    Text("💊 \(info.name)")
                        .font(.title2).bold()

                    Group {
                        Text("📌 기능성")
                            .font(.headline)
                        Text(info.function)

                        Text("⚠️ 주의사항")
                            .font(.headline)
                        Text(info.caution)

                        Text("🍽️ 섭취 방법")
                            .font(.headline)
                        Text(info.method)
                    }
                    .padding(.bottom, 8)
                }
                .padding()
            } else {
                Text("❌ 관련된 영양제 정보를 찾을 수 없습니다.")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .navigationTitle("영양제 정보")
    }
}
