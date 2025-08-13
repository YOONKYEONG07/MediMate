import SwiftUI

// (선택) 안 쓰면 지워도 돼요
struct RecognizedMed: Identifiable {
    let id = UUID()
    let name: String
    let boundingBox: CGRect
}

// 실제로 화면에 그려진 이미지 사각형(ScaledToFit) 계산
private func aspectFitRect(imageSize: CGSize, container: CGSize) -> CGRect {
    let scale = min(container.width / imageSize.width, container.height / imageSize.height)
    let w = imageSize.width * scale
    let h = imageSize.height * scale
    let x = (container.width - w) / 2
    let y = (container.height - h) / 2
    return CGRect(x: x, y: y, width: w, height: h)
}

struct PrescriptionConfirmView: View {
    let image: UIImage
    let detectedMeds: [String]
    let medBoundingBoxes: [CGRect]

    @State private var selectedMed: String? = nil
    @State private var editedMedName: String = ""
    @State private var navigateToResult = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 헤더
                VStack(spacing: 8) {
                    Text("인식 결과 확인")
                        .font(.largeTitle).bold()
                        .multilineTextAlignment(.center)

                    Text("인식된 약 중에 결과를 확인하고 싶은 약을 \n한 개 선택해주세요.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                // 이미지 + 라벨 오버레이
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)

                    GeometryReader { geo in
                        let drawRect = aspectFitRect(imageSize: image.size, container: geo.size)

                        ForEach(Array(detectedMeds.enumerated()), id: \.offset) { index, med in
                            if index < medBoundingBoxes.count {
                                let box = medBoundingBoxes[index]   // Vision normalized (0~1, 좌하 원점)

                                // drawRect 기준 좌표 변환
                                let x = drawRect.minX + box.origin.x * drawRect.width
                                let y = drawRect.minY + (1 - box.origin.y - box.height) * drawRect.height
                                let w = box.width  * drawRect.width
                                let h = box.height * drawRect.height

                                Button {
                                    selectedMed = med
                                    editedMedName = med
                                } label: {
                                    Text(med)
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.yellow)
                                        .foregroundColor(.black)
                                        .cornerRadius(6)
                                }
                                .position(x: x + w/2, y: y + h/2)
                            }
                        }
                    }
                }
                .frame(height: 300)

                // 디버그: 인식 개수/예시
                Group {
                    if detectedMeds.isEmpty {
                        Text("인식 0개 (OCR 미실행/실패/전달 문제)")
                            .font(.footnote).foregroundColor(.red)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("인식 \(detectedMeds.count)개")
                                .font(.footnote).foregroundColor(.green)
                            Text(detectedMeds.prefix(5).joined(separator: ", "))
                                .font(.footnote).foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                .padding(.horizontal)

                // 편집 + 이동 버튼
                VStack(alignment: .leading, spacing: 12) {
                    Text("필요할 경우 약 이름을 수정하세요.")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    ZStack(alignment: .trailing) {
                        TextField("", text: $editedMedName)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)

                        if !editedMedName.isEmpty {
                            Button {
                                editedMedName = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 12)
                            }
                        }
                    }

                    Button {
                        if !editedMedName.trimmingCharacters(in: .whitespaces).isEmpty {
                            navigateToResult = true
                        }
                    } label: {
                        Text("결과 화면 보기")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                editedMedName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue
                            )
                            .cornerRadius(12)
                    }
                    .disabled(editedMedName.trimmingCharacters(in: .whitespaces).isEmpty)

                    NavigationLink(
                        destination: MedicationDetailView(medName: editedMedName),
                        isActive: $navigateToResult
                    ) { EmptyView() }
                }
                .padding(.horizontal)
                .padding(.bottom, 300) // 키보드 대비 여유
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            if editedMedName.isEmpty, let first = detectedMeds.first {
                selectedMed = first
                editedMedName = first
            }
        }
    }
}
