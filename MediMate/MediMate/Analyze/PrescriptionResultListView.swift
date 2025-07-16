import SwiftUI

struct PrescriptionResultListView: View {
    let detectedMeds: [String]
    @State private var searchText = ""

    // 검색어에 따라 필터링된 결과 반환
    var filteredMeds: [String] {
        if searchText.isEmpty {
            return detectedMeds
        } else {
            return detectedMeds.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 안내 문구 (변경됨)
            Text("인식된 약 목록에서 원하는 약을 찾아보세요")
                .font(.headline)
                .padding(.horizontal)

            // 검색창 (디자인 통일)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("예: 타이레놀", text: $searchText)
                    .font(.body)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .padding(.horizontal)

            // 검색 결과 리스트
            ScrollView {
                VStack(spacing: 8) {
                    if filteredMeds.isEmpty {
                        Text("검색 결과가 없어요 😢")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(filteredMeds, id: \.self) { med in
                            NavigationLink(destination: MedicationDetailView(medName: med, previousScreenTitle: "인식된 약 목록")) {
                                HStack {
                                    Text(med)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.top)
        .navigationTitle("인식된 약 목록")
    }
}
