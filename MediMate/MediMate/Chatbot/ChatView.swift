import SwiftUI
import Vision
import UIKit
import FirebaseFirestore
import FirebaseAuth   // ✅ 추가

// MARK: - Model
/// A single chat message.
struct ChatMessage: Identifiable {
    let id: UUID = UUID()
    let text: String
    let isUser: Bool
    var isBookmarked: Bool = false
    var isCategoryCard: Bool = false
}

// MARK: - Firestore Manager
final class BookmarksStore {
    static let shared = BookmarksStore()
    private let db = Firestore.firestore()
    private init() {}

    /// Save a question string under the user's Saved Questions path.
    func save(userID: String, question: String) {
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

    /// Load questions for a user (newest first).
    func fetch(userID: String, completion: @escaping ([String]) -> Void) {
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
}

// MARK: - OCR Service
enum OCRService {
    /// Perform text recognition on a UIImage. Returns a single joined string.
    static func recognizeText(in image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.success(""))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let recognized = (request.results as? [VNRecognizedTextObservation])?
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n") ?? ""
            completion(.success(recognized))
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko-KR", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform([request]) } catch { completion(.failure(error)) }
        }
    }
}

// MARK: - Chat View
struct ChatView: View {
    @EnvironmentObject var chatInputManager: ChatInputManager
    @Environment(\.colorScheme) private var colorScheme

    // Data
    @State private var messages: [ChatMessage] = [ChatMessage(text: "", isUser: false, isCategoryCard: true)]
    @State private var bookmarkedQuestions: [String] = []

    // UI State
    @State private var inputText = ""
    @State private var showBookmarks = false
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var scrollAnchor = UUID()
    @State private var jumpToID: UUID? = nil
    @State private var jumpTick: Int = 0
    @State private var isLoadingReply = false

    // ✅ 현재 선택된 카테고리 (기본: 일반)
    @State private var selectedCategory: ChatCategory = .general

    // User (Google 로그인 UID 사용)
    @State private var userID: String = ""
    @State private var authHandle: AuthStateDidChangeListenerHandle? = nil

    // Greeting
    private var todayGreeting: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return "🗓️ \(f.string(from: Date())) 오늘도 건강 챙기기! 🍀"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(todayGreeting)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.vertical, 4)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageRow(
                                message: message,
                                colorScheme: colorScheme,
                                onCategorySelected: { sendCategoryMessage($0) },
                                onBookmark: { toggleBookmark($0) }
                            )
                            .id(message.id) // ← 각 메시지 고유 ID
                        }

                        // Invisible anchor to keep scrolling to bottom
                        Color.clear.frame(height: 1).id(scrollAnchor)
                    }
                }
                .padding(.vertical, 8)
                // 새 메시지 올 때 하단으로
                .onChange(of: messages.count) { _ in
                    withAnimation { proxy.scrollTo(scrollAnchor, anchor: .bottom) }
                }
                // 즐겨찾기에서 탭할 때 강제 스크롤 트리거
                .onChange(of: jumpTick) { _ in
                    if let id = jumpToID {
                        withAnimation { proxy.scrollTo(id, anchor: .center) }
                    }
                }
            }

            // Composer
            ComposerBar(
                inputText: $inputText,
                onSend: sendMessage,
                onPickPhoto: { showImagePicker = true },
                onOpenCamera: { showCameraPicker = true }
            )
            .padding()
        }
        .navigationTitle("상담 챗봇")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showBookmarks, content: bookmarksSheet)
        .sheet(isPresented: $showImagePicker) { ImagePickerView { handlePickedImage($0) } }
        .sheet(isPresented: $showCameraPicker) { CameraPickerView { handlePickedImage($0) } }
        // ✅ 로그인 상태 감지 → userID 세팅 & 즐겨찾기 로드
        .onAppear {
            authHandle = Auth.auth().addStateDidChangeListener { _, user in
                let newUID = user?.uid ?? ""
                if userID != newUID {
                    userID = newUID
                    if !newUID.isEmpty {
                        BookmarksStore.shared.fetch(userID: newUID) { fetched in
                            bookmarkedQuestions = fetched
                        }
                    } else {
                        bookmarkedQuestions = []
                    }
                }
            }
        }
        .onDisappear {
            if let h = authHandle { Auth.auth().removeStateDidChangeListener(h) }
        }
        .onChange(of: chatInputManager.prefilledMessage) { newValue in
            if let text = newValue { inputText = text; chatInputManager.prefilledMessage = nil }
        }
    }
}

// MARK: - Subviews & Toolbar
private extension ChatView {
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                Button("즐겨찾기 보기") { showBookmarks = true }
                    .disabled(userID.isEmpty) // UID 없으면 비활성화
            } label: { Image(systemName: "star") }
        }
    }

    @ViewBuilder
    func bookmarksSheet() -> some View {
        NavigationView {
            List {
                ForEach(bookmarkedQuestions, id: \.self) { q in
                    Button(q) {
                        if let idx = messages.lastIndex(where: { $0.text == q }) {
                            jumpToID = messages[idx].id
                            jumpTick &+= 1            // 매번 값 변경해 onChange 트리거
                            showBookmarks = false
                        } else {
                            inputText = q
                            showBookmarks = false
                        }
                    }
                }
            }
            .navigationTitle("즐겨찾기")
            .onAppear {
                guard !userID.isEmpty else { return }
                BookmarksStore.shared.fetch(userID: userID) { fetched in
                    bookmarkedQuestions = fetched
                }
            }
        }
    }
}

// MARK: - Actions
private extension ChatView {
    func handlePickedImage(_ image: UIImage?) {
        guard let img = image else { return }
        OCRService.recognizeText(in: img) { result in
            switch result {
            case .success(let text):
                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: "[사진 분석 결과]\n\(text)", isUser: true))
                    // ✅ 카테고리 전달
                    ChatGPTService.shared.sendMessage(messages: [text],
                                                      selectedCategory: selectedCategory) { response in
                        DispatchQueue.main.async {
                            messages.append(ChatMessage(text: response ?? "⚠️ 응답 실패", isUser: false))
                        }
                    }
                }
            case .failure:
                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: "⚠️ OCR 처리 실패", isUser: false))
                }
            }
        }
    }

    func sendMessage() {
        let userMsg = ChatMessage(text: inputText, isUser: true)
        messages.append(userMsg)
        let prompt = inputText
        inputText = ""

        // Quick access to category card
        if prompt.lowercased().contains("카테고리") {
            messages.append(ChatMessage(text: "", isUser: false, isCategoryCard: true))
            return
        }

        // ✅ 로딩 상태 true + 로딩 메시지 추가 (응답 오면 제거)
        isLoadingReply = true
        let loadingMsg = ChatMessage(text: "챗봇이 답변중입니다...🤖", isUser: false)
        messages.append(loadingMsg)

        // ✅ 카테고리 전달
        ChatGPTService.shared.sendMessage(messages: [prompt],
                                          selectedCategory: selectedCategory) { response in
            DispatchQueue.main.async {
                // 로딩 메시지 제거
                if let idx = messages.firstIndex(where: { $0.id == loadingMsg.id }) {
                    messages.remove(at: idx)
                }

                // 실제 응답 추가
                messages.append(ChatMessage(text: response ?? "⚠️ 응답 실패", isUser: false))
                isLoadingReply = false
            }
        }
    }

    func sendCategoryMessage(_ category: String) {
        // ✅ 1) 선택한 카테고리 상태 갱신
        selectedCategory = ChatCategory.fromButtonTitle(category)

        // 2) 사용자 메시지로 표시
        messages.append(ChatMessage(text: category, isUser: true))

        // 3) 카테고리별 안내 프롬프트
        let reply: String
        switch selectedCategory {
        case .interaction:
            reply = "함께 복용 중인 약(또는 성분)을 입력해 주세요. 예: 이부프로펜 + 와파린"
        case .usageTiming:
            reply = "약 이름을 알려주시면 복용 시기(식전/식후/취침 전 등)와 방법을 안내해 드릴게요."
        case .precaution:
            reply = "복용 중인 약 이름을 알려주세요. 금기 질환/연령/임신·수유, 흔한/심각 부작용을 확인해 드릴게요."
        case .supplement:
            reply = "원하시는 건강 목표나 고민(예: 피로, 수면, 관절)을 알려주시면 성분을 추천해 드릴게요."
        case .general:
            reply = "궁금한 내용을 자유롭게 입력해 주세요. 최대한 도움을 드릴게요."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            messages.append(ChatMessage(text: reply, isUser: false))
        }
    }

    func toggleBookmark(_ message: ChatMessage) {
        // 로그인 안 되어 있으면 (UID 없음) 저장하지 않음
        guard !userID.isEmpty else { return }
        if let idx = messages.firstIndex(where: { $0.id == message.id }) {
            messages[idx].isBookmarked.toggle()
            if messages[idx].isBookmarked {
                BookmarksStore.shared.save(userID: userID, question: messages[idx].text)
            }
        }
    }
}

// MARK: - Composer Bar
private struct ComposerBar: View {
    @Binding var inputText: String
    let onSend: () -> Void
    let onPickPhoto: () -> Void
    let onOpenCamera: () -> Void

    var body: some View {
        HStack {
            Menu {
                Button("📸 카메라", action: onOpenCamera)
                Button("🖼️ 사진 선택", action: onPickPhoto)
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title3)
                    .padding(.horizontal, 4)
            }

            TextField("메시지를 입력하세요", text: $inputText)
                .textFieldStyle(.roundedBorder)

            Button("전송", action: onSend)
                .disabled(inputText.isEmpty)
        }
    }
}

// MARK: - Message Row
private struct MessageRow: View {
    let message: ChatMessage
    let colorScheme: ColorScheme
    let onCategorySelected: (String) -> Void
    let onBookmark: (ChatMessage) -> Void

    // ✅ 숫자 포맷: 문장 중간의 " 1." → 줄바꿈, "1." 단독 줄 → 다음 줄과 합치기
    static func formatEnumerations(_ raw: String) -> String {
        var s = raw
        // 문장 뒤에 스페이스+번호가 붙은 경우 줄바꿈으로 바꿈
        for n in 1...20 {
            s = s.replacingOccurrences(of: " \(n).", with: "\n\(n).")
        }
        // "1." 만 있는 줄은 다음 줄과 붙임(빈 줄은 건너뜀)
        var lines = s.components(separatedBy: .newlines)
        var out: [String] = []
        var i = 0
        while i < lines.count {
            let curTrim = lines[i].trimmingCharacters(in: .whitespaces)
            if curTrim.range(of: #"^\d+\.$"#, options: .regularExpression) != nil {
                var j = i + 1
                while j < lines.count,
                      lines[j].trimmingCharacters(in: .whitespaces).isEmpty {
                    j += 1
                }
                if j < lines.count {
                    let next = lines[j].trimmingCharacters(in: .whitespaces)
                    out.append("\(curTrim) \(next)")
                    i = j + 1
                    continue
                }
            }
            out.append(lines[i])
            i += 1
        }
        return out.joined(separator: "\n")
    }

    var body: some View {
        Group {
            if message.isCategoryCard {
                HStack(alignment: .top) {
                    Avatar()
                    CategoryCardMessageView(onCategorySelected: onCategorySelected)
                }
                .padding(.horizontal)
            } else {
                HStack(alignment: .top) {
                    if !message.isUser { Avatar().padding(.trailing, 5) }
                    if message.isUser { Spacer() }

                    VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                        let formattedText = MessageRow.formatEnumerations(message.text)

                        Text(formattedText)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                            .foregroundColor(message.isUser ? .white : (colorScheme == .dark ? .white : .black))
                            .background(message.isUser ? Color.blue : Color(UIColor.systemGray5))
                            .cornerRadius(16)
                            .frame(maxWidth: 250, alignment: message.isUser ? .trailing : .leading)

                        if !message.isUser {
                            Button(action: { onBookmark(message) }) {
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
    }

    private func Avatar() -> some View {
        Image("chatbotAvatar")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
            .clipShape(Circle())
    }
}

// MARK: - Category Card (unchanged behavior)
struct CategoryCardMessageView: View {
    @Environment(\.colorScheme) var colorScheme
    var onCategorySelected: (String) -> Void

    private let categories = [
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
                Button(category) { onCategorySelected(category) }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
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
        .background(colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Camera & Photo Pickers
struct CameraPickerView: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            completion(info[.originalImage] as? UIImage)
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil); picker.dismiss(animated: true) }
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

struct ImagePickerView: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            completion(info[.originalImage] as? UIImage)
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completion(nil); picker.dismiss(animated: true) }
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

