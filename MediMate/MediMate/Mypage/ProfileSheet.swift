import SwiftUI

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
                            dismiss()  // ✅ 팝업 닫기
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
                            isSaved = true
                            UserDefaults.standard.set(nickname, forKey: "nickname")
                            UserDefaults.standard.set(gender, forKey: "gender")
                            UserDefaults.standard.set(height, forKey: "height")
                            UserDefaults.standard.set(weight, forKey: "weight")
                            UserDefaults.standard.set(dateFormatter.string(from: birthday), forKey: "birthday")
                            dismiss()  // ✅ 저장 후 팝업 닫기
                        }
                    }
                }
            }
            .navigationTitle("개인정보")
            .listStyle(InsetGroupedListStyle())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()  // ✅ 닫기 버튼도 수정
                    }
                }
            }
        }
    }
}
