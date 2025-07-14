import SwiftUI

struct AnalyzeView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 제목
                Text("입력 방식 선택")
                    .font(.title)
                    .bold()
                
                // 텍스트로 검색 버튼 → 다음 화면으로 이동
                NavigationLink(destination: TextSearchView()) {
                    InputOptionButton(icon: "magnifyingglass", title: "텍스트로 검색")
                }
                .buttonStyle(.plain)


                // 약 사진 촬영 (동작 없음)
                NavigationLink(destination: CameraCaptureView()) {
                    InputOptionButton(icon: "camera", title: "약 사진 촬영")
                }
                .buttonStyle(.plain)

                
                // 처방전 촬영 (동작 없음)
                NavigationLink(destination: PrescriptionCaptureView()) {
                    InputOptionButton(icon: "doc.text", title: "처방전 촬영")
                }
                .buttonStyle(.plain)


                // 설명 텍스트
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
