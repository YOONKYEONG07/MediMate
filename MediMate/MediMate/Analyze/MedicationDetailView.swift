import SwiftUI

struct MedicationDetailView: View {
    var medName: String
    var previousScreenTitle: String = "약 사진 촬영"

    @Environment(\.presentationMode) var presentationMode
    @State private var isFavorited = false

    let alternativeMeds: [String: [String]] = [
        "타이레놀": ["게보린", "부루펜"],
        "알마겔": ["겔포스", "마그밀"],
        "지르텍": ["클라리틴", "알러지컷"]
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ✅ 커스텀 뒤로가기 버튼
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(previousScreenTitle)
                    }
                    .foregroundColor(.blue)
                    .font(.headline)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            // ✅ 본문 콘텐츠
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(medName)
                                    .font(.largeTitle)
                                    .bold()

                                Button(action: {
                                    isFavorited.toggle()
                                    updateFavorites()
                                }) {
                                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                                        .resizable()
                                        .frame(width: 24, height: 22)
                                        .foregroundColor(.blue)
                                        .padding(.leading, 4)
                                }
                            }

                            Text("이 약은 감기 증상을 완화해주는 일반의약품입니다")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()

                        Image("pill_image")
                            .resizable()
                            .frame(width: 150, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 4)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    }

                    Divider()

                    GroupBox(label: Label("성분", systemImage: "pills")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• 아세트아미노펜 (해열/진통)")
                            Text("• 클로르페니라민 (항히스타민)")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox(label: Label("효능", systemImage: "cross.case")) {
                        Text("감기 증상 완화 (콧물, 발열 등)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    GroupBox(label: Label("복용법", systemImage: "capsule.portrait")) {
                        Text("하루 3회, 1회 1정씩 복용")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 16) {
                        GroupBox(label: Label("식전/식후 여부", systemImage: "clock")) {
                            Text("식후 30분 이내에 복용")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        GroupBox(label: Label("1일 복용횟수", systemImage: "number")) {
                            Text("1일 최대 3정 (4시간 간격)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    GroupBox(label: Label("주의사항", systemImage: "exclamationmark.triangle")) {
                        Text("졸음 유발 가능성 있음, 운전 주의")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let alternatives = alternativeMeds[medName], !alternatives.isEmpty {
                        GroupBox(label: Label("💡 대체 가능한 약", systemImage: "arrow.2.squarepath")) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(alternatives, id: \.self) { alt in
                                    Text("• \(alt)")
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        }
        // ✅ 시스템 네비게이션바 완전 제거!
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            loadFavoriteStatus()
        }
    }

    // MARK: - 즐겨찾기 저장/불러오기
    func updateFavorites() {
        var favorites = UserDefaults.standard.stringArray(forKey: "favoriteMeds") ?? []
        if isFavorited {
            if !favorites.contains(medName) {
                favorites.append(medName)
            }
        } else {
            favorites.removeAll { $0 == medName }
        }
        UserDefaults.standard.set(favorites, forKey: "favoriteMeds")
    }

    func loadFavoriteStatus() {
        let favorites = UserDefaults.standard.stringArray(forKey: "favoriteMeds") ?? []
        isFavorited = favorites.contains(medName)
    }
}
