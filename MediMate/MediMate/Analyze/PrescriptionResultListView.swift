import SwiftUI

struct PrescriptionResultListView: View {
    let detectedMeds: [String]

    var body: some View {
        List(detectedMeds, id: \.self) { med in
            NavigationLink(destination: MedicationDetailView(medName: med, previousScreenTitle: "인식된 약 목록")) {
                Text(med)
            }
        }
        .navigationTitle("인식된 약 목록")
    }
}
