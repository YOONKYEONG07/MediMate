import Foundation
import CoreGraphics

struct RecognizedTextItem: Identifiable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect // VN에서 추출한 상대 좌표 (0~1)
}

