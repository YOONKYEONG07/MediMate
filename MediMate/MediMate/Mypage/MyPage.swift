import SwiftUI

struct MyPage: View {
    @State private var nickname = ""
    @State private var birthday = Date()
    @State private var gender = "선택 안 함"
    @State private var height = ""
    @State private var weight = ""
    @State private var isSaved = false

    let genderOptions = ["남자", "여자"]

    // 날짜 포맷
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
                    // 저장된 요약 화면
                    Section {
                        HStack(spacing: 16) {
                            Image(profileImageName())
                                .resizable()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(nickname)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text("마이페이지")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
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
                                                }
                                                .foregroundColor(.red)

                        
                       
                    }
                

                } else {
                    // 입력 화면
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
                        }
                    }
                }
            }
            .navigationTitle("마이페이지")
            .listStyle(InsetGroupedListStyle())
        }
    }

  
    private func profileImageName() -> String {
        switch gender {
        case "남자":
            return "blue_pill"
        case "여자":
            return "pink_pill"
        default:
            return "person.crop.circle.fill" // 기본 이미지
        }
    }
}

struct MyInfoRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
