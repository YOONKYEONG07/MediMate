import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Public API
func performVisionOCR(on image: UIImage, completion: @escaping ([String], [CGRect]) -> Void) {
    // 전처리 모드 2가지: 흑백+대비 / 원본색(전처리 최소)
    let modes: [PreMode] = [.monoStrong, .colorSoft]
    tryOCR(with: modes, image: image) { texts, boxes in
        DispatchQueue.main.async { completion(texts, boxes) }
    }
}

// 여러 전처리 모드 순차 시도 + 타일링 fallback
private func tryOCR(with modes: [PreMode], image: UIImage,
                    completion: @escaping ([String],[CGRect]) -> Void) {
    var idx = 0
    func next() {
        guard idx < modes.count else { completion([], []); return }
        let mode = modes[idx]; idx += 1

        guard let cg = preprocessImage(image, mode: mode, maxDim: 3200) else { next(); return }

        // 1차: 전체
        ocrOnce(cgImage: cg, roi: nil, minTextHeight: 0.004) { t1, b1 in
            if t1.count >= 3 {
                completion(t1, b1); return
            }
            // 2차: 3x3 타일(오버랩 10%)
            let tiles = tiledROIs(rows: 3, cols: 3, overlap: 0.10)
            var all: [(String, CGRect)] = []
            let g = DispatchGroup()
            for r in tiles {
                g.enter()
                ocrOnce(cgImage: cg, roi: r, minTextHeight: 0.004) { tt, bb in
                    all.append(contentsOf: zip(tt, bb)); g.leave()
                }
            }
            g.notify(queue: .global(qos: .userInitiated)) {
                let merged = mergeByIOU(pairs: all, iouThreshold: 0.25)
                if merged.isEmpty {
                    // 다음 전처리 모드로 재시도
                    next()
                } else {
                    completion(merged.map{$0.0}, merged.map{$0.1})
                }
            }
        }
    }
    next()
}

// MARK: - 1회 OCR
private func ocrOnce(cgImage: CGImage,
                     roi: CGRect?,
                     minTextHeight: Float,
                     completion: @escaping ([String], [CGRect]) -> Void) {
    let request = VNRecognizeTextRequest { request, _ in
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            completion([], []); return
        }
        var texts: [String] = []
        var boxes: [CGRect] = []
        for obs in results {
            guard let best = obs.topCandidates(1).first else { continue }
            let line = best.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            // 긴 줄 토큰 분리
            let tokens = line.components(separatedBy: .whitespaces)
                              .map{$0.trimmingCharacters(in: .whitespaces)}
                              .filter{!$0.isEmpty}
            for tok in tokens {
                texts.append(tok)
                boxes.append(obs.boundingBox)
            }
        }
        completion(texts, boxes)
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.automaticallyDetectsLanguage = false
    request.recognitionLanguages = ["ko-KR"] // 숫자/기호 섞여도 보통 이게 안정적
    request.minimumTextHeight = minTextHeight
    if #available(iOS 16.0, *) { request.revision = VNRecognizeTextRequestRevision3 }
    if let roi = roi { request.regionOfInterest = roi }

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
        do { try handler.perform([request]) } catch { completion([], []) }
    }
}

// MARK: - 전처리
private enum PreMode { case monoStrong, colorSoft }

private func preprocessImage(_ uiImage: UIImage, mode: PreMode, maxDim: CGFloat) -> CGImage? {
    let img = fixOrientation(uiImage)
    let scale = min(maxDim / max(img.size.width, img.size.height), 1.0)
    let size = CGSize(width: img.size.width * scale, height: img.size.height * scale)
    let resized = UIGraphicsImageRenderer(size: size).image { _ in
        img.draw(in: CGRect(origin: .zero, size: size))
    }
    guard let ci = CIImage(image: resized) else { return resized.cgImage }
    let ctx = CIContext()

    switch mode {
    case .monoStrong:
        let noir = CIFilter.photoEffectNoir(); noir.inputImage = ci
        let ctrl = CIFilter.colorControls()
        ctrl.inputImage = noir.outputImage
        ctrl.contrast = 1.38
        ctrl.brightness = 0.03
        ctrl.saturation = 0.0
        let sharp = CIFilter.sharpenLuminance()
        sharp.inputImage = ctrl.outputImage
        sharp.sharpness = 0.65
        let out = sharp.outputImage ?? ctrl.outputImage ?? ci
        return ctx.createCGImage(out, from: out.extent)

    case .colorSoft:
        // 컬러 유지, 가벼운 선명/대비만
        let sharp = CIFilter.sharpenLuminance()
        sharp.inputImage = ci
        sharp.sharpness = 0.4
        let ctrl = CIFilter.colorControls()
        ctrl.inputImage = sharp.outputImage
        ctrl.contrast = 1.18
        ctrl.brightness = 0.01
        ctrl.saturation = 1.0
        let out = ctrl.outputImage ?? ci
        return ctx.createCGImage(out, from: out.extent)
    }
}

private func fixOrientation(_ image: UIImage) -> UIImage {
    if image.imageOrientation == .up { return image }
    let r = UIGraphicsImageRenderer(size: image.size)
    return r.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
}

// MARK: - 타일/병합 유틸
private func tiledROIs(rows: Int, cols: Int, overlap: CGFloat) -> [CGRect] {
    var rois: [CGRect] = []
    let stepW = 1.0 / CGFloat(cols), stepH = 1.0 / CGFloat(rows)
    let ox = stepW * overlap, oy = stepH * overlap
    for r in 0..<rows {
        for c in 0..<cols {
            var x = CGFloat(c)*stepW, y = CGFloat(r)*stepH
            var w = stepW, h = stepH
            x = max(0, x - ox/2); y = max(0, y - oy/2)
            w = min(1 - x, w + ox); h = min(1 - y, h + oy)
            rois.append(CGRect(x: x, y: y, width: w, height: h))
        }
    }
    return rois
}

private func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
    let inter = a.intersection(b)
    if inter.isNull || inter.isEmpty { return 0 }
    let interArea = inter.width*inter.height
    let unionArea = a.width*a.height + b.width*b.height - interArea
    return unionArea > 0 ? interArea/unionArea : 0
}

private func mergeByIOU(pairs: [(String, CGRect)], iouThreshold: CGFloat) -> [(String, CGRect)] {
    var out: [(String, CGRect)] = []
    for (t,b) in pairs {
        var merged = false
        for i in 0..<out.count where out[i].0 == t && iou(out[i].1, b) >= iouThreshold {
            out[i].1 = out[i].1.union(b); merged = true; break
        }
        if !merged { out.append((t,b)) }
    }
    return out
}
