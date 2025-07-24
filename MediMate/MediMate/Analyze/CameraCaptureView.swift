import SwiftUI
import UIKit
import Vision  // ✅ Vision 프레임워크 추가

struct CameraCaptureView: View {
    @State private var image: UIImage? = nil
    @State private var selectedSourceType: UIImagePickerController.SourceType? = nil
    @State private var isUploading = false
    @State private var ocrResult: String? = nil
    @State private var navigateToResult = false

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
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Button(action: {
                    if let image = image {
                        isUploading = true
                        performVisionOCR(on: image) { result in
                            DispatchQueue.main.async {
                                self.ocrResult = result.trimmingCharacters(in: .whitespacesAndNewlines)
                                self.navigateToResult = true
                                self.isUploading = false
                            }
                        }
                    }
                }) {
                    if isUploading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("결과 화면 보기")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(image != nil ? Color.green : Color.gray)  // ✅ 색상 통일
                            .cornerRadius(12)
                    }
                }
                .disabled(image == nil || isUploading)
                .opacity(image == nil ? 0.5 : 1.0)
                .padding(.horizontal)


                    Spacer()
                    
                }

                Spacer()

                // 👉 결과 화면으로 자동 이동
                NavigationLink(
                    destination: MedicationDetailView(medName: ocrResult ?? "알 수 없음"),
                    isActive: $navigateToResult
                ) {
                    EmptyView()
                }
            }
            .padding()
            .navigationTitle("약 사진 촬영")
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

// ✅ Vision OCR 함수 (파일 아래쪽에 추가)
func performVisionOCR(on image: UIImage, completion: @escaping (String) -> Void) {
    guard let cgImage = image.cgImage else {
        completion("이미지 변환 실패")
        return
    }

    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    let request = VNRecognizeTextRequest { request, error in
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            completion("인식 실패")
            return
        }

        let texts = results.compactMap { $0.topCandidates(1).first?.string }
        completion(texts.joined(separator: "\n"))
    }

    request.recognitionLanguages = ["ko-KR", "en-US"]
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true

    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try requestHandler.perform([request])
        } catch {
            completion("OCR 오류: \(error.localizedDescription)")
        }
    }
}

