import SwiftUI
import FirebaseFirestore
import FirebaseAuth

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
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteReminderByID(reminder)
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
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
                reminders = NotificationManager.instance.loadAllReminders()
            }

            .sheet(isPresented: $showingAddView) {
                ReminderAddView(onSave: {
                    self.reminders = NotificationManager.instance.loadAllReminders()
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
                            self.reminders = NotificationManager.instance.loadAllReminders()
                            self.editingReminder = nil
                        },
                        onSave: {
                            self.reminders = NotificationManager.instance.loadAllReminders()
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

    // ✅ Firestore에서도 조건 검색 후 삭제
    func deleteReminderByID(_ reminder: MedicationReminder) {
        // 🗑 1. 로컬 알림 삭제
        NotificationManager.instance.deleteReminder(id: reminder.id)
        reminders.removeAll { $0.id == reminder.id }

        // ☁️ 2. Firestore 문서 삭제
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ 로그인된 사용자 없음 - Firestore 삭제 취소")
            return
        }

        let db = Firestore.firestore()
        db.collection("reminders")
            .whereField("userID", isEqualTo: userID)
            .whereField("medName", isEqualTo: reminder.name)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore 삭제 실패: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("⚠️ Firestore 문서 없음")
                    return
                }

                for doc in documents {
                    db.collection("reminders").document(doc.documentID).delete { error in
                        if let error = error {
                            print("❌ 문서 삭제 실패: \(error.localizedDescription)")
                        } else {
                            print("✅ Firestore 문서 삭제 완료")
                        }
                    }
                }
            }
    }

    func binding(for id: String?) -> Binding<MedicationReminder>? {
        guard let id = id else { return nil }
        if let index = reminders.firstIndex(where: { $0.id == id }) {
            return $reminders[index]
        }
        return nil
    }
}

