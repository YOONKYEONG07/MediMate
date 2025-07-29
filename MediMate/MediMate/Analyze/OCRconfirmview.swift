import SwiftUI
import Combine

struct OCRConfirmView: View {
    @Binding var recognizedName: String
    var onConfirm: (String) -> Void

    @State private var keyboardHeight: CGFloat = 0
    @State private var shouldNavigate = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 32)

                // 🤔 캐릭터 이미지
                Image("question_character")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 240)

                // 💊 약 이름 표시
                Text(recognizedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "“인식된 텍스트 없음”" : "“\(recognizedName)”")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(recognizedName.isEmpty ? .gray : .blue)
                    .multilineTextAlignment(.center)

                Text("정확한 약 이름이 아닐 경우, 직접 입력하여 수정해 주세요.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // ✏️ 입력창
                TextField("약 이름 확인 또는 수정", text: $recognizedName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                // ✅ 확인 버튼
                Button(action: {
                    print("🔘 확인 버튼 눌림 - 이름: \(recognizedName)")
                    onConfirm(recognizedName)
                    shouldNavigate = true
                }) {
                    Text("확인")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                // ✅ 결과 화면으로 이동하는 링크
                NavigationLink(
                    destination: MedicationDetailView(medName: recognizedName),
                    isActive: $shouldNavigate
                ) {
                    EmptyView()
                }

                Spacer()
                    .frame(height: keyboardHeight)
            }
        }
        .padding()
        .background(Color.white)
        .onReceive(Publishers.keyboardHeight) { height in
            withAnimation {
                self.keyboardHeight = height
            }
        }
    }
}

// MARK: - 키보드 높이 감지 확장
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}
