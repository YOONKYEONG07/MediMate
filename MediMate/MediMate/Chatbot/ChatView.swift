import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "안녕하세요! 무엇을 도와드릴까요?", isUser: false)
    ]
    @State private var inputText = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(messages) { message in
                    HStack {
                        if message.isUser { Spacer() }
                        Text(message.text)
                            .padding()
                            .foregroundColor(message.isUser ? .white : .black)
                            .background(message.isUser ? Color.blue : Color(.systemGray5))
                            .cornerRadius(16)
                            .frame(maxWidth: 250, alignment: message.isUser ? .trailing : .leading)
                        if !message.isUser { Spacer() }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }

            HStack {
                TextField("메시지를 입력하세요", text: $inputText)
                    .textFieldStyle(.roundedBorder)

                Button("전송") {
                    sendMessage()
                }
                .disabled(inputText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("상담 챗봇")
    }

    func sendMessage() {
        let userMessage = ChatMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        inputText = ""

        // AI 응답 시뮬레이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let reply = ChatMessage(text: "복용 중인 약에 대해 알려주시면 도와드릴게요.", isUser: false)
            messages.append(reply)
        }
    }
}

