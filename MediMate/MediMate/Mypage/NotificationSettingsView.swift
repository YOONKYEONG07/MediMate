import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("medicationReminders") private var medicationReminders = true
    @AppStorage("marketingConsent") private var marketingConsent = true

    var body: some View {
        Form {
            Section(header: Text("전체 알림")) {
                Toggle(isOn: $notificationsEnabled) {
                    Label("알림 받기", systemImage: "bell.fill")
                }
                .onChange(of: notificationsEnabled) {
                    if !notificationsEnabled {
                        medicationReminders = false
                        marketingConsent = false
                    } else {
                        medicationReminders = true
                        marketingConsent = true
                    }
                }
            }

            if notificationsEnabled {
                Section(header: Text("세부 알림 설정")) {
                    Toggle("복용 알람", isOn: $medicationReminders)
                    Toggle("광고성 알림 수신", isOn: $marketingConsent)
                }
            }
        }
        .navigationTitle("알림 설정")
    }
}
