import SwiftUI

struct AnalyzeView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("입력 방식 선택")
                    .font(.title)
                    .bold()

                InputOptionButton(icon: "magnifyingglass", title: "텍스트로 검색")
                InputOptionButton(icon: "camera", title: "약 사진 촬영")
                InputOptionButton(icon: "doc.text", title: "처방전 촬영")

                Text("텍스트나 사진을 통해 약 정보를 분석할 수 있어요.")
                    .foregroundColor(.gray)
                    .padding(.top, 16)

                Spacer()
            }
            .padding()
            .navigationTitle("분석")
        }
    }
}

#Preview {
    AnalyzeView()
}
