import SwiftUI

struct AnalyzeView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // 제목
                Text("입력 방식 선택")
                    .font(.title)
                    .bold()

                // 텍스트로 검색 버튼
                NavigationLink(destination: TextSearchView()) {
                    InputOptionButton(icon: "magnifyingglass", title: "텍스트로 검색")
                }
                .buttonStyle(.plain)

                // 약 사진 촬영 버튼
                NavigationLink(destination: CameraCaptureView()) {
                    InputOptionButton(icon: "camera", title: "약 사진 촬영")
                }
                .buttonStyle(.plain)

                // 처방전 촬영 버튼
                NavigationLink(destination: PrescriptionCaptureView()) {
                    InputOptionButton(icon: "doc.text", title: "처방전 촬영")
                }
                .buttonStyle(.plain)

                Spacer(minLength: 30)

                // 💬 캐릭터 + 말풍선 중간 위치에 배치
                HStack(alignment: .center, spacing: 16) {
                    Image("green_pill")
                        .resizable()
                        .frame(width: 120, height: 120)

                    Text("""
                    💡 약 이름을 직접 입력하거나,
                    사진을 찍어서
                    성분을 분석할 수 있어요!
                    편한 방법을 골라주세요.

                    ⚠️ 흐릿한 사진은 인식이 어려워요!
                    라벨과 글자가 잘 보이도록
                    밝고 선명하게 찍어주세요.
                    """)
                    .font(.subheadline)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)

                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10) // ← 이 정도면 딱 중간쯤

                Spacer(minLength: 20)
            }
            .padding()
            .navigationTitle("분석")
        }
    }
}
