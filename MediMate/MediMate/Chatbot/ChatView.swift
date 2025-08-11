import SwiftUI
import Vision
import UIKit
import FirebaseFirestore

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isUser: Bool
    var isBookmarked: Bool = false
    var isCategoryCard: Bool = false
}

struct ChatView: View {
    @EnvironmentObject var chatInputManager: ChatInputManager
    @Environment(\.colorScheme) var colorScheme

    // Firestore
    private let store = ChatFirestoreManager()

    // 답변 포맷 고정용 스타일 프롬프트 (기존 그대로)
    private let STYLE_PROMPT = """
    너는 의약/건강 상담 챗봇이야. 아래 규칙으로 한국어 **마크다운**만 반환해.
    - 가장 먼저 한 줄 요약을 **굵게** 작성하고, 그 줄 뒤에 빈 줄을 하나 넣어.
    - 그 다음 `## 핵심 요약` 섹션에 3–6개의 불릿(-)로 핵심만 간결하게.
    - 필요한 경우 `## 상세 안내` 섹션에 문단/목록으로 설명. 섹션/문단 사이에는 항상 빈 줄 1개.
    - 주의/경고는 ❗ 이모지와 함께 한 줄로 강조.
    - 불필요한 수사는 제거하고, 문장은 짧게. 코드블록/표/인용구/번호목록은 사용하지 마.
    """

    // User/Session
    @State private var userID: String = ChatView.makeDeviceUserID()
    @State private var sessionId = UUID().uuidString

    // Messages
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "", isUser: false, isCategoryCard: true)
    ]

    // UI states
    @State private var inputText = ""
    @State private var showBookmarks = false
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var showPickerMenu = false
    @State private var isResponding = false
    @State private var typingMessageID: UUID? = nil

    // Scroll/Highlight
    @State private var scrollTargetID: UUID? = nil
    @State private var highlightMessageID: UUID? = nil

    // Bookmarks
    @State private var bookmarkedQuestions: [String] = []

    // 말풍선 최대 폭
    private let bubbleMaxWidth: CGFloat = 320

    var todayGreeting: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return "🗓️ \(f.string(from: Date())) 오늘도 건강 챙기기! 🍀"
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
                                    CategoryCardMessageView(onCategorySelected: handleCategory)
                                }
                                .padding(.horizontal)
                            } else {
                                messageRow(message)
                            }
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                }
                .padding(.vertical, 8)
                .onChange(of: messages.count) { _ in
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
                .onChange(of: scrollTargetID) { targetID in
                    if let id = targetID { withAnimation { proxy.scrollTo(id, anchor: .top) } }
                }
            }

            if isResponding {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("🤖 챗봇이 답변 중입니다…")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 6)
            }

            HStack {
                Button { showPickerMenu = true } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .padding(.horizontal, 4)
                }
                .confirmationDialog("이미지 가져오기", isPresented: $showPickerMenu, titleVisibility: .visible) {
                    Button("📸 카메라") { showCameraPicker = true }
                    Button("🖼️ 사진 선택") { showImagePicker = true }
                    Button("취소", role: .cancel) {}
                }

                TextField("메시지를 입력하세요", text: $inputText)
                    .textFieldStyle(.roundedBorder)

                Button("전송") { sendMessage() }
                    .disabled(inputText.isEmpty || isResponding)
            }
            .padding()
        }
        .navigationTitle("상담 챗봇")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("즐겨찾기 보기") { showBookmarks = true }
                } label: { Image(systemName: "gearshape") }
            }
        }
        // 즐겨찾기 시트(초기화 제거)
        .sheet(isPresented: $showBookmarks) {
            NavigationView {
                List {
                    ForEach(bookmarkedQuestions, id: \.self) { question in
                        Button(action: { goToBookmarked(question) }) {
                            Text(question).lineLimit(2)
                        }
                    }
                }
                .navigationTitle("즐겨찾기")
                .onAppear {
                    store.fetchBookmarkedQuestions(userID: userID, sessionId: sessionId) { loaded in
                        let merged = Array((bookmarkedQuestions + loaded).uniqued())
                        bookmarkedQuestions = merged
                    }
                }
            }
        }
        // 사진 선택/카메라
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView { image in
                if let image = image { performOCR(image) }
            }
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPickerView { image in
                if let image = image { performOCR(image) }
            }
        }
        .onChange(of: chatInputManager.prefilledMessage) { newValue in
            if let newText = newValue {
                inputText = newText
                chatInputManager.prefilledMessage = nil
            }
        }
    }

    // MARK: - 메시지 행
    @ViewBuilder
    private func messageRow(_ message: ChatMessage) -> some View {
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
                // ⬇️ 표시 직전에 문단 강제 정리
                let displayText = forceParagraphs(message.text)

                if !message.isUser, let attributed = try? AttributedString(markdown: displayText) {
                    Text(attributed)
                        .lineSpacing(8)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .frame(maxWidth: bubbleMaxWidth, alignment: .leading)
                        .id(message.id)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.accentColor.opacity(message.id == highlightMessageID ? 0.9 : 0), lineWidth: 2)
                        )
                        .textSelection(.enabled)
                } else {
                    Text(displayText)
                        .lineSpacing(8)
                        .multilineTextAlignment(message.isUser ? .trailing : .leading)
                        .padding(12)
                        .foregroundColor(message.isUser ? .white : (colorScheme == .dark ? .white : .black))
                        .background(message.isUser ? Color.blue : Color(.systemGray6))
                        .cornerRadius(16)
                        .frame(maxWidth: bubbleMaxWidth, alignment: message.isUser ? .trailing : .leading)
                        .id(message.id)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.accentColor.opacity(message.id == highlightMessageID ? 0.9 : 0), lineWidth: 2)
                        )
                }

                if !message.isUser {
                    Button(action: { bookmark(message) }) {
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

    // MARK: - Helpers
    private static func makeDeviceUserID() -> String {
        let k = "localUserID"
        if let id = UserDefaults.standard.string(forKey: k) { return id }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: k)
        return new
    }

    /// ✅ 모델 출력이 붙어서 와도 문단/소제목/불릿을 강제로 정리
    /// - 문장부호 뒤 개행
    /// - `##` 소제목 전후 빈 줄
    /// - 번호목록(1. 2. …)을 불릿(- )으로 변환
    /// - '---', '—' 같은 구분선 제거
    /// - 연속 공백/개행 정리
    /// - 코드블록/인용구 제거(모델이 실수로 넣었을 때)
    private func forceParagraphs(_ s: String) -> String {
        var t = s.replacingOccurrences(of: "\r\n", with: "\n")

        // 0) 코드블록/인용구 제거
        t = t.replacingOccurrences(of: #"```[\s\S]*?```"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?m)^\s*>\s?"#, with: "", options: .regularExpression)

        // 1) 한 줄 요약(굵게) 뒤에 빈 줄 보장
        t = t.replacingOccurrences(of: #"(?m)^\s*\*\*(.+?)\*\*\s*$"#,
                                   with: "**$1**\n",
                                   options: .regularExpression)

        // 2) 소제목 앞뒤 빈 줄
        t = t.replacingOccurrences(of: #"(?m)(?<!\n)(##\s+[^\n]+)"#,
                                   with: "\n\n$1",
                                   options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?m)^(##\s+[^\n]+)\n(?!\n)"#,
                                   with: "$1\n\n",
                                   options: .regularExpression)

        // 3) 번호목록 → 불릿
        t = t.replacingOccurrences(of: #"(?m)^\s*\d+\.\s+"#,
                                   with: "- ",
                                   options: .regularExpression)

        // 4) 구분선/대시류 제거
        t = t.replacingOccurrences(of: #"(?m)^\s*[-–—]{3,}\s*$"#,
                                   with: "",
                                   options: .regularExpression)

        // 5) 리스트 항목은 줄 시작으로 정리 (중간에 붙으면 줄 나눔)
        t = t.replacingOccurrences(of: #"(?m)([^\n])\s*-\s"#,
                                   with: "$1\n- ",
                                   options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?m)([^\n])\s*•\s"#,
                                   with: "$1\n• ",
                                   options: .regularExpression)

        // 6) 문장 끝(., ?, !) 뒤에 개행(다음 문자가 한글/영문/숫자면)
        //    → 문장 단위로 시각적 분리
        t = t.replacingOccurrences(of: #"([\.!?])\s+(?=[가-힣A-Za-z0-9])"#,
                                   with: "$1\n",
                                   options: .regularExpression)

        // 7) 소제목 다음에 바로 리스트가 나오면 한 줄 띄우기
        t = t.replacingOccurrences(of: #"(?m)(##\s+[^\n]+)\n(-|\•)\s"#,
                                   with: "$1\n\n$2 ",
                                   options: .regularExpression)

        // 8) 연속 공백/개행 정리
        t = t.replacingOccurrences(of: #"[ \t]{2,}"#,
                                   with: " ",
                                   options: .regularExpression)
        t = t.replacingOccurrences(of: #"\n{3,}"#,
                                   with: "\n\n",
                                   options: .regularExpression)

        // 9) 앞뒤 공백 제거
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        return t
    }

    // 즐겨찾기 → 해당 메시지로 스크롤 + 하이라이트
    private func goToBookmarked(_ question: String) {
        showBookmarks = false
        let target = messages.first(where: { !$0.isUser && $0.text == question }) ??
                     messages.first(where: { $0.text == question })
        guard let found = target else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            scrollTargetID = found.id
            highlightMessageID = found.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { highlightMessageID = nil }
            }
        }
    }

    private func handleCategory(_ category: String) {
        sendCategoryMessage(category)
    }

    private func sendCategoryMessage(_ category: String) {
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

    private func addTypingIndicator() {
        let typing = ChatMessage(text: "🤖 챗봇이 답변 중입니다…", isUser: false)
        typingMessageID = typing.id
        messages.append(typing)
        isResponding = true
    }

    private func removeTypingIndicator() {
        if let id = typingMessageID, let idx = messages.firstIndex(where: { $0.id == id }) {
            messages.remove(at: idx)
        }
        typingMessageID = nil
        isResponding = false
    }

    private func buildStyledPrompt(from userText: String) -> String {
        """
        \(STYLE_PROMPT)

        [사용자 질문]
        \(userText)

        위 규칙을 지켜 **마크다운 텍스트만** 반환해.
        """
    }

    // OCR
    func performOCR(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            messages.append(ChatMessage(text: "⚠️ 이미지 변환 실패", isUser: false))
            return
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let req = VNRecognizeTextRequest { [self] request, _ in
            if let obs = request.results as? [VNRecognizedTextObservation] {
                let recognized = obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: "[사진 분석 결과]\n\(recognized)", isUser: true))
                    addTypingIndicator()
                    let composed = buildStyledPrompt(from:
                        "다음은 사진에서 인식된 텍스트야. 이를 참고해서 사용자가 이해하기 쉽게 안내해줘.\n\(recognized)"
                    )
                    ChatGPTService.shared.sendMessage(messages: [composed]) { response in
                        DispatchQueue.main.async {
                            removeTypingIndicator()
                            let clean = forceParagraphs(response ?? "⚠️ 응답 실패")
                            messages.append(ChatMessage(text: clean, isUser: false))
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: "⚠️ 텍스트 인식 실패", isUser: false))
                }
            }
        }
        req.recognitionLevel = .accurate
        req.recognitionLanguages = ["ko-KR", "en-US"]
        req.usesLanguageCorrection = true

        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform([req]) }
            catch {
                DispatchQueue.main.async {
                    messages.append(ChatMessage(text: "⚠️ OCR 처리 실패", isUser: false))
                }
            }
        }
    }

    // 일반 전송
    func sendMessage() {
        let userMessage = ChatMessage(text: inputText, isUser: true)
        messages.append(userMessage)
        let prompt = inputText
        inputText = ""

        if prompt.lowercased().contains("카테고리") {
            messages.append(ChatMessage(text: "", isUser: false, isCategoryCard: true))
            return
        }

        addTypingIndicator()
        let composed = buildStyledPrompt(from: prompt)
        ChatGPTService.shared.sendMessage(messages: [composed]) { response in
            DispatchQueue.main.async {
                removeTypingIndicator()
                let clean = forceParagraphs(response ?? "⚠️ 응답 실패")
                messages.append(ChatMessage(text: clean, isUser: false))
            }
        }
    }

    // 북마크
    func bookmark(_ message: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index].isBookmarked.toggle()
            let text = messages[index].text

            if messages[index].isBookmarked {
                if !bookmarkedQuestions.contains(text) {
                    bookmarkedQuestions.insert(text, at: 0)
                }
                store.saveBookmarkedQuestion(userID: userID, question: text, sessionId: sessionId) { _ in }
            } else {
                if let i = bookmarkedQuestions.firstIndex(of: text) {
                    bookmarkedQuestions.remove(at: i)
                }
            }
        }
    }
}

// MARK: - Camera
struct CameraPickerView: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            completion(image); picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil); picker.dismiss(animated: true)
        }
    }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.delegate = context.coordinator
        p.sourceType = .camera
        return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Photo Library
struct ImagePickerView: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            completion(image); picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil); picker.dismiss(animated: true)
        }
    }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.delegate = context.coordinator
        p.sourceType = .photoLibrary
        return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Category Card
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
                Button(action: { onCategorySelected(category) }) {
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

// MARK: - Small sugar
private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

