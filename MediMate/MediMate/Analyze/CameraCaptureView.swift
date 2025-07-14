import SwiftUI
import UIKit

struct CameraCaptureView: View {
    @State private var image: UIImage? = nil
    @State private var isShowingCamera = false
    @State private var navigateToResult = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("약 사진을 촬영해주세요")
                    .font(.headline)
                    .padding(.top)

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                } else {
                    Image("pill_sample") // 예시 이미지 (없으면 생략)
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

                    NavigationLink(destination: MedicationDetailView(medName: "타이레놀")) {
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
            .navigationTitle("약 사진 촬영")
            .sheet(isPresented: $isShowingCamera) {
                CustomImagePicker(sourceType: .camera, selectedImage: $image)
            }
        }
    }
}
