import SwiftUI

struct ReminderListView: View {
    @State private var reminders: [MedicationReminder] = []
    @State private var showingAddView = false
    @State private var showingHistoryView = false
    @State private var editingReminder: MedicationReminder? = nil

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {

                List {
                    Section(header:
                        Text("복용 알림 목록")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, -20)
                    ) {
                        ForEach(reminders, id: \.id) { reminder in
                            Button {
                                editingReminder = reminder
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(reminder.name)
                                            .font(.headline)

                                        let times = zip(reminder.hours, reminder.minutes)
                                            .map { hour, minute in
                                                String(format: "%02d:%02d", hour, minute)
                                            }
                                            .joined(separator: ", ")

                                        Text("🕒 \(times)")
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
            }
            .navigationBarHidden(true)
            .onAppear {
                reminders = NotificationManager.instance.loadReminders()
            }

            .sheet(isPresented: $showingAddView) {
                ReminderAddView(onSave: {
                    self.reminders = NotificationManager.instance.loadReminders()
                })
            }

            .sheet(isPresented: $showingHistoryView) {
                HistoryView()
            }

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

    func deleteReminderByID(_ id: String) {
        NotificationManager.instance.deleteReminder(id: id)
        reminders.removeAll { $0.id == id }
    }

    func binding(for id: String?) -> Binding<MedicationReminder>? {
        guard let id = id else { return nil }
        if let index = reminders.firstIndex(where: { $0.id == id }) {
            return $reminders[index]
        }
        return nil
    }
}

