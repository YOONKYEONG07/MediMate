import SwiftUI

struct TodayMedicationListView: View {
    var body: some View {
        VStack {
            Text("오늘 복용할 약 리스트")
                .font(.title)
                .padding()

            Spacer()
        }
        .navigationTitle("오늘의 복약")
    }
}

