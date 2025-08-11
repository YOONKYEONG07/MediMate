import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MyPage: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @StateObject private var authVM = AuthViewModel()

    @State private var nickname = ""
    @State private var birthday = Date()
    @State private var gender = "선택 안 함"
    @State private var height = ""
    @State private var weight = ""
    @State private var isSaved = false
    @State private var showSheet = false

    // 탈퇴 관련 상태
    @State private var showDeleteConfirmation = false
    @State private var deleteErrorMessage = ""

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
                                Text("내 정보")
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

                Section {
                    NavigationLink(destination: FavoriteDrugsView()) {
                        Label("즐겨찾는 약", systemImage: "heart.fill")
                            .foregroundColor(.blue)
                    }
                }

                Section {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("알림 설정", systemImage: "bell")
                    }
                }

                Section {
                    NavigationLink(destination: NoticeView()) {
                        Label("공지사항", systemImage: "speaker.3")
                    }
                }

                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("환경설정", systemImage: "gearshape")
                    }
                }

                Section {
                    Button("로그아웃") {
                        logout()
                    }
                    .foregroundColor(.red)

                    Button("회원 탈퇴") {
                        showDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .alert("정말 탈퇴하시겠어요?", isPresented: $showDeleteConfirmation) {
                Button("탈퇴", role: .destructive) {
                    authVM.deleteGoogleUser { success, error in
                        if success {
                            logout()
                        } else {
                            deleteErrorMessage = error ?? "알 수 없는 오류"
                        }
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("모든 데이터가 삭제되며 복구할 수 없습니다.")
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
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ 로그인된 사용자 없음")
            return
        }

        let db = Firestore.firestore()
        let ref = db.collection("users").document(uid)

        ref.getDocument { document, error in
            if let error = error {
                print("❌ Firestore 불러오기 오류: \(error.localizedDescription)")
                return
            }

            guard let data = document?.data() else { return }

            self.nickname = data["nickname"] as? String ?? ""
            self.gender = data["gender"] as? String ?? "선택 안 함"
            self.height = data["height"] as? String ?? ""
            self.weight = data["weight"] as? String ?? ""
            if let birthdayString = data["birthday"] as? String,
               let date = dateFormatter.date(from: birthdayString) {
                self.birthday = date
            }

            self.isSaved = !nickname.isEmpty
        }
    }

    private func logout() {
        isLoggedIn = false
        nickname = ""
        birthday = Date()
        gender = "선택 안 함"
        height = ""
        weight = ""
        isSaved = false
        showSheet = false

        do {
            try Auth.auth().signOut()
        } catch {
            print("로그아웃 실패: \(error.localizedDescription)")
        }
    }
}
