import SwiftUI

struct ReportView: View {
    @State private var selectedTab = 0
    @State private var selectedDate: Date? = nil
    @State private var currentWeekStart: Date = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!.start

    // ✅ 실제 Firestore에서 불러온 복약 기록
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
                                    averageRates: Array(repeating: Double(successRate(for: currentWeekStart)), count: 7)
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

    // ✅ 날짜 선택 핸들러
    func onDateSelected(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
    }

    // ✅ 주 이동
    func moveWeek(by offset: Int) {
        if let newWeek = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart),
           let newStart = Calendar.current.dateInterval(of: .weekOfYear, for: newWeek)?.start {
            currentWeekStart = newStart
        }
    }

    // ✅ 주간 성공률 계산
    func successRate(for weekStart: Date) -> Double {
        let calendar = Calendar.current
        let dates = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }

        let successes = dates.filter {
            let key = calendar.startOfDay(for: $0)
            return records[key] == true
        }.count

        return Double(successes) / 7.0
    }

    // ✅ 날짜 범위 문자열
    func weekDateRangeString(from startDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"

        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
        return "\(formatter.string(from: startDate)) ~ \(formatter.string(from: endDate))"
    }

    // ✅ Firestore에서 복약 기록 불러오기
    func loadRecords() {
        DoseRecordManager.shared.fetchWeeklyDoseRecords(userID: "testUser123") { result in
            DispatchQueue.main.async {
                // 🔁 모든 기록 날짜를 시작 날짜 기준으로 통일
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

