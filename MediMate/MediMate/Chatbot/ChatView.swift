import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String?
    let image: UIImage?
    let isUser: Bool
    var isBookmarked: Bool = false
}

struct ChatView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(text: "안녕하세요! 무엇을 도와드릴까요?", image: nil, isUser: false)
    ]
    @State private var inputText = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showFileImporter = false

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    ForEach(messages) { message in
                        HStack(alignment: .bottom) {
                            if !message.isUser {
                                // ☰ 메뉴 버튼 맨 왼쪽 정렬용 (공간 확보)
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.clear)
                                    .frame(width: 24)

                                // 상대방 프로필 이미지
                                Image("pharmacist")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                            }

                            VStack(alignment: message.isUser ? .trailing : .leading) {
                                if let image = message.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 200)
                                        .cornerRadius(10)
                                }

                                if let text = message.text {
                                    Text(text)
                                        .padding()
                                        .foregroundColor(message.isUser ? .white : .black)
                                        .background(message.isUser ? Color.blue : Color(.systemGray5))
                                        .cornerRadius(16)
                                        .frame(maxWidth: 250, alignment: message.isUser ? .trailing : .leading)
                                }
                            }

                            if message.isUser {
                                Spacer()

                                // 내 프로필 이미지
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.blue)
                            } else {
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                }

                Divider()

                HStack {
                    Menu {
                        Button("📷 사진 선택") {
                            showImagePicker = true
                        }
                        Button("📄 파일 선택 (.txt)") {
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
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage) { image in
                if let image = image {
                    messages.append(ChatMessage(text: nil, image: image, isUser: true))
                    simulateReply()
                }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first, let contents = try? String(contentsOf: url) {
                    messages.append(ChatMessage(text: contents, image: nil, isUser: true))
                    simulateReply()
                }
            case .failure(let error):
                print("파일 가져오기 실패: \(error.localizedDescription)")
            }
        }
    }

    func sendMessage() {
        messages.append(ChatMessage(text: inputText, image: nil, isUser: true))
        inputText = ""
        simulateReply()
    }

    func simulateReply() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            messages.append(ChatMessage(text: "복용 중인 약에 대해 알려주시면 도와드릴게요.", image: nil, isUser: false))
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self, completion: completion)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        var completion: (UIImage?) -> Void

        init(_ parent: ImagePicker, completion: @escaping (UIImage?) -> Void) {
            self.parent = parent
            self.completion = completion
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let uiImage = info[.originalImage] as? UIImage
            parent.image = uiImage
            completion(uiImage)
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
