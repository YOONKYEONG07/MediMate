import SwiftUI

struct MedicationDetailView: View {
    var medName: String
    var previousScreenTitle: String = "약 사진 촬영" // ✅ 뒤로가기 버튼에 표시될 텍스트 (기본값 지정)

    @Environment(\.presentationMode) var presentationMode
    @State private var isFavorited = false

    var body: some View {
        VStack(spacing: 0) {
            // ✅ 커스텀 헤더
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(previousScreenTitle) // ✅ 전달받은 텍스트로 설정
                    }
                    .foregroundColor(.blue)
                    .font(.headline)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))

            Divider()

            // ✅ 내용 영역
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
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
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            HStack {
                                Label("하료저", systemImage: "cross.case.fill")
                                Text("OTC")
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }

                        Spacer()

                        Image("pill_image")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Divider()

                    GroupBox(label: Label("성분", systemImage: "pills")) {
                        VStack(alignment: .leading) {
                            Text("• 아세트아미노펜 (해열/진통)")
                            Text("• 클로르페니라민 (항히스타민)")
                        }
                    }

                    GroupBox(label: Label("효능", systemImage: "cross.case")) {
                        Text("감기 증상 완화 (콧물, 발열 등)")
                    }

                    GroupBox(label: Label("복용법", systemImage: "capsule.portrait")) {
                        Text("하루 3회, 1회 1정씩 복용")
                    }

                    HStack {
                        GroupBox(label: Label("식전/식후 여부", systemImage: "clock")) {
                            Text("식후 30분 이내에 복용")
                        }
                        GroupBox(label: Label("1일 복용횟수", systemImage: "number")) {
                            Text("1일 최대 3정 (4시간 간격)")
                        }
                    }

                    GroupBox(label: Label("주의사항", systemImage: "exclamationmark.triangle")) {
                        Text("졸음 유발 가능성 있음, 운전 주의")
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true) // ✅ 시스템 뒤로가기 버튼 숨김
        .toolbar(.hidden, for: .navigationBar) // ✅ 기본 네비게이션 바 숨김
        // .navigationTitle("약 성분 분석 결과") // ❌ 시스템 타이틀 제거
        .onAppear {
            loadFavoriteStatus()
        }
    }

    // MARK: - 즐겨찾기 저장 / 불러오기
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
