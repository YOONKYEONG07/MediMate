import SwiftUI
import UIKit

struct PrescriptionCaptureView: View {
    @State private var image: UIImage? = nil
    @State private var showingCamera = false
    @State private var showingAlbum = false
    @State private var detectedMeds: [String] = ["타이레놀", "게보린", "판콜에이"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 안내 텍스트
                Text("처방전을 촬영해주세요")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)

                Text("처방전 전체가 선명하게 나오도록 촬영해 주세요.")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("흐리거나 잘리면 인식이 어려울 수 있어요.\n빛 반사 없이 정면에서 찍어주세요.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // 사진 미리보기 or 예시
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                } else {
                    Image("prescription_sample")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                }

                // 버튼 2개: 카메라 / 앨범
                HStack(spacing: 12) {
                    Button(action: {
                        showingCamera = true
                    }) {
                        Text("카메라 열기")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        showingAlbum = true
                    }) {
                        Text("앨범에서 선택")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                // 결과 화면 보기 버튼
                NavigationLink(destination: PrescriptionResultListView(detectedMeds: detectedMeds)) {
                    Text("결과 화면 보기")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .disabled(image == nil)
                .opacity(image == nil ? 0.5 : 1.0)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("처방전 촬영")
            // ✅ 각각 독립된 시트로 분리
            .sheet(isPresented: $showingCamera) {
                AnalyzeImagePicker(sourceType: .camera, selectedImage: $image)
            }
            .sheet(isPresented: $showingAlbum) {
                AnalyzeImagePicker(sourceType: .photoLibrary, selectedImage: $image)
            }
        }
    }
}
