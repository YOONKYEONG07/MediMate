import SwiftUI
import UIKit
import Vision

struct PrescriptionCaptureView: View {
    @State private var image: UIImage? = nil
    @State private var selectedPicker: PickerType? = nil
    @State private var isProcessing = false
    @State private var detectedMeds: [String] = []
    @State private var navigateToResult = false
    @State private var selectedPickerType: PickerType? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
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

                HStack(spacing: 12) {
                    Button("카메라 열기") {
                        selectedPicker = .camera
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)

                    Button("앨범에서 선택") {
                        selectedPicker = .photoLibrary  // ✅ 정확한 이름

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
                        isProcessing = true
                        performVisionOCR(on: image) { result in
                            DispatchQueue.main.async {
                                self.detectedMeds = extractMedicationNames(from: result)
                                self.navigateToResult = true
                                self.isProcessing = false
                            }
                        }
                    }
                }) {
                    if isProcessing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("결과 화면 보기")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(image != nil ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                }
                .disabled(image == nil || isProcessing)
                .opacity(image == nil ? 0.5 : 1.0)
                .padding(.horizontal)

                Spacer()

                NavigationLink(
                    destination: PrescriptionResultListView(detectedMeds: detectedMeds),
                    isActive: $navigateToResult
                ) {
                    EmptyView()
                }
            }
            .padding()
            .navigationTitle("처방전 촬영")
            .sheet(item: $selectedPicker) { picker in
                AnalyzeImagePicker(sourceType: picker.sourceType, selectedImage: $image)
            }
        }
    }
}

// ✅ 약 이름 추출 로직 (간단한 예시)
func extractMedicationNames(from ocrText: String) -> [String] {
    let knownMeds = ["타이레놀", "게보린", "판콜에이", "신일이부프로펜", "알마겔", "서스펜",
                     "부루펜", "타세놀", "지르텍", "펜잘", "이부프로펜", "신풍이부펜"]
    return knownMeds.filter { ocrText.contains($0) }
}
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
        let combinedText = texts.joined(separator: "\n")
        completion(combinedText)
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

