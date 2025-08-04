import SwiftUI

struct RecognizedMed: Identifiable {
    let id = UUID()
    let name: String
    let boundingBox: CGRect
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
                VStack(spacing: 8) {
                    Text("인식 결과 확인")
                        .font(.largeTitle).bold()
                        .multilineTextAlignment(.center)

                    Text("인식된 약 중에 결과를 확인하고 싶은 약을 \n한 개 선택해주세요.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)

                    GeometryReader { geo in
                        ForEach(Array(detectedMeds.enumerated()), id: \.offset) { index, med in
                            if index < medBoundingBoxes.count {
                                let box = medBoundingBoxes[index]
                                let imgSize = geo.size
                                let x = box.origin.x * imgSize.width
                                let y = (1 - box.origin.y - box.height) * imgSize.height
                                let width = box.width * imgSize.width
                                let height = box.height * imgSize.height

                                Button(action: {
                                    selectedMed = med
                                    editedMedName = med
                                }) {
                                    Text(med)
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.yellow)
                                        .foregroundColor(.black)
                                        .cornerRadius(6)
                                }
                                .position(x: x + width / 2, y: y + height / 2)
                            }
                        }
                    }
                }
                .frame(height: 300)

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
                            Button(action: {
                                editedMedName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 12)
                            }
                        }
                    }

                    Button(action: {
                        navigateToResult = true
                    }) {
                        Text("결과 화면 보기")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    NavigationLink(destination: MedicationDetailView(medName: editedMedName), isActive: $navigateToResult) {
                        EmptyView()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 300) // 키보드 대비 여유 높이
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}
