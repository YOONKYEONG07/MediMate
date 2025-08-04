import Vision
import UIKit

func performVisionOCR(on image: UIImage, completion: @escaping ([String], [CGRect]) -> Void) {
    guard let cgImage = image.cgImage else {
        completion([], [])
        return
    }

    let request = VNRecognizeTextRequest { request, error in
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            completion([], [])
            return
        }

        let knownMeds = ["타이레놀", "게보린", "판콜에이", "신일이부프로펜", "알마겔", "서스펜",
                         "부루펜", "타세놀", "지르텍", "펜잘", "이부프로펜", "신풍이부펜"]

        var matchedTexts: [String] = []
        var matchedBoxes: [CGRect] = []

        for observation in results {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string
            if knownMeds.contains(where: { text.contains($0) }) {
                matchedTexts.append(text)
                matchedBoxes.append(observation.boundingBox)
            }
        }

        completion(matchedTexts, matchedBoxes)
    }

    request.recognitionLevel = .accurate
    request.recognitionLanguages = ["ko-KR", "en-US"]
    request.usesLanguageCorrection = true

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global().async {
        do {
            try handler.perform([request])
        } catch {
            print("OCR 오류: \(error)")
            completion([], [])
        }
    }
}
