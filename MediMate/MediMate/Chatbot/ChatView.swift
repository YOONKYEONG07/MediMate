import SwiftUI
import UniformTypeIdentifiers

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var isBookmarked: Bool = false
    var isCategoryCard: Bool = false // ✅ 카테고리 카드 여부
}

struct ChatView: View {
    @EnvironmentObject var chatInputManager: ChatInputManager

    @State private var messages: [ChatMessage] = [
            ChatMessage(text: "", isUser: false, isCategoryCard: true)
        ]

    @State private var inputText = ""
    @State private var showBookmarks = false
    @State private var showImagePicker = false
    @State private var showFileImporter = false

    @State private var scrollTargetID: UUID? = nil // ✅ 추가

    var todayGreeting: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return "🗓️ \(formatter.string(from: Date())) 오늘도 건강 챙기기! 🍀"
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(todayGreeting)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.vertical, 4)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(messages) { message in
                            if message.isCategoryCard {
                                HStack(alignment: .top) {
                                    Image("chatbotAvatar")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                        .padding(.trailing, 5)

                                    CategoryCardMessageView { selectedCategory in
                                        sendCategoryMessage(selectedCategory)
                                    }
                                }
                                .padding(.horizontal)
                            } else {
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
                                            .id(message.id) // ✅ 추가

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
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                }
                .padding(.vertical, 8)
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: scrollTargetID) { targetID in // ✅ 추가
                    if let id = targetID {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .top)
                        }
                    }
                }
            }

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
                    Button("즐겨찾기 보기") { showBookmarks = true }
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showBookmarks) {
            NavigationView {
                List(messages.filter { $0.isBookmarked }) { msg in
                    Button(action: {
                        scrollTargetID = msg.id // ✅ 바로 해당 메시지로 스크롤
                        showBookmarks = false
                    }) {
                        Text(msg.text)
                    }
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
        .onChange(of: chatInputManager.prefilledMessage) { newValue in
            if let newText = newValue {
                inputText = newText
                chatInputManager.prefilledMessage = nil
            }
        }
    }

    func sendMessage() {
        let userMessage = ChatMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        let prompt = inputText
        inputText = ""

        // ✅ "카테고리" 입력 시 카드 다시 보여주기
        if prompt.lowercased().contains("카테고리") {
            messages.append(ChatMessage(text: "", isUser: false, isCategoryCard: true))
            return
        }

        ChatGPTService.shared.sendMessage(messages: [prompt]) { response in
            DispatchQueue.main.async {
                let reply = ChatMessage(text: response ?? "⚠️ 응답 실패", isUser: false)
                messages.append(reply)
            }
        }
    }


    func sendCategoryMessage(_ category: String) {
        messages.append(ChatMessage(text: category, isUser: true))
        let reply: String
        switch category {
        case "💊 약물 간 상호작용":
            reply = "함께 복용 중인 약들을 입력해 주세요."
        case "⏰ 복용 방법 및 시기":
            reply = "약 이름을 알려주시면 복용 시기와 방법을 안내해 드릴게요."
        case "⚠️ 금기 사항/부작용":
            reply = "복용 중인 약 이름을 알려주세요. 부작용이나 금기 사항을 확인해 드릴게요."
        case "🔄 성분 및 효능":
            reply = "약 이름을 입력해 주시면 성분과 효능 정보를 알려드릴게요."
        default:
            reply = "카테고리를 다시 선택해 주세요."
            messages.append(ChatMessage(text: "", isUser: false, isCategoryCard: true))
            return
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

// ✅ 카테고리 카드 컴포넌트
struct CategoryCardMessageView: View {
    var onCategorySelected: (String) -> Void
    let categories = [
        "💊 약물 간 상호작용",
        "⏰ 복용 방법 및 시기",
        "⚠️ 금기 사항/부작용",
        "🔄 성분 및 효능"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("무엇이 궁금하신가요?\n아래 카테고리를 선택해 주세요.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)

            ForEach(categories, id: \.self) { category in
                Button(action: {
                    onCategorySelected(category)
                }) {
                    Text(category)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
            }

            Text("다른 카테고리가 궁금하다면 '카테고리' 라고 \n입력해 주세요 ☺️")
                .lineLimit(nil)
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
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

