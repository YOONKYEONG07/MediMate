import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileSheet: View {
    @Environment(\.dismiss) var dismiss

    @Binding var nickname: String
    @Binding var birthday: Date
    @Binding var gender: String
    @Binding var height: String
    @Binding var weight: String
    @Binding var isSaved: Bool

    let genderOptions: [String]

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter
    }

    var body: some View {
        NavigationView {
            List {
                if isSaved {
                    Section(header: Text("개인정보")) {
                        MyInfoRow(title: "성별", value: gender)
                        MyInfoRow(title: "생년월일", value: dateFormatter.string(from: birthday))
                        MyInfoRow(title: "키", value: height + " cm")
                        MyInfoRow(title: "몸무게", value: weight + " kg")
                    }

                    Section {
                        Button("정보 수정하기") {
                            isSaved = false
                        }

                        Button("로그아웃") {
                            UserDefaults.standard.set(false, forKey: "isLoggedIn")
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }

                } else {
                    Section {
                        HStack {
                            Text("닉네임")
                            Spacer()
                            TextField("입력", text: $nickname)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("성별")
                            Spacer()
                            Picker("", selection: $gender) {
                                ForEach(genderOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }

                        HStack {
                            Text("생년월일")
                            Spacer()
                            DatePicker("", selection: $birthday, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "ko_KR"))
                        }

                        HStack {
                            Text("키 (cm)")
                            Spacer()
                            TextField("입력", text: $height)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("몸무게 (kg)")
                            Spacer()
                            TextField("입력", text: $weight)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    Section {
                        Button("저장") {
                            saveToFirestore()
                        }
                    }
                }
            }
            .navigationTitle("개인정보")
            .listStyle(InsetGroupedListStyle())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveToFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ 로그인된 사용자 없음")
            return
        }

        let db = Firestore.firestore()
        let ref = db.collection("users").document(uid)

        ref.setData([
            "nickname": nickname,
            "gender": gender,
            "height": height,
            "weight": weight,
            "birthday": dateFormatter.string(from: birthday)
        ], merge: true) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore에 저장 완료")
                isSaved = true
                dismiss()
            }
        }
    }
}
