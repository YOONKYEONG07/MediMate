import SwiftUI

struct PrescriptionResultListView: View {
    let detectedMeds: [String]

    var body: some View {
        List(detectedMeds, id: \.self) { med in
            NavigationLink(destination: MedicationDetailView(medName: med)) {
                Text(med)
            }
        }
        .navigationTitle("인식된 약 목록")
    }
}
