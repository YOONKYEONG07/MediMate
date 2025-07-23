import SwiftUI

struct NoticeView: View {
    // 공지 데이터
    let notices: [Notice] = [
        Notice(title: "버전 1.0 출시 🎉", content: "드디어 MediMate의 첫 번째 버전이 출시되었습니다!"),
        Notice(title: "알림 기능 개선", content: "약 복용 알림이 더 정확하고 안정적으로 개선되었어요."),
        Notice(title: "버그 수정 안내", content: "일부 사용자에게 발생한 로그인 오류가 해결되었습니다.")
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("공지사항")
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)
                .padding(.top)
            
            List(notices) { notice in
                VStack(alignment: .leading, spacing: 4) {
                    Text(notice.title)
                        .font(.headline)
                    Text(notice.content)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
            .listStyle(.insetGrouped)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false) // ✅ 상단 네비게이션바 숨김
        .navigationBarTitleDisplayMode(.inline) // ✅ 시스템 배경으로 자연스럽게
    }
}

// 공지사항 모델
struct Notice: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}
