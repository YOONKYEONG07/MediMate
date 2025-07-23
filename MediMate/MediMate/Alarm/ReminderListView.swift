import SwiftUI

struct ReminderListView: View {
    @State private var reminders: [MedicationReminder] = []
    @State private var showingAddView = false
    @State private var showingHistoryView = false
    @State private var editingReminder: MedicationReminder? = nil  // ✅ sheet(item:)용

    var body: some View {
        NavigationView {
            List {
                ForEach(reminders, id: \.id) { reminder in
                    Button {
                        editingReminder = reminder  // ✅ 이게 곧 sheet trigger
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.name)
                                    .font(.headline)
                                Text(String(format: "🕒 %02d:%02d", reminder.hour, reminder.minute))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                               
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
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
            .font(.title2)
            .bold()
            .onAppear {
                reminders = NotificationManager.instance.loadReminders()
            }
            .sheet(isPresented: $showingAddView) {
                ReminderAddView()
            }
            .sheet(isPresented: $showingHistoryView) {
                HistoryView()
            }
            // ✅ 안정적 sheet 방식 (ID 바뀌거나 상태 꼬임 방지)
            .sheet(item: $editingReminder) { reminder in
                if let binding = binding(for: reminder.id) {
                    ReminderEditView(
                        reminder: binding,
                        onDelete: {
                            self.reminders = NotificationManager.instance.loadReminders()
                            self.editingReminder = nil
                        },
                        onSave: {
                            self.reminders = NotificationManager.instance.loadReminders()
                            self.editingReminder = nil
                        }
                    )
                } else {
                    Text("❌ 알림을 불러올 수 없습니다.")
                        .font(.title2)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
    }

    // 삭제 함수
    func deleteReminderByID(_ id: String) {
        NotificationManager.instance.deleteReminder(id: id)
        reminders.removeAll { $0.id == id }
    }

    // 특정 알림 바인딩 찾기
    func binding(for id: String?) -> Binding<MedicationReminder>? {
        guard let id = id else { return nil }
        if let index = reminders.firstIndex(where: { $0.id == id }) {
            return $reminders[index]
        }
        return nil
    }
}

