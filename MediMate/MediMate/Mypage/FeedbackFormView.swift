
import SwiftUI

struct FeedbackFormView: View {
    @State private var feedbackText = ""
    
    var body: some View {
        Form {
            Section(header: Text("피드백 내용")) {
                TextEditor(text: $feedbackText)
                    .frame(height: 150)
            }
            
            Button("보내기") {
                // 서버 업로드 또는 이메일 자동 생성 등 처리
                print("Feedback: \(feedbackText)")
            }
        }
        .navigationTitle("피드백 보내기")
    }
}


