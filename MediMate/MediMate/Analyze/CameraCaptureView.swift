import SwiftUI
import UIKit

struct CameraCaptureView: View {
    @State private var image: UIImage? = nil
    @State private var isShowingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 안내 텍스트
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
                
                // 사진 미리보기 또는 예시 이미지
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320) // ✅ 크기 살짝 키움
                        .cornerRadius(12)
                        .shadow(radius: 3)
                } else {
                    Image("pill_sample")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 320) // ✅ 크기 살짝 키움
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                }
                
                // 버튼 2개 (카메라, 앨범)
                HStack(spacing: 12) {
                    // 📸 카메라 열기
                    Button(action: {
                        sourceType = .camera
                        isShowingCamera = true
                    }) {
                        Text("카메라 열기")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    // 🖼️ 앨범에서 선택
                    Button(action: {
                        sourceType = .photoLibrary
                        isShowingCamera = true
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
                
                // 결과 화면 보기
                NavigationLink(destination: MedicationDetailView(medName: "타이레놀")) {
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
            .navigationTitle("약 사진 촬영")
            // ✅ 카메라 전용 sheet
            .navigationTitle("약 사진 촬영")
            
            // ✅ 여기에 이거 추가!
            .sheet(isPresented: $isShowingCamera) {
                if UIImagePickerController.isSourceTypeAvailable(sourceType) {
                    AnalyzeImagePicker(sourceType: sourceType, selectedImage: $image)
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
