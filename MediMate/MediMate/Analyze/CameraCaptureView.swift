import SwiftUI
import UIKit

struct CameraCaptureView: View {
    @State private var image: UIImage? = nil
    @State private var selectedSourceType: UIImagePickerController.SourceType? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("약 사진을 촬영해주세요")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)

                Text("깨끗한 배경에서 사진을 또렷하게 촬영해주세요.")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("사진이 흐리거나 인식이 잘 안 될 경우,\n다시 촬영해 주세요.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                } else {
                    Image("pill_sample")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                }

                HStack(spacing: 12) {
                    Button("카메라 열기") {
                        selectedSourceType = .camera
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)

                    Button("앨범에서 선택") {
                        selectedSourceType = .photoLibrary
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                NavigationLink(destination: MedicationDetailView(medName: "타이레놀")) {
                    Text("결과 화면 보기")
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
            .navigationTitle("약 사진 촬영")

            // ✅ 핵심: 옵셔널 타입을 item으로 사용
            .sheet(item: $selectedSourceType) { type in
                if UIImagePickerController.isSourceTypeAvailable(type) {
                    AnalyzeImagePicker(sourceType: type, selectedImage: $image)
                } else {
                    Text("해당 기능을 사용할 수 없습니다.")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
    }
}

// ✅ 이거도 같이 붙여줘야 .sheet(item:)이 작동함!
extension UIImagePickerController.SourceType: Identifiable {
    public var id: String {
        String(describing: self)
    }
}
