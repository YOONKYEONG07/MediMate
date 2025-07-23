import SwiftUI
import UniformTypeIdentifiers

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var isBookmarked: Bool = false
}

struct ChatView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "안녕하세요! 무엇을 도와드릴까요?", isUser: false)
    ]

    @State private var inputText = ""
    @State private var showBookmarks = false
    @State private var showImagePicker = false
    @State private var showFileImporter = false

    var todayGreeting: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return "🗓️ \(formatter.string(from: Date()))    오늘도 건강 챙기기! 🍀"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text(todayGreeting)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 10)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {  // ✅ LazyVStack 추가 + spacing 설정
                        ForEach(messages) { message in
                            HStack(alignment: .top) {
                                if !message.isUser {
                                    Image("chatbotAvatar") // ✅ 이 이름이 Assets에 있는지 확인
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .padding(.trailing, 5)
                                }

                                if message.isUser { Spacer() }

                                VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                                    Text(message.text)
                                        .padding()
                                        .foregroundColor(message.isUser ? .white : .black)
                                        .background(message.isUser ? Color.blue : Color(.systemGray5))
                                        .cornerRadius(16)
                                        .frame(maxWidth: 250, alignment: message.isUser ? .trailing : .leading)

                                    if !message.isUser {
                                        Button(action: {
                                            bookmark(message)
                                        }) {
                                            Image(systemName: message.isBookmarked ? "star.fill" : "star")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                        }
                                        .padding(.leading, 8)
                                    }
                                }

                                if !message.isUser { Spacer() }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }

                Divider()

                HStack {
                    Menu {
                        Button("📷 사진 선택") { showImagePicker = true }
                        Button("📄 파일 선택") { showFileImporter = true }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .padding(.horizontal, 4)
                    }

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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("즐겨찾기 보기") {
                            showBookmarks = true
                        }
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showBookmarks) {
                NavigationView {
                    List(messages.filter { $0.isBookmarked }) { msg in
                        Text(msg.text)
                    }
                    .navigationTitle("즐겨찾기")
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView { image in
                    if let _ = image {
                        messages.append(ChatMessage(text: "[사진 전송됨]", isUser: true))
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [
                    UTType.plainText, .pdf,
                    UTType(filenameExtension: "doc")!,
                    UTType(filenameExtension: "docx")!,
                    UTType(filenameExtension: "xls")!,
                    UTType(filenameExtension: "xlsx")!
                ],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        do {
                            let contents = try String(contentsOf: url)
                            messages.append(ChatMessage(text: contents, isUser: true))
                        } catch {
                            messages.append(ChatMessage(text: "[⚠️ 이 파일은 텍스트로 열 수 없어요]", isUser: true))
                        }
                    }
                case .failure(let error):
                    print("파일 가져오기 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    func sendMessage() {
        let userMessage = ChatMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        inputText = ""

        let reply = ChatMessage(text: "복용 중인 약에 대해 알려주시면 도와드릴게요.", isUser: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            messages.append(reply)
        }
    }

    func bookmark(_ message: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].isBookmarked.toggle()
        }
    }
}
