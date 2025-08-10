import SwiftUI
import UIKit

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

struct PrescriptionCaptureView: View {
    @State private var image: UIImage? = nil
    @State private var selectedPicker: PickerType? = nil
    @State private var isProcessing = false

    @State private var detectedMeds: [String] = []
    @State private var medBoundingBoxes: [CGRect] = []

    @State private var goConfirm = false

    // (선택) 화이트리스트 필터: 등록 약만 통과시키고 싶을 때 사용
    private let knownMeds: Set<String> = [
        "타이레놀","게보린","판콜에이","신일이부프로펜","알마겔","서스펜",
        "부루펜","타세놀","지르텍","펜잘","이부프로펜","신풍이부펜"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("처방전을 촬영해주세요")
                    .font(.title2).fontWeight(.semibold)
                    .padding(.top)

                Text("처방전 전체가 선명하게 나오도록 촬영해 주세요.\n빛 반사 없이 정면에서 찍어주세요.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Group {
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
                }

                // 하단 버튼
                HStack(spacing: 12) {
                    Button("카메라 열기") { selectedPicker = .camera }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)

                    Button("앨범에서 선택") { selectedPicker = .photoLibrary }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                // 상태 표시 / 재시도
                if isProcessing {
                    ProgressView("텍스트 인식 중…")
                        .padding(.horizontal)
                } else if image != nil && detectedMeds.isEmpty {
                    // (선택) 약 미검출 메시지
                    Text("등록된 약 이름을 찾지 못했어요. 이미지가 흐리거나 잘렸는지 확인해 주세요.")
                        .font(.footnote)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // OCR 완료 후에만 다음 화면으로 이동
                if let img = image {
                    NavigationLink(
                        destination: PrescriptionConfirmView(
                            image: img,
                            detectedMeds: detectedMeds,
                            medBoundingBoxes: medBoundingBoxes
                        ),
                        isActive: $goConfirm
                    ) { EmptyView() }
                }
            }
            .padding()
            .navigationTitle("처방전 촬영")
            .sheet(item: $selectedPicker) { picker in
                AnalyzeImagePicker(sourceType: picker.sourceType, selectedImage: $image)
            }
            // ✅ 사진 선택/촬영 즉시 OCR 돌리고, 끝나면 이동
            .onChange(of: image) { img in
                guard let img else { return }
                runOCRPipeline(with: img)
            }
        }
    }

    private func runOCRPipeline(with img: UIImage) {
        // 초기화
        detectedMeds = []
        medBoundingBoxes = []
        isProcessing = true
        goConfirm = false

        performVisionOCR(on: img) { texts, boxes in
            let meds = texts
            let bbs  = boxes

            // (옵션2) 필터 없이 전부 보내고, Confirm 화면에서 사용자가 선택/수정하도록 하려면:
            // let meds = texts
            // let bbs  = boxes

            self.detectedMeds = meds
            self.medBoundingBoxes = bbs
            self.isProcessing = false

            // 결과 화면 열기 (검출 0개여도 수정 입력 가능하게 열고 싶으면 true로 유지)
            self.goConfirm = true
        }
    }
}
