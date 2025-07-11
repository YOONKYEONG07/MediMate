import SwiftUI

struct PrescriptionCaptureView: View {
    @State private var image: UIImage? = nil
    @State private var isShowingCamera = false
    @State private var detectedMeds: [String] = ["타이레놀", "게보린", "판콜에이"]


    var body: some View {
        NavigationStack { // ✅ 여기 NavigationView → NavigationStack으로 변경
            VStack(spacing: 20) {
                Text("처방전을 촬영해주세요")
                    .font(.headline)
                    .padding(.top)

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                } else {
                    Image("prescription_sample")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                }

                HStack(spacing: 12) {
                    Button("카메라 열기") {
                        isShowingCamera = true
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                    NavigationLink(destination: PrescriptionResultListView(detectedMeds: detectedMeds)) {
                        Text("결과 화면 보기")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }

                Spacer()
            }
            .padding()
                        .navigationTitle("처방전 촬영")
                        .sheet(isPresented: $isShowingCamera) {
                            ImagePicker(sourceType: .camera, selectedImage: $image)
                        }
                    }
                }
            }
