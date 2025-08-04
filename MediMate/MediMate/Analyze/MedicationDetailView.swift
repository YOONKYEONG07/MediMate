import SwiftUI
import FirebaseAuth

struct MedicationDetailView: View {
    var medName: String
    var previousScreenTitle: String = "약 사진 촬영"

    @Environment(\.presentationMode) var presentationMode
    @State private var isFavorited = false
    @State private var drugInfo: DrugInfo?
    @State private var supplementInfo: [String: String]? = nil
    @State private var isLoadingFailed: Bool? = nil
    @State private var selectedTab = 0
    @State private var parsedGPTInfo: [String: String]? = nil
    @State private var isLoading: Bool = true

    var body: some View {
        VStack {
            // 🔙 뒤로가기
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Label(previousScreenTitle, systemImage: "chevron.left")
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.horizontal)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 💊 약 이름 + 하트 + 이미지
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .center, spacing: 8) {
                                Text(medName)
                                    .font(.system(size: 32, weight: .bold))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                Button(action: {
                                    isFavorited.toggle()
                                    updateFavorites()
                                }) {
                                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        Spacer()

                        if let imageUrl = drugInfo?.itemImage, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 130, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                case .failure(_):
                                    Image(systemName: "photo")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.gray)
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "pills.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 10)

                    // ✅ 약 정보 or 영양제 정보
                    if isLoading {
                        ProgressView("정보를 불러오는 중...")
                    } else if isLoadingFailed == true {
                        errorView()
                    } else if let info = drugInfo {
                        drugDetailTabs(info: info)
                    } else if let supplement = supplementInfo, !supplement.isEmpty {
                        supplementInfoCardView(info: supplement)
                    } else if let parsed = parsedGPTInfo {
                        gptParsedInfoTabs(info: parsed)
                    }
                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
            .onAppear {
                isLoading = true
                isLoadingFailed = nil
                loadFavoriteStatus()
                fetchDrugDetails()

                let mapped = SupplementMapper.shared.mapToIngredient(medName)
                if supplementInfo == nil {
                    SupplementInfoService.shared.fetchSupplementInfo(ingredient: mapped) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let info):
                                self.supplementInfo = info
                                if info.isEmpty && drugInfo == nil {
                                    fetchFromGPT()
                                } else {
                                    isLoading = false
                                }
                            case .failure:
                                self.supplementInfo = [:]
                                if drugInfo == nil {
                                    fetchFromGPT()
                                } else {
                                    isLoading = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func fetchFromGPT() {
        MedGPTService.shared.fetchGPTInfo(for: medName) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let info):
                    let combinedText = info.values.joined(separator: " ")
                    // ✅ ➊ 키워드가 너무 적거나 ➋ 약 관련 단어가 없음 → 실패 처리
                    if combinedText.count < 30 || !containsMedicalKeywords(text: combinedText) {
                        self.parsedGPTInfo = nil
                        self.isLoadingFailed = true
                    } else {
                        self.parsedGPTInfo = info
                        self.isLoadingFailed = false
                    }
                case .failure(_):
                    self.parsedGPTInfo = nil
                    self.isLoadingFailed = true
                }
                self.isLoading = false
            }
        }
    }

    // ✅ 키워드 기반 검증 함수
    private func containsMedicalKeywords(text: String) -> Bool {
        let keywords = ["복용", "약", "성분", "효능", "건강기능식품", "부작용", "용량", "질병", "보관", "주의사항"]
        return keywords.contains { text.localizedCaseInsensitiveContains($0) }
    }


    private func updateFavorites() {
        let uid = Auth.auth().currentUser?.uid ?? "unknown"
        let key = "favoriteMeds_\(uid)"
        var favorites = UserDefaults.standard.stringArray(forKey: key) ?? []
        if isFavorited {
            if !favorites.contains(medName) {
                favorites.append(medName)
            }
        } else {
            favorites.removeAll { $0 == medName }
        }
        UserDefaults.standard.set(favorites, forKey: key)
    }

    private func fetchDrugDetails() {
        DrugInfoService.shared.fetchDrugInfo(drugName: medName) { item in
            DispatchQueue.main.async {
                self.drugInfo = item
            }
        }
    }

    private func loadFavoriteStatus() {
        let uid = Auth.auth().currentUser?.uid ?? "unknown"
        let key = "favoriteMeds_\(uid)"
        let favorites = UserDefaults.standard.stringArray(forKey: key) ?? []
        isFavorited = favorites.contains(medName)
    }

    private func drugDetailTabs(info: DrugInfo) -> some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                Label("제품명", systemImage: "pills")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text(info.itemName ?? "정보 없음")
                    .font(.body)
                    .foregroundColor(.primary)

                Divider()

                Label("제조사", systemImage: "building")
                    .foregroundColor(.blue)
                    .font(.headline)
                Text(info.entpName ?? "정보 없음")
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
            .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
            .padding(.horizontal)

            Picker("정보 선택", selection: $selectedTab) {
                Text("효능").tag(0)
                Text("복용법").tag(1)
                Text("주의사항").tag(2)
                Text("상호작용").tag(3)
                Text("보관법").tag(4)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 4)

            Group {
                switch selectedTab {
                case 0: DrugInfoCard(title: "효능", icon: "cross.case", text: info.efcyQesitm)
                case 1: DrugInfoCard(title: "복용법", icon: "clock", text: info.useMethodQesitm)
                case 2:
                    let warning = [info.atpnWarnQesitm, info.atpnQesitm].compactMap { $0 }.joined(separator: "\n")
                    DrugInfoCard(title: "주의사항", icon: "exclamationmark.triangle", text: warning)
                case 3: DrugInfoCard(title: "상호작용", icon: "arrow.triangle.branch", text: info.intrcQesitm)
                case 4: DrugInfoCard(title: "보관법", icon: "tray", text: info.depositMethodQesitm)
                default: EmptyView()
                }
            }
        }
    }

    private func supplementInfoCardView(info: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("영양제 정보")
                .font(.title3)
                .bold()
                .padding(.horizontal)

            ForEach(Array(info.sorted(by: { $0.key < $1.key })), id: \.0) { (key, value) in
                VStack(alignment: .leading, spacing: 8) {
                    Text(key)
                        .font(.headline)
                        .foregroundColor(.blue)

                    Text(value.isEmpty || value == "-" ? "정보 없음" : value)
                        .font(.body)
                        .foregroundColor(value.isEmpty || value == "-" ? .gray : .primary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                .padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    private func gptParsedInfoTabs(info: [String: String]) -> some View {
        VStack {
            Picker("정보 선택", selection: $selectedTab) {
                Text("효능").tag(0)
                Text("복용법").tag(1)
                Text("주의사항").tag(2)
                Text("상호작용").tag(3)
                Text("보관법").tag(4)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            Group {
                switch selectedTab {
                case 0: DrugInfoCard(title: "효능", icon: "cross.case", text: info["효능"])
                case 1: DrugInfoCard(title: "복용법", icon: "clock", text: info["복용법"])
                case 2: DrugInfoCard(title: "주의사항", icon: "exclamationmark.triangle", text: info["주의사항"])
                case 3: DrugInfoCard(title: "상호작용", icon: "arrow.triangle.branch", text: info["상호작용"])
                case 4: DrugInfoCard(title: "보관법", icon: "tray", text: info["보관법"])
                default: EmptyView()
                }
            }
        }
    }

    private func errorView() -> some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "xmark.octagon.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.red)
                Text("등록되지 않은 항목입니다.")
                    .font(.headline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.top, 40)
    }

    struct DrugInfoCard: View {
        var title: String
        var icon: String
        var text: String?

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundColor(.blue)

                Text(text?.isEmpty == false ? text! : "정보 없음")
                    .font(.body)
                    .foregroundColor(text?.isEmpty == false ? .primary : .gray)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))
            .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
            .padding(.horizontal)
        }
    }
}
