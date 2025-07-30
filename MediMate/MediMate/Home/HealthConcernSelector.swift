import SwiftUI

struct HealthConcernSelector: View {
    @Binding var selectedConcerns: [String]
    
    let allConcerns = [
        "간 건강", "활력/피로", "체지방 관리",
        "혈당 관리", "혈압 관리", "뇌 건강", "눈 건강",
        "뼈 건강", "위 건강", "장 건강", "관절/근육", "면역력",
        "모발/손톱", "수면", "스트레스", "피부", "남성 건강", "여성 건강"
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(allConcerns, id: \.self) { concern in
                Button(concern) {
                    if selectedConcerns.contains(concern) {
                        selectedConcerns.removeAll { $0 == concern }
                    } else if selectedConcerns.count < 5 {
                        selectedConcerns.append(concern)
                    }
                }
                .choiceStyle(isSelected: selectedConcerns.contains(concern))
            }
        }
    }
}
