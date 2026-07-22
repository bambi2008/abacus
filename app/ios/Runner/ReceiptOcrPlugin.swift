import Flutter
import UIKit
import Vision

/// On-device receipt text recognition via Apple's Vision framework. The
/// photo never leaves the device — recognition runs locally and only the
/// extracted text lines cross the method channel back to Dart, which does
/// the amount/vendor/date heuristics (see receipt_scan_result.dart). This is
/// an entry-speed assist for Pocklume's manual-first core loop, not a step
/// toward bank sync — see docs/technical-architecture.md.
class ReceiptOcrPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.pocklume.app/receipt_ocr",
            binaryMessenger: registrar.messenger()
        )
        let instance = ReceiptOcrPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "recognizeText":
            guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
                result(FlutterError(code: "bad_args", message: "Missing 'path'", details: nil))
                return
            }
            recognizeText(atPath: path, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func recognizeText(atPath path: String, result: @escaping FlutterResult) {
        guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
            result(FlutterError(code: "bad_image", message: "Could not load image at \(path)", details: nil))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                result(FlutterError(code: "recognition_failed", message: error.localizedDescription, details: nil))
                return
            }
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            result(["lines": lines])
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.01

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .init(image.imageOrientation), options: [:])
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(code: "recognition_failed", message: error.localizedDescription, details: nil))
                }
            }
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
