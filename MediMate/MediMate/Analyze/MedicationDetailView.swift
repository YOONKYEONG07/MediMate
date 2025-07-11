import SwiftUI

struct MedicationDetailView: View {
    var medName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(medName)
                            .font(.largeTitle)
                            .bold()
                        Text("이 약은 감기 증상을 완화해주는 일반의약품입니다")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        HStack {
                            Label("하료저", systemImage: "cross.case.fill")
                            Text("OTC")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    Spacer()

                    Image("pill_image")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Divider()

                GroupBox(label: Label("성분", systemImage: "pills")) {
                    VStack(alignment: .leading) {
                        Text("• 아세트아미노펜 (해열/진통)")
                        Text("• 클로르페니라민 (항히스타민)")
                    }
                }

                GroupBox(label: Label("효능", systemImage: "cross.case")) {
                    Text("감기 증상 완화 (콧물, 발열 등)")
                }

                GroupBox(label: Label("복용법", systemImage: "capsule.portrait")) {
                    Text("하루 3회, 1회 1정씩 복용")
                }

                HStack {
                    GroupBox(label: Label("식전/식후 여부", systemImage: "clock")) {
                        Text("식후 30분 이내에 복용")
                    }
                    GroupBox(label: Label("1일 복용횟수", systemImage: "number")) {
                        Text("1일 최대 3정 (4시간 간격)")
                    }
                }

                GroupBox(label: Label("주의사항", systemImage: "exclamationmark.triangle")) {
                    Text("졸음 유발 가능성 있음, 운전 주의")
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("약 성분 분석 결과")
    }
}
