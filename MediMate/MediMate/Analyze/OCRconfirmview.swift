import SwiftUI
import Combine
import UIKit

struct OCRConfirmView: View {
    @Binding var recognizedName: String
    var ocrCandidates: [String]
    var onConfirm: (String) -> Void

    @State private var keyboardHeight: CGFloat = 0
    @State private var shouldNavigate = false
    @State private var selectedIndex: Int? = nil // ✅ 선택된 인덱스 추적

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 10)

                // 🤔 캐릭터 이미지
                Image("question_character")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)

                // 📢 안내 문구
                Text("모든 글자를 인식했어요!\n아래에서 약 이름을 선택하거나 \n직접 입력해 수정해주세요.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // ✅ OCR 후보 리스트
                if !ocrCandidates.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("인식된 후보 목록")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 8)

                        ForEach(ocrCandidates.indices, id: \.self) { index in
                            let candidate = ocrCandidates[index]

                            Button(action: {
                                recognizedName = candidate
                                selectedIndex = index // ✅ 선택된 index 저장
                            }) {
                                HStack {
                                    Text(candidate)
                                        .foregroundColor(.primary)
                                        .padding(.vertical, 12)

                                    Spacer()

                                    if selectedIndex == index {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .background(Color(.systemBackground))
                            }

                            if index < ocrCandidates.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // ✏️ 선택된 약 이름 수정창
                VStack(alignment: .leading, spacing: 6) {
                    Text("필요할 경우 약 이름을 수정하세요")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    HStack {
                        TextField("", text: $recognizedName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        if !recognizedName.isEmpty {
                            Button(action: {
                                recognizedName = ""
                                selectedIndex = nil // ✅ 초기화 시 체크도 해제
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

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
        .padding(.vertical)
        .background(Color(.systemBackground))
        .onReceive(Publishers.keyboardHeight) { height in
            withAnimation {
                self.keyboardHeight = height
            }
        }
    }
}

// ✅ 키보드 높이 감지
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
