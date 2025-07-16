import SwiftUI

struct TextSearchView: View {
    @State private var searchText: String = ""
    
    // 예시 데이터
    let frequentMeds = ["타이레놀", "게보린", "판콜에이"]
    let recentMeds = ["신일이부프로펜", "서스펜", "알마겔"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 1. 타이틀
            Text("검색할 약의 이름을 입력해주세요")
                .font(.title3)
                .bold()
                .padding(.top)
            
            // ✅ 2. 통일된 검색창
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("예: 타이레놀", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal, 0)
            
            // 3. 자주 찾는 약
            if !frequentMeds.isEmpty {
                Text("자주 찾는 약")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(frequentMeds, id: \.self) { med in
                            Text(med)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            // 4. 최근 검색한 약
            if !recentMeds.isEmpty {
                Text("최근 검색한 약")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recentMeds, id: \.self) { med in
                        Text(med)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
            }

            Spacer()
            
            // 5. 검색 버튼
            NavigationLink(destination: MedicationDetailView(medName: searchText)) {
                Text("약 성분 분석하기")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .disabled(searchText.isEmpty)
        }
        .padding()
        .navigationTitle("텍스트로 검색")
    }
}
