import SwiftUI

struct LoginView: View {
    @StateObject private var authVM = AuthViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 앱 로고 + 앱 이름
            VStack(spacing: 8) {
                Image(systemName: "pills.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("MediMate")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
            }
            
            // 구글 로그인 버튼 (아이콘만)
            // 구글 로그인 버튼 (아이콘+텍스트 포함된 이미지 자체만)
            Button(action: {
                authVM.signInWithGoogle { success in
                    if success {
                        isLoggedIn = true
                    }
                }
            }) {
                Image("google-icon") // ✅ 텍스트 포함된 이미지
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 60) // ✅ 이미지 크기만 조절 (원하는 대로 변경 가능)
            }
            .buttonStyle(PlainButtonStyle()) // ✅ 버튼 기본 효과 제거


            Spacer()
        }
        .padding()
    }
}
