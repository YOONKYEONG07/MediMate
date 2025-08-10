/*import SwiftUI

struct AnalyzeParentView: View {
    @State private var showPicker = false
    @State private var selectedImage: UIImage? = nil

    @State private var detected: [String] = []
    @State private var boxes: [CGRect] = []
    @State private var goConfirm = false

    var body: some View {
        VStack(spacing: 16) {
            Text("✅ AnalyzeParentView OPENED") // 화면 열렸는지 표시
                .font(.footnote).foregroundColor(.blue)
            
            Button("앨범에서 처방전 선택") { showPicker = true }

            if !detected.isEmpty {
                Text("임시: 인식 \(detected.count)개")
                    .font(.footnote).foregroundColor(.green)
            }
        }
        .sheet(isPresented: $showPicker) {
            AnalyzeImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { img in
            guard let img else { return }
            print("🖼️ 선택됨, OCR 시작")
            performVisionOCR(on: img) { texts, bboxes in
                DispatchQueue.main.async {
                    print("📦 호출부 수신: \(texts.count)개, 예시=\(texts.prefix(5))")
                    self.detected = texts
                    self.boxes = bboxes
                    self.goConfirm = true      // ✅ OCR 끝난 뒤에만 이동
                }
            }
        }
        // 🔧 destination을 별도 ViewBuilder로 분리
        .background(
            NavigationLink(destination: destinationView, isActive: $goConfirm) {
                EmptyView()
            }
        )
        .navigationTitle("분석 테스트")
    }

    // MARK: - Destination 뷰 (타입 안정)
    @ViewBuilder
    private var destinationView: some View {
        if let img = selectedImage {
            PrescriptionConfirmView(image: img,
                                    detectedMeds: detected,
                                    medBoundingBoxes: boxes)
        } else {
            EmptyView()
        }
    }
}*/
