import SwiftUI

struct MedicationDetailView: View {
    var medName: String
    var previousScreenTitle: String = "약 사진 촬영"

    @Environment(\.presentationMode) var presentationMode
    @State private var isFavorited = false
    @State private var drugInfo: DrugInfo?
    @State private var supplementInfo: [String: String]? = nil
    @State private var isLoadingFailed: Bool? = nil

    @State private var selectedTab = 0

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
                            supplementDetailView(info: supplement)
                        }
                    } else if isLoadingFailed == true {
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
                SupplementInfoService.shared.fetchSupplementInfo(ingredient: mapped) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let info):
                            self.supplementInfo = info
                        case .failure:
                            self.supplementInfo = nil
                        }
                    }
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

    private func supplementDetailView(info: [String: String]) -> some View {
        let sortedInfo = info.sorted(by: { $0.key < $1.key }) // ✅ 뷰 바깥으로 이동

        return VStack(alignment: .leading, spacing: 20) {
            Text("영양제 정보")
                .font(.title3)
                .bold()
                .padding(.horizontal)

            ForEach(sortedInfo, id: \.key) { item in
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.key)
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text(item.value.isEmpty ? "정보 없음" : item.value)
                        .font(.body)
                        .foregroundColor(item.value.isEmpty ? .gray : .primary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                .padding(.horizontal)
            }
        }
    }


    private func fetchDrugDetails() {
        DrugInfoService.shared.fetchDrugInfo(drugName: medName) { item in
            DispatchQueue.main.async {
                self.drugInfo = item

                // 👉 약 정보도 없고, 영양제 정보도 없을 때만 실패 처리
                if item == nil && self.supplementInfo == nil {
                    self.isLoadingFailed = true
                } else {
                    self.isLoadingFailed = false
                }
            }
        }

    }

    private func updateFavorites() {
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

    private func loadFavoriteStatus() {
        let favorites = UserDefaults.standard.stringArray(forKey: "favoriteMeds") ?? []
        isFavorited = favorites.contains(medName)
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
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
            )
            .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
            .padding(.horizontal)
        }
    }

    struct SupplementInfoCard: View {
        var title: String
        var value: String

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.blue)
                Text(value.isEmpty ? "정보 없음" : value)
                    .font(.body)
                    .foregroundColor(value.isEmpty ? .gray : .primary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
            .padding(.horizontal)
        }
    }
}
