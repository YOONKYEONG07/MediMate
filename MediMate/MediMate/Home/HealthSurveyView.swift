import SwiftUI

struct HealthSurveyView: View {
    // 🔵 설문 응답 변수들
    @State private var gender: String = ""
    @State private var ageGroup: String = ""
    @State private var healthConcerns: [String] = []
    @State private var pregnancyStatus: String = ""
    @State private var alcohol: String = ""
    @State private var outdoorActivity: String = ""
    @State private var fatigueLevel: String = ""
    @State private var sensitiveStomach: String = ""
    @State private var existingDiseases: String = ""
    @State private var currentMedications: String = ""
    @State private var hadSupplementIssues: Bool? = nil

    // 🔸 선택지 배열들
    let genders = ["남성", "여성", "기타"]
    let ageGroups = ["10대", "20대", "30대", "40대", "50대 이상"]
    let pregnancyOptions = ["준비 중", "임신 중", "수유 중", "해당 없음"]
    let yesNoOptions = ["예", "아니오"]
    let fatigueOptions = ["낮다", "보통", "높다"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // 1. 성별
                SectionTitle("성별을 선택해주세요")
                HorizontalButtonSelector(options: genders, selection: $gender)

                // 2. 연령대
                SectionTitle("연령대를 선택해주세요")
                Picker("연령대", selection: $ageGroup) {
                    ForEach(ageGroups, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)

                // 3. 건강 고민
                SectionTitle("건강 고민을 최대 5개까지 선택해주세요")
                HealthConcernSelector(selectedConcerns: $healthConcerns)

                // 4. 임신 여부 (여성만)
                if gender == "여성" {
                    SectionTitle("임신 여부를 선택해주세요")
                    HorizontalButtonSelector(options: pregnancyOptions, selection: $pregnancyStatus)
                }

                // 5. 음주 여부
                SectionTitle("평소 음주를 하시나요?")
                HorizontalButtonSelector(options: yesNoOptions, selection: $alcohol)

                // 6. 야외활동
                SectionTitle("야외활동을 자주 하시나요?")
                HorizontalButtonSelector(options: yesNoOptions, selection: $outdoorActivity)

                // 7. 피로도
                SectionTitle("최근 신체 피로도는 어떤가요?")
                HorizontalButtonSelector(options: fatigueOptions, selection: $fatigueLevel)

                // 8. 장/위 예민
                SectionTitle("장과 위가 예민한 편인가요?")
                HorizontalButtonSelector(options: yesNoOptions, selection: $sensitiveStomach)

                // 9. 앓고 있는 질환
                SectionTitle("앓고 있는 질환이 있다면 입력해주세요")
                TextField("ex) 고혈압, 당뇨", text: $existingDiseases)
                    .textFieldStyle(.roundedBorder)

                // 10. 복용 중인 약
                SectionTitle("복용 중인 약이 있다면 입력해주세요")
                TextField("ex) 타이레놀, 센트룸", text: $currentMedications)
                    .textFieldStyle(.roundedBorder)

                // 11. 부작용 경험
                SectionTitle("영양제 복용 후 불편한 증상을 느낀 적이 있나요?")
                HStack(spacing: 16) {
                    Button("O") {
                        hadSupplementIssues = true
                    }
                    .choiceStyle(isSelected: hadSupplementIssues == true)

                    Button("X") {
                        hadSupplementIssues = false
                    }
                    .choiceStyle(isSelected: hadSupplementIssues == false)
                }

                // 12. 제출 버튼
                Button(action: {
                    let prompt = surveyToPromptText()
                    print("GPT 프롬프트:\n\(prompt)")
                    // → GPT API 호출 예정
                }) {
                    Text("제출하고 추천 받기")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("건강 상태 체크")
    }
}

extension HealthSurveyView {
    func surveyToPromptText() -> String {
        var lines: [String] = []

        if !gender.isEmpty {
            lines.append("사용자는 \(ageGroup) \(gender)입니다.")
        }
        if !healthConcerns.isEmpty {
            lines.append("건강 고민은 \(healthConcerns.joined(separator: ", "))입니다.")
        }
        if gender == "여성" && !pregnancyStatus.isEmpty {
            lines.append("임신 관련 상태는 '\(pregnancyStatus)'입니다.")
        }
        if !alcohol.isEmpty {
            lines.append("음주 여부: \(alcohol)입니다.")
        }
        if !outdoorActivity.isEmpty {
            lines.append("야외 활동 여부: \(outdoorActivity)입니다.")
        }
        if !fatigueLevel.isEmpty {
            lines.append("최근 신체 피로도는 '\(fatigueLevel)'입니다.")
        }
        if !sensitiveStomach.isEmpty {
            lines.append("장과 위가 예민한 편: \(sensitiveStomach)입니다.")
        }
        if !existingDiseases.isEmpty {
            lines.append("앓고 있는 질환: \(existingDiseases)입니다.")
        }
        if !currentMedications.isEmpty {
            lines.append("복용 중인 약: \(currentMedications)입니다.")
        } else {
            lines.append("복용 중인 약은 없습니다.")
        }
        if let hadIssues = hadSupplementIssues {
            lines.append("영양제 복용 후 불편함을 느낀 적이 \(hadIssues ? "있습니다." : "없습니다.")")
        }

        return lines.joined(separator: "\n")
    }
}

struct SectionTitle: View {
    var text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.headline)
            .fontWeight(.semibold)
    }
}

struct HorizontalButtonSelector: View {
    let options: [String]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection = option
                }
                .choiceStyle(isSelected: selection == option)
            }
        }
    }
}

extension View {
    func choiceStyle(isSelected: Bool) -> some View {
        self
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .black)
            .cornerRadius(10)
    }
}
