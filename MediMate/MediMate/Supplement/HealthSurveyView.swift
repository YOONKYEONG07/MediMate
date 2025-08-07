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
    @State private var isLoading = false
    @State private var gptResult: String? = nil
    @State private var navigateToResult = false

    // 🔸 선택지 배열들
    let genders = ["남성", "여성"]
    let ageGroups = ["10대", "20대", "30대", "40대", "50대", "60대", "70대 이상"]
    let pregnancyOptions = ["준비 중", "임신 중", "수유 중", "해당 없음"]
    let yesNoOptions = ["예", "아니오"]
    let fatigueOptions = ["낮다", "보통", "높다"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    SectionTitle("성별을 선택해주세요")
                    HorizontalButtonSelector(options: genders, selection: $gender)

                    SectionTitle("연령대를 선택해주세요")
                    Menu {
                        ForEach(ageGroups, id: \.self) { age in
                            Button(age) {
                                ageGroup = age
                            }
                        }
                    } label: {
                        HStack {
                            Text(ageGroup.isEmpty ? "선택" : ageGroup)
                                .foregroundColor(ageGroup.isEmpty ? .gray : .primary)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }

                    SectionTitle("건강 고민을 최대 5개까지 선택해주세요")
                    HealthConcernSelector(selectedConcerns: $healthConcerns)

                    if gender == "여성" {
                        SectionTitle("임신 여부를 선택해주세요")
                        HorizontalButtonSelector(options: pregnancyOptions, selection: $pregnancyStatus)
                    }

                    SectionTitle("평소 음주를 하시나요?")
                    HorizontalButtonSelector(options: yesNoOptions, selection: $alcohol)

                    SectionTitle("야외활동을 자주 하시나요?")
                    HorizontalButtonSelector(options: yesNoOptions, selection: $outdoorActivity)

                    SectionTitle("최근 신체 피로도는 어떤가요?")
                    HorizontalButtonSelector(options: fatigueOptions, selection: $fatigueLevel)

                    SectionTitle("장과 위가 예민한 편인가요?")
                    HorizontalButtonSelector(options: yesNoOptions, selection: $sensitiveStomach)

                    SectionTitle("앓고 있는 질환이 있다면 입력해주세요")
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemGray5))
                        if existingDiseases.isEmpty {
                            Text("ex) 고혈압, 당뇨")
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                        }
                        TextField("", text: $existingDiseases)
                            .padding(12)
                            .foregroundColor(.primary)
                    }

                    SectionTitle("복용 중인 약이 있다면 입력해주세요")
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemGray5))
                        if currentMedications.isEmpty {
                            Text("ex) 타이레놀, 센트룸")
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                        }
                        TextField("", text: $currentMedications)
                            .padding(12)
                            .foregroundColor(.primary)
                    }

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

                    Button(action: {
                        isLoading = true
                        let prompt = surveyToPromptText()
                        print("GPT 프롬프트:\n\(prompt)")

                        SupplementGPTService.shared.sendRecommendationPrompt(prompt: prompt) { result in
                            DispatchQueue.main.async {
                                isLoading = false
                                gptResult = result
                                navigateToResult = true
                            }
                        }
                    }) {
                        if isLoading {
                            ProgressView("AI가 추천 중입니다...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("제출하고 추천 받기")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isLoading)
                    .padding(.top)

                    NavigationLink(
                        destination: Group {
                            if let result = gptResult {
                                SupplementResultView(resultText: result)
                            }
                        },
                        isActive: $navigateToResult
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
                .padding()
            }
            .navigationTitle("건강 상태 체크")
        }
    }

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

// 🔧 선택 UI 컴포넌트들
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
            .background(
                isSelected
                ? Color.accentColor
                : Color(UIColor.systemGray5)
            )
            .foregroundColor(
                isSelected ? .white : .primary
            )
            .cornerRadius(10)
    }
}
