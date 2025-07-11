import SwiftUI

struct ReportView: View {
    @State private var selectedTab = 0 // 0: 월간 캘린더, 1: 주간 리포트
    @State private var selectedDate: Date? = nil
    @State private var currentWeekStart: Date = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!.start

    // ✅ 더미 복약 기록
    let dummyRecords: [Date: Bool] = [
        Calendar.current.date(from: DateComponents(year: 2025, month: 7, day: 1))!: true,
        Calendar.current.date(from: DateComponents(year: 2025, month: 7, day: 2))!: true,
        Calendar.current.date(from: DateComponents(year: 2025, month: 7, day: 3))!: false,
        Calendar.current.date(from: DateComponents(year: 2025, month: 7, day: 5))!: true,
        Calendar.current.date(from: DateComponents(year: 2025, month: 7, day: 7))!: false,
        Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 24))!: true,
        Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 26))!: false,
        Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 29))!: true
    ]

    var body: some View {
        NavigationView {
            VStack {
                // ✅ 탭 선택
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
                                records: dummyRecords,
                                onDateSelected: onDateSelected
                            )
                            .padding(.horizontal)

                            if let selectedDate = selectedDate,
                               let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start {
                                WeeklyDetailCard(weekStart: weekStart, records: dummyRecords)
                                    .transition(.slide)
                            }
                        }
                    } else {
                        // ✅ 버튼으로 조작하는 카드
                        VStack(spacing: 12) {
                            WeeklyReportCardView(
                                weekRange: weekDateRangeString(from: currentWeekStart),
                                successRate: successRate(for: currentWeekStart),
                                isCurrentWeek: Calendar.current.isDate(currentWeekStart, equalTo: Date(), toGranularity: .weekOfYear)
                            )

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
                        .frame(height: 300)
                    }
                }
                Spacer()
            }
            .navigationTitle("리포트 보기")
        }
    }

    // ✅ 날짜 선택 핸들러
    func onDateSelected(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
    }

    // ✅ 현재 주 변경
    func moveWeek(by offset: Int) {
        if let newWeek = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart),
           let newStart = Calendar.current.dateInterval(of: .weekOfYear, for: newWeek)?.start {
            currentWeekStart = newStart
        }
    }

    // ✅ 주간 성공률 계산
    func successRate(for weekStart: Date) -> Int {
        let calendar = Calendar.current
        let dates = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }

        let successes = dates.filter {
            dummyRecords[calendar.startOfDay(for: $0)] == true
        }.count

        return Int((Double(successes) / 7.0) * 100)
    }

    // ✅ 날짜 범위 텍스트
    func weekDateRangeString(from startDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"

        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startDate)!
        return "\(formatter.string(from: startDate)) ~ \(formatter.string(from: endDate))"
    }
}
