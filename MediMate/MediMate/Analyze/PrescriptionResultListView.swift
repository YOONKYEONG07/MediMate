/*import SwiftUI

struct PrescriptionResultListView: View {
    let detectedMeds: [String]
    let capturedImage: UIImage?  // ✅ 추가

    @State private var searchText = ""

    var filteredMeds: [String] {
        if searchText.isEmpty {
            return detectedMeds
        } else {
            return detectedMeds.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                // ✅ 이미지 표시
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                // 인식된 약 개수
                Text("총 \(detectedMeds.count)개의 약이 인식되었습니다")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)

                // 검색창
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("예: 타이레놀", text: $searchText)
                        .foregroundColor(.primary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                if filteredMeds.isEmpty {
                    Text("해당하는 약이 없습니다")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                        .padding(.horizontal)
                } else {
                    List(filteredMeds, id: \.self) { med in
                        let mapped = SupplementMapper.shared.mapToIngredient(med)

                        NavigationLink(destination: MedicationDetailView(medName: mapped)) {
                            Text(med)
                                .foregroundColor(.blue)
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .navigationTitle("인식된 약 목록")
        }
    }
}*/
