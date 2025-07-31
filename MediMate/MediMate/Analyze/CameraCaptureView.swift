import SwiftUI
import UIKit
import Vision

enum PickerType: Identifiable {
    case camera
    case photoLibrary

    var id: Int { hashValue }

    var sourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: return .camera
        case .photoLibrary: return .photoLibrary
        }
    }
}

struct CameraCaptureView: View {
    @State private var selectedPickerType: PickerType? = nil
    @State private var image: UIImage? = nil
    @State private var isUploading = false
    @State private var ocrResult: String? = nil
    @State private var confirmedMedName: String? = nil
    @State private var navigateToConfirm = false
    @State private var navigateToResult = false
    @State private var ocrCandidates: [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
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
                            selectedPickerType = .camera
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)

                        Button("앨범에서 선택") {
                            selectedPickerType = .photoLibrary
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Button(action: {
                        guard let image = image else { return }

                        isUploading = true
                        performVisionOCR(on: image) { result in
                            let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                            let firstLine = trimmed.components(separatedBy: .newlines).first ?? trimmed
                            print("\u{1F4F8} OCR 결과: \(firstLine)")

                            DispatchQueue.main.async {
                                self.isUploading = false
                                if !firstLine.isEmpty {
                                    self.ocrResult = firstLine
                                    self.navigateToConfirm = true
                                } else {
                                    self.ocrResult = nil
                                }
                            }
                        }
                    }) {
                        if isUploading {
                            ProgressView().frame(maxWidth: .infinity).padding()
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
                    .disabled(image == nil || isUploading)
                    .opacity(image == nil ? 0.5 : 1.0)
                    .padding(.horizontal)

                    Spacer()
                }

                NavigationLink(
                    destination: OCRConfirmView(
                        recognizedName: Binding(
                            get: { self.ocrResult ?? "" },
                            set: { self.ocrResult = $0 }
                        ),
                        ocrCandidates: self.ocrCandidates, // ✅ 추가된 파라미터
                        onConfirm: { finalName in
                            self.confirmedMedName = finalName
                            self.navigateToResult = true
                        }
                    ),
                    isActive: $navigateToConfirm
                ) {
                    EmptyView()
                }


                NavigationLink(
                    destination: MedicationDetailView(medName: confirmedMedName ?? "알 수 없음"),
                    isActive: $navigateToResult
                ) {
                    EmptyView()
                }
            }
            .navigationTitle("약 사진 촬영")
        }
        .sheet(item: $selectedPickerType) { pickerType in
            AnalyzeImagePicker(sourceType: pickerType.sourceType, selectedImage: Binding(
                get: { self.image },
                set: { newImage in
                    print("\u{1F4E5} 선택된 새 이미지: \(newImage)")
                    self.image = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.image = newImage
                    }
                }
            ))
        }
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
            print("🔍 전체 OCR 결과:\n\(texts.joined(separator: "\n"))")

            // 💊 약 이름처럼 보이는 후보들 (약 이름 사전 기반)
            let knownMedNames = ["판콜에이", "이지엔6", "타이레놀", "게보린", "쌍화탕", "판피린", "시콜드", "콜대원", "펜잘", "부루펜"]
            let medNameCandidates = texts.filter { text in
                knownMedNames.contains(where: { name in
                    text.replacingOccurrences(of: " ", with: "").contains(name)
                })
            }

            // 🔍 추가 후보 필터링 (키워드 기반도 함께 사용 가능)
            let keywordCandidates = texts.filter {
                $0.contains("정") || $0.contains("캡슐") || $0.contains("이브") || $0.contains("시럽")
            }

            // 최종 후보: 우선순위는 known > keyword > fallback
            let result = medNameCandidates.first
                ?? keywordCandidates.first
                ?? texts.first
                ?? "인식 실패"

            DispatchQueue.main.async {
                self.ocrCandidates = texts // 전체 후보 저장
                completion(result)
            }
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
}
