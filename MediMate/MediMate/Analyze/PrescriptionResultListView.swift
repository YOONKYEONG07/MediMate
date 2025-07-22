import SwiftUI

struct PrescriptionResultListView: View {
    let detectedMeds: [String]  // ✅ 외부에서 값을 전달받도록 변경
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
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            
            // 필터된 약 리스트
            if filteredMeds.isEmpty {
                Text("해당하는 약이 없습니다")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.horizontal)
            } else {
                List(filteredMeds, id: \.self) { med in
                    NavigationLink(destination: MedicationDetailView(medName: med)) {
                        Text(med)
                            .foregroundColor(.blue)
                    }
                }
                .listStyle(.plain)
            }
            
            Spacer()
            
                .padding(.top)
                .navigationTitle("인식된 약 목록")
        }
    }
    
}
