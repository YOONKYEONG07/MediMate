import SwiftUI

struct OCRResultOverlayView: View {
    let image: UIImage
    let items: [RecognizedTextItem]
    var onTextTapped: (String) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width)

                ForEach(items) { item in
                    let rect = item.boundingBox
                    let x = rect.origin.x * geometry.size.width
                    let y = (1 - rect.origin.y - rect.height) * geometry.size.height
                    let w = rect.width * geometry.size.width
                    let h = rect.height * geometry.size.height

                    Button(action: {
                        onTextTapped(item.text)
                    }) {
                        Text(item.text)
                            .font(.caption)
                            .padding(4)
                            .background(Color.yellow.opacity(0.9))
                            .cornerRadius(6)
                            .foregroundColor(.black)
                    }
                    .frame(width: w, height: h)
                    .position(x: x + w / 2, y: y + h / 2)
                }
            }
        }
    }
}
