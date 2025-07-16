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
        VStack {
            // 🔍 검색창
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("약 이름을 입력하세요", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding([.horizontal, .top])

            // 📋 필터링된 약 리스트 or 안내 문구
            if filteredMeds.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("검색 결과가 없습니다.")
                        .foregroundColor(.gray)
                }
                .padding(.top, 100)
            } else {
                List(filteredMeds, id: \.self) { med in
                    NavigationLink(destination: MedicationDetailView(medName: med, previousScreenTitle: "인식된 약 목록")) {
                        Text(med)
                    }
                }
                .listStyle(.plain)
            }

            Spacer()
        }
        .navigationTitle("인식된 약 목록")
    }
}
