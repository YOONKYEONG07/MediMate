import SwiftUI

struct MedicationDetailView: View {
    var medName: String
    var previousScreenTitle: String = "약 사진 촬영"
    
    @Environment(\.presentationMode) var presentationMode
    @State private var isFavorited = false
    @State private var drugInfo: DrugInfo?
    
    @State private var selectedTab = 0
    @State private var isLoadingFailed = false
    
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
                    
                    // ✅ 약 정보 탭 뷰
                    if let info = drugInfo {
                        // 📦 제품 정보 카드 (제품명 + 제조사)
                        VStack(alignment: .leading, spacing: 12) {
                            Label("제품명", systemImage: "pills")
                                .foregroundColor(.blue)
                                .font(.headline)

                            let name = info.itemName ?? ""
                            Text(name.isEmpty ? "정보 없음" : name)
                                .font(.body)
                                .foregroundColor(name.isEmpty ? .gray : .primary)

                            Divider()

                            Label("제조사", systemImage: "building")
                                .foregroundColor(.blue)
                                .font(.headline)

                            let entpName = info.entpName ?? ""
                            Text(entpName.isEmpty ? "정보 없음" : entpName)
                                .font(.body)
                                .foregroundColor(entpName.isEmpty ? .gray : .primary)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
                        .padding(.horizontal)

                        // 🔘 Segmented Picker
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
                            case 0:
                                DrugInfoCard(title: "효능", icon: "cross.case", text: info.efcyQesitm)
                            case 1:
                                DrugInfoCard(title: "복용법", icon: "clock", text: info.useMethodQesitm)
                            case 2:
                                let warning = [info.atpnWarnQesitm, info.atpnQesitm].compactMap { $0 }.joined(separator: "\n")
                                DrugInfoCard(title: "주의사항", icon: "exclamationmark.triangle", text: warning)
                            case 3:
                                DrugInfoCard(title: "상호작용", icon: "arrow.triangle.branch", text: info.intrcQesitm)
                            case 4:
                                DrugInfoCard(title: "보관법", icon: "tray", text: info.depositMethodQesitm)
                            default:
                                EmptyView()
                            }
                        }

                    } else if isLoadingFailed {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "xmark.octagon.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.red)
                                Text("등록되지 않은 약입니다.")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                        .padding(.top, 40)
                    } else {
                        ProgressView("약 정보를 불러오는 중...")
                    }
                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
            .onAppear {
                loadFavoriteStatus()
                fetchDrugDetails()
            }
        }
    }

    private func fetchDrugDetails() {
        DrugInfoService.shared.fetchDrugInfo(drugName: medName) { item in
            DispatchQueue.main.async {
                if let item = item {
                    self.drugInfo = item
                    self.isLoadingFailed = false
                } else {
                    self.isLoadingFailed = true
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
                    .fill(Color.white)
            )
            .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
            .padding(.horizontal)
        }
    }
}
