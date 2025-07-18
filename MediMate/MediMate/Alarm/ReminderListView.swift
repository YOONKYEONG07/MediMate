import SwiftUI

struct ReminderListView: View {
    @State private var reminders: [MedicationReminder] = []
    @State private var showingAddView = false
    @State private var showingHistoryView = false

    var body: some View {
        NavigationView {
            List {
                ForEach(reminders) { reminder in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reminder.name)
                                .font(.headline)
                            Text(String(format: "🕒 %02d:%02d", reminder.hour, reminder.minute))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            deleteReminderByID(reminder.id)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 6)
                }

                Section {
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
            }
            .listStyle(InsetGroupedListStyle())
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
    }

    // ❌ 버튼으로 삭제
    func deleteReminderByID(_ id: String) {
        NotificationManager.instance.deleteReminder(id: id)
        reminders.removeAll { $0.id == id }
    }

    // 스와이프 삭제도 가능하게 유지
    func deleteReminder(at offsets: IndexSet) {
        for index in offsets {
            let id = reminders[index].id
            NotificationManager.instance.deleteReminder(id: id)
        }
        reminders.remove(atOffsets: offsets)
    }
}

