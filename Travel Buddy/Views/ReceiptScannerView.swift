//
//  ReceiptScannerView.swift
//  Split Voyage Group Travel
//
//  Created by Shanique Beckford on 3/12/26.
//

import SwiftUI
import VisionKit

struct ReceiptScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var scannedImage: UIImage?
    @Binding var extractedAmount: Double?
    
    @State private var isShowingScanner = false
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = scannedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                
                if isProcessing {
                    ProgressView("Extracting amount...")
                } else if let amount = extractedAmount {
                    Text("Detected Amount: $\(amount, specifier: "%.2f")")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
                
                HStack {
                    Button("Retake") {
                        scannedImage = nil
                        extractedAmount = nil
                        isShowingScanner = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Use This Photo") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text("Scan Receipt")
                        .font(.title2)
                    
                    Text("Take a photo of your receipt to automatically extract the amount")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                
                Button("Open Camera") {
                    isShowingScanner = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .navigationTitle("Scan Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingScanner) {
            ImagePicker(image: $scannedImage, extractedAmount: $extractedAmount, isProcessing: $isProcessing, errorMessage: $errorMessage, showingError: $showingError)
        }
        .alert("Camera Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

// Image Picker with OCR
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var extractedAmount: Double?
    @Binding var isProcessing: Bool
    @Binding var errorMessage: String
    @Binding var showingError: Bool
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // Check if camera is available
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            DispatchQueue.main.async {
                errorMessage = "Camera is not available on this device"
                showingError = true
            }
        }
        
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.isProcessing = true
                
                // Extract text from image
                Task {
                    await parent.extractAmount(from: image)
                    await MainActor.run {
                        parent.isProcessing = false
                    }
                }
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func extractAmount(from image: UIImage) async {
        guard let cgImage = image.cgImage else {
            await MainActor.run {
                self.errorMessage = "Failed to process image"
                self.showingError = true
            }
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        
        do {
            try requestHandler.perform([request])
            
            if let observations = request.results {
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    let text = topCandidate.string
                    
                    // Look for currency amounts
                    if let amount = parseAmount(from: text) {
                        await MainActor.run {
                            self.extractedAmount = amount
                        }
                        return
                    }
                }
            }
            
            // No amount found
            await MainActor.run {
                self.errorMessage = "Could not detect amount. You can enter it manually."
                self.showingError = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "OCR failed: \(error.localizedDescription)"
                self.showingError = true
            }
        }
    }
    
    private func parseAmount(from text: String) -> Double? {
        // Remove common currency symbols and clean the text
        let _ = text.replacingOccurrences(of: "$", with: "")
                         .replacingOccurrences(of: ",", with: "")
                         .trimmingCharacters(in: .whitespaces)
        
        // Look for patterns like "Total: 123.45" or just "123.45"
        let patterns = [
            #"(?:total|amount|subtotal|sum)[:\s]*([0-9]+\.?[0-9]{0,2})"#,
            #"\b([0-9]+\.[0-9]{2})\b"#,
            #"\b([0-9]+)\b"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range) {
                    let matchRange = match.range(at: 1)
                    if matchRange.location != NSNotFound,
                       let range = Range(matchRange, in: text),
                       let amount = Double(text[range]) {
                        return amount
                    }
                }
            }
        }
        
        return nil
    }
}

import Vision

#Preview {
    NavigationStack {
        ReceiptScannerView(scannedImage: .constant(nil), extractedAmount: .constant(nil))
    }
}
