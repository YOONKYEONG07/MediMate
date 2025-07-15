import Foundation

struct HealthQuestion: Identifiable {
    let id = UUID()
    let question: String
}

let sampleQuestions: [HealthQuestion] = [
    HealthQuestion(question: "감기약과 영양제 같이 먹어도 될까요?"),
    HealthQuestion(question: "빈속에 약 먹어도 되나요?"),
    HealthQuestion(question: "진통제랑 항생제는 어떤 차이가 있나요?"),
    HealthQuestion(question: "영양제는 언제 먹는 게 좋을까요?"),
    HealthQuestion(question: "감기 걸렸을 때 어떤 약을 먹어야 하나요?")
]

func getDailyQuestion() -> HealthQuestion {
    let dayIndex = Calendar.current.component(.day, from: Date()) % sampleQuestions.count
    return sampleQuestions[dayIndex]
}

