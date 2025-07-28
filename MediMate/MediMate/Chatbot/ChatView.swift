import SwiftUI
import UniformTypeIdentifiers

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var isBookmarked: Bool = false
}

struct ChatView: View {
    @EnvironmentObject var chatInputManager: ChatInputManager

    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "안녕하세요! 무엇을 도와드릴까요?", isUser: false)
    ]
    @State private var inputText = ""
    @State private var showBookmarks = false
    @State private var showImagePicker = false
    @State private var showFileImporter = false
    @State private var selectedCategory: String? = nil
    @State var showCategoryButtons = true

    let categoryOptions = [
            "💊 약 성분 분석",
            "❗ 부작용 확인",
            "📋 복용법 안내",
            "🚫 병용금기 확인"
        ]
    
    var todayGreeting: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        let dateString = formatter.string(from: Date())
        return "🗓️ \(dateString)    오늘도 건강 챙기기! 🍀"
    }

    var body: some View {
            VStack(spacing: 0) {
                Text(todayGreeting)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 4)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(messages) { message in
                            HStack(alignment: .top) {
                                if !message.isUser {
                                    Image("chatbotAvatar")
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
                                    }
                                }

                                if !message.isUser { Spacer() }
                            }
                            .padding(.horizontal)
                        }
                        
                        if showCategoryButtons {
                            VStack(alignment: .leading, spacing: 12) {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(categoryOptions, id: \.self) { category in
                                        Button(action: {
                                            selectedCategory = category
                                            sendCategoryMessage(category)
                                        }) {
                                            Text(category)
                                                .padding(.vertical, 8)
                                                .frame(maxWidth: .infinity)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(10)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                                            }
                    }
                    .padding(.vertical, 8)
                }

                HStack {
                    Menu {
                        Button("📷 사진 선택") {
                            showImagePicker = true
                        }
                        Button("📄 파일 선택") {
                            showFileImporter = true
                        }
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
                    UTType.plainText,
                    UTType.pdf,
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
            // ✅ 여기서 prefilledMessage 자동 반영
            .onChange(of: chatInputManager.prefilledMessage) { newValue in
                if let newText = newValue {
                    inputText = newText
                    chatInputManager.prefilledMessage = nil // 중복 방지
                }
            }
            .onAppear(){
                if messages.isEmpty {
                    messages.append(ChatMessage(text: "안녕하세요! 무엇을 도와드릴까요?", isUser: false))
                    messages.append(ChatMessage(text: "무엇이 궁금하신가요? 아래 카테고리를 선택해 주세요.", isUser: false))
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
    
    func sendCategoryMessage(_ category: String) {
            messages.append(ChatMessage(text: category, isUser: true))
        showCategoryButtons = false

            let reply: String
            switch category {
            case "💊 약 성분 분석":
                reply = "궁금한 약 이름을 입력해 주세요!"
            case "❗ 부작용 확인":
                reply = "복용 중인 약 이름을 알려주세요."
            case "📋 복용법 안내":
                reply = "약 이름을 알려주시면 복용법을 안내해 드릴게요."
            case "🚫 병용금기 확인":
                reply = "함께 복용 중인 약들을 입력해 주세요."
            default:
                reply = "카테고리를 다시 선택해 주세요."
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    messages.append(ChatMessage(text: reply, isUser: false))
                }
            }

    func bookmark(_ message: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].isBookmarked.toggle()
        }
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (UIImage?) -> Void

        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            completion(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
            picker.dismiss(animated: true)
        }
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
