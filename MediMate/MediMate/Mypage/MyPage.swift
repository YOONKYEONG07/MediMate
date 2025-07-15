import SwiftUI

struct MyPage: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false

    @State private var nickname = ""
    @State private var birthday = Date()
    @State private var gender = "선택 안 함"
    @State private var height = ""
    @State private var weight = ""
    @State private var isSaved = false
    @State private var showSheet = false

    let genderOptions = ["남자", "여자"]

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter
    }

    var body: some View {
        NavigationView {
            List {
                // 🔹 프로필
                Section {
                    Button {
                        showSheet = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(profileImageName())
                                .resizable()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())

                            VStack(alignment: .leading) {
                                Text(nickname.isEmpty ? "닉네임 없음" : nickname)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("마이페이지")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }

                // ⭐ 즐겨찾는 약
                Section {
                    NavigationLink(destination: FavoriteDrugsView()) {
                        Label {
                            Text("즐겨찾는 약")
                        } icon: {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // 🔔 알림 설정
                Section {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("알림 설정", systemImage: "bell.fill")
                    }
                }





                // ⚙️ 환경설정
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("환경설정", systemImage: "gearshape")
                    }
                }

                // 🚪 로그아웃
                Section {
                    Button("로그아웃") {
                        isLoggedIn = false
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("마이페이지")
            .listStyle(InsetGroupedListStyle())
            .onAppear {
                loadSavedData()
            }
            .sheet(isPresented: $showSheet) {
                ProfileSheet(
                    nickname: $nickname,
                    birthday: $birthday,
                    gender: $gender,
                    height: $height,
                    weight: $weight,
                    isSaved: $isSaved,
                    genderOptions: genderOptions
                )
            }
        }
    }

    private func profileImageName() -> String {
        switch gender {
        case "남자": return "blue_pill"
        case "여자": return "pink_pill"
        default: return "person.crop.circle.fill"
        }
    }

    private func loadSavedData() {
        nickname = UserDefaults.standard.string(forKey: "nickname") ?? ""
        gender = UserDefaults.standard.string(forKey: "gender") ?? "선택 안 함"
        height = UserDefaults.standard.string(forKey: "height") ?? ""
        weight = UserDefaults.standard.string(forKey: "weight") ?? ""
        isSaved = !nickname.isEmpty

        if let birthdayString = UserDefaults.standard.string(forKey: "birthday"),
           let savedDate = dateFormatter.date(from: birthdayString) {
            birthday = savedDate
        }
    }
}
