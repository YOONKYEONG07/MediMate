import SwiftUI
import Vision
import UIKit
import FirebaseFirestore

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var isBookmarked: Bool = false
    var isCategoryCard: Bool = false
}

let db = Firestore.firestore()

func saveBookmarkedQuestion(userID: String, question: String) {
    let questionID = UUID().uuidString
    let data: [String: Any] = [
        "text": question,
        "timestamp": Timestamp(date: Date())
    ]
    db.collection("savedQuestions")
        .document(userID)
        .collection("questions")
        .document(questionID)
        .setData(data)
}

func fetchBookmarkedQuestions(userID: String, completion: @escaping ([String]) -> Void) {
    db.collection("savedQuestions")
        .document(userID)
        .collection("questions")
        .order(by: "timestamp", descending: true)
        .getDocuments { snapshot, error in
            guard let docs = snapshot?.documents, error == nil else {
                completion([])
                return
            }
            let questions = docs.compactMap { $0.data()["text"] as? String }
            completion(questions)
        }
}

struct ChatView: View {
    @EnvironmentObject var chatInputManager: ChatInputManager
    @Environment(\.colorScheme) var colorScheme

    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "", isUser: false, isCategoryCard: true)
    ]

    @State private var inputText = ""
    @State private var showBookmarks = false
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var scrollTargetID: UUID? = nil
    @State private var bookmarkedQuestions: [String] = []
    @State private var userID = "test-user-001"

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
                                            .lineSpacing(6)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding()
                                            .foregroundColor(message.isUser ? .white : (colorScheme == .dark ? .white : .black))
                                            .background(
                                                message.isUser ? Color.blue :
                                                (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray5))
                                            )
                                            .cornerRadius(16)
                                            .frame(maxWidth: 250, alignment: message.isUser ? .trailing : .leading)
                                            .id(message.id)

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
                .onChange(of: scrollTargetID) { targetID in
                    if let id = targetID {
                        withAnimation {
                            proxy.scrollTo(id, anchor: .top)
                        }
                    }
                }
            }

            HStack {
                Menu {
                    Button("📸 카메라") { showCameraPicker = true }
                    Button("🖼️ 사진 선택") { showImagePicker = true }
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
                List {
                    ForEach(bookmarkedQuestions, id: \.self) { question in
                        Button(action: {
                            inputText = question
                            showBookmarks = false
                        }) {
                            Text(question)
                        }
                    }
                }
                .navigationTitle("즐겨찾기")
                .onAppear {
                    fetchBookmarkedQuestions(userID: userID) { loaded in
                        bookmarkedQuestions = loaded
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView { image in
                if let image = image {
                    performOCR(image)
                }
            }
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPickerView { image in
                if let image = image {
                    performOCR(image)
                }
            }
        }
        .onChange(of: chatInputManager.prefilledMessage) { newValue in
            if let newText = newValue {
                inputText = newText
                chatInputManager.prefilledMessage = nil
            }
        }
    }

    func performOCR(_ image: UIImage) {
        

        guard let cgImage = image.cgImage else {
            messages.append(ChatMessage(text: "⚠️ 이미지 변환 실패", isUser: false))
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { [self] request, error in
            if let observations = request.results as? [VNRecognizedTextObservation] {
                let recognizedText = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: "[사진 분석 결과]\n\(recognizedText)", isUser: true))

                    ChatGPTService.shared.sendMessage(messages: [recognizedText]) { response in
                        DispatchQueue.main.async {
                            let reply = ChatMessage(text: response ?? "⚠️ 응답 실패", isUser: false)
                            messages.append(reply)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: "⚠️ 텍스트 인식 실패", isUser: false))
                }
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko-KR", "en-US"]
        request.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: "⚠️ OCR 처리 실패", isUser: false))
                }
            }
        }
    }

    func sendMessage() {
        let userMessage = ChatMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        let prompt = inputText
        inputText = ""

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
        case "💪 영양제 추천":
            reply = "원하시는 건강 목표나 고민을 알려주시면 추천해 드릴게요"
        case "💬 상담 / 기타 문의":
            reply = "궁금한 내용을 자유롭게 입력해 주세요. 최대한 도움을 드릴게요."
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
            if messages[index].isBookmarked {
                saveBookmarkedQuestion(userID: userID, question: messages[index].text)
            }
        }
    }
}

// 카메라로 사진찍기 기능 구현
struct CameraPickerView: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completion: (UIImage?) -> Void

        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// 갤러리에서 사진 선택 기능 구현 (이전 코드 재활용)
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

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// 카테고리 카드 뷰 (이전 코드 재활용)
struct CategoryCardMessageView: View {
    @Environment(\.colorScheme) var colorScheme
    var onCategorySelected: (String) -> Void

    let categories = [
        "💊 약물 간 상호작용",
        "⏰ 복용 방법 및 시기",
        "⚠️ 금기 사항/부작용",
        "💪 영양제 추천",
        "💬 상담 / 기타 문의"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("무엇이 궁금하신가요?\n아래 카테고리를 선택해 주세요.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)

            ForEach(categories, id: \.self) { category in
                Button(action: {
                    onCategorySelected(category)
                }) {
                    Text(category)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            Text("다른 카테고리가 궁금하다면 '카테고리' 라고 입력해 주세요 ☺️")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

