import SwiftUI

struct ReminderListView: View {
    @State private var reminders: [MedicationReminder] = []
    @State private var showingAddView = false
    @State private var showingHistoryView = false

    var body: some View {
        List {
            ForEach(reminders) { reminder in
                VStack(alignment: .leading) {
                    Text(reminder.name)
                        .font(.headline)
                    Text(String(format: "%02d:%02d", reminder.hour, reminder.minute))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .onDelete(perform: deleteReminder)

            // 🕓 히스토리 보기 버튼
            Button(action: {
                showingHistoryView = true
            }) {
                HStack {
                    Image(systemName: "clock.fill")
                    Text("복용 히스토리 보기")
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("복용 알림 목록")
        .onAppear {
            reminders = NotificationManager.instance.loadReminders()
        }
        .sheet(isPresented: $showingAddView) {
            ReminderAddView()
        }
        .sheet(isPresented: $showingHistoryView) {
            HistoryView()
        }
    }

    func deleteReminder(at offsets: IndexSet) {
        for index in offsets {
            let id = reminders[index].id
            NotificationManager.instance.deleteReminder(id: id)
        }
        reminders.remove(atOffsets: offsets)
    }
}
