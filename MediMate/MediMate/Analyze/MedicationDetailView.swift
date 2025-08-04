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
    @State private var gptFallbackText: String? = nil
    @State private var parsedGPTInfo: [String: String]? = nil

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
                    if let info = drugInfo {
                        drugDetailTabs(info: info)
                    } else if let supplement = supplementInfo {
                        if supplement.isEmpty {
                            errorView()
                        } else {
                            supplementInfoCardView(info: supplement)
                        }
                    } else if let parsed = parsedGPTInfo {
                        gptParsedInfoTabs(info: parsed)
                    } else if isLoadingFailed == true {
                        errorView()
                    } else if drugInfo == nil && supplementInfo == nil && parsedGPTInfo == nil {
                        errorView()
                    } else {
                        ProgressView("정보를 불러오는 중...")
                    }


                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
            .onAppear {
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
                                }
                            case .failure:
                                self.supplementInfo = [:]
                                if drugInfo == nil {
                                    fetchFromGPT()
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
                    // 🔽 요기 수정!
                    self.parsedGPTInfo = info
                case .failure(_):
                    self.parsedGPTInfo = ["효능": "AI 정보를 불러오지 못했습니다."]
                }
            }
        }
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
                if item == nil && supplementInfo == nil && parsedGPTInfo == nil {
                    self.isLoadingFailed = true
                } else {
                    self.isLoadingFailed = false
                }
            }
        }
    }
    
    private func fetchGPTFallbackInfo() {
        MedGPTService.shared.fetchSupplementInfoFromGPT(query: medName) { result in
            DispatchQueue.main.async {
                self.parsedGPTInfo = result

                // ✅ GPT까지 시도한 후, 결과가 없을 때만 실패 처리
                if self.drugInfo == nil && self.supplementInfo == nil && self.parsedGPTInfo == nil {
                    self.isLoadingFailed = true
                } else {
                    self.isLoadingFailed = false
                }
            }
        }
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
    private func parseGPTResponse(_ response: String) -> [String: String] {
        var result: [String: String] = [:]
        let categories = ["효능", "복용법", "주의사항", "상호작용", "보관법"]

        for category in categories {
            if let range = response.range(of: "\(category):") {
                let start = range.upperBound
                let remaining = response[start...]
                let nextCategory = categories.first { $0 != category && remaining.contains("\($0):") }

                let end = nextCategory.flatMap { remaining.range(of: "\($0):")?.lowerBound } ?? response.endIndex
                let value = response[start..<end].trimmingCharacters(in: .whitespacesAndNewlines)
                result[category] = value
            }
        }

        return result
    }

    private func loadFavoriteStatus() {
        let uid = Auth.auth().currentUser?.uid ?? "unknown"
        let key = "favoriteMeds_\(uid)"
        let favorites = UserDefaults.standard.stringArray(forKey: key) ?? []
        isFavorited = favorites.contains(medName)
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

    private func gptInfoView(text: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI 약사 정보")
                .font(.title3)
                .bold()
                .padding(.horizontal)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                .padding(.horizontal)
        }
        .padding(.top, 8)
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
