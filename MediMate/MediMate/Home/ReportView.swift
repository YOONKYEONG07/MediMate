import SwiftUI

struct ReportView: View {
    @State private var selectedTab = 0
    @State private var selectedDate: Date? = nil
    @State private var currentWeekStart: Date = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!.start

    @State private var records: [Date: Bool] = [:]

    var body: some View {
        NavigationView {
            VStack {
                Picker("보기 타입", selection: $selectedTab) {
                    Text("월간 캘린더").tag(0)
                    Text("주간 리포트").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                ZStack {
                    if selectedTab == 0 {
                        ScrollView {
                            CalendarView(
                                records: records,
                                onDateSelected: onDateSelected
                            )
                            .padding(.horizontal)

                            if let selectedDate = selectedDate,
                               let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start {
                                WeeklyDetailCard(weekStart: weekStart, records: records)
                                    .transition(.slide)
                            }
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                WeeklyReportCardView(
                                    weekRange: weekDateRangeString(from: currentWeekStart),
                                    successRate: Int(successRate(for: currentWeekStart)),
                                    isCurrentWeek: Calendar.current.isDate(currentWeekStart, equalTo: Date(), toGranularity: .weekOfYear)
                                )
                                .padding(.top, 16)
                                .padding(.horizontal)

                                WeeklyReportChartView(
                                    records: records,
                                    weekStart: currentWeekStart,
                                    averageRates: dailySuccessRates(for: currentWeekStart),
                                    weeklyAverage: successRate(for: currentWeekStart)
                                )
                                .padding(.top, 8)
                                .padding(.horizontal)

                                HStack {
                                    Button(action: {
                                        withAnimation {
                                            moveWeek(by: -1)
                                        }
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .padding()
                                    }

                                    Spacer()

                                    Button(action: {
                                        withAnimation {
                                            moveWeek(by: 1)
                                        }
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .padding()
                                    }
                                }
                                .padding(.horizontal, 60)
                            }
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("리포트 보기")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadRecords()
            }
        }
    }

    func onDateSelected(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
    }

    func moveWeek(by offset: Int) {
        if let newWeek = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart),
           let newStart = Calendar.current.dateInterval(of: .weekOfYear, for: newWeek)?.start {
            currentWeekStart = newStart
        }
    }

    func successRate(for weekStart: Date) -> Double {
        let calendar = Calendar.current
        let reminders = NotificationManager.instance.loadAllReminders()

        let dates = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }

        let dailyRates: [Double] = dates.map { date in
            let key = todayString(from: date)
            let takenIDs = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])

            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let weekdaySymbol = ["일", "월", "화", "수", "목", "금", "토"][weekdayIndex]

            let dosesForDay = reminders.flatMap { reminder in
                reminder.days.contains(weekdaySymbol) ? zip(reminder.hours, reminder.minutes).map { hour, minute in
                    "\(reminder.id)_\(hour)_\(minute)"
                } : []
            }

            guard !dosesForDay.isEmpty else { return Double.nan }

            let completed = dosesForDay.filter { takenIDs.contains($0) }.count
            return Double(completed) / Double(dosesForDay.count)
        }

        let validRates = dailyRates.filter { !$0.isNaN }
        let avg = validRates.isEmpty ? 0.0 : validRates.reduce(0, +) / Double(validRates.count)
        return avg * 100
    }

    func dailySuccessRates(for weekStart: Date) -> [Double] {
        let calendar = Calendar.current
        let reminders = NotificationManager.instance.loadAllReminders()

        let dates = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }

        return dates.map { date in
            let key = todayString(from: date)
            let takenIDs = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])

            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let weekdaySymbol = ["일", "월", "화", "수", "목", "금", "토"][weekdayIndex]

            let doseIDs = reminders.flatMap { reminder in
                reminder.days.contains(weekdaySymbol) ? zip(reminder.hours, reminder.minutes).map { hour, minute in
                    "\(reminder.id)_\(hour)_\(minute)"
                } : []
            }

            guard !doseIDs.isEmpty else { return Double.nan } // ✅ 핵심 수정

            let completed = doseIDs.filter { takenIDs.contains($0) }.count
            return Double(completed) / Double(doseIDs.count)
        }
    }

    private func todayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func weekDateRangeString(from startDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"

        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
        return "\(formatter.string(from: startDate)) ~ \(formatter.string(from: endDate))"
    }

    func loadRecords() {
        DoseRecordManager.shared.fetchWeeklyDoseRecords(userID: "testUser123") { result in
            DispatchQueue.main.async {
                let normalized: [Date: Bool] = result.reduce(into: [:]) { acc, pair in
                    let key = Calendar.current.startOfDay(for: pair.key)
                    acc[key] = pair.value
                }
                self.records = normalized
                print("📥 불러온 복약 기록 개수: \(normalized.count)")
            }
        }
    }
}
