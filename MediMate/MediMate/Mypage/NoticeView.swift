import SwiftUI

struct NoticeView: View {
    // 샘플 공지 리스트 (실제 데이터와 연결 가능)
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
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct Notice: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}
