import SwiftUI

struct ReminderTabView: View {
    var body: some View {
        NavigationView {
            VStack {
                // 상단 버튼
                HStack {
                    Spacer()
                    NavigationLink(destination: ReminderAddView()) {
                        Label("알림 추가", systemImage: "plus.circle")
                            .font(.headline)
                            .padding(.trailing)
                    }
                }

                // 알림 목록
                ReminderListView()
            }
            .navigationTitle("복용 알림")
        }
    }
}

#Preview {
    ReminderTabView()
}

