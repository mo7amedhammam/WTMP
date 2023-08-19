import SwiftUI
import AVFoundation
import CoreMotion
import Photos

struct DTMPView: View {
    @State private var motionManager = CMMotionManager()
    @State private var isMotionDetectionActive = false
    @State private var isPasscodeSettingActive = false
    @State private var enteredPasscode = ""
    @StateObject private var photoCaptureHandler = PhotoCaptureHandler()
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Text("DTMP")
                        .font(.largeTitle)
                    Spacer()
                    Image(systemName: "camera.fill")
                        .font(.title)
                        .foregroundColor(.black)
                }

                Spacer()
                Button(action: {
                    handlePlayStopButtonTap()
                }) {
                    Text(isMotionDetectionActive ? "Stop" : "Start")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isMotionDetectionActive ? Color.red : Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom)
            .sheet(isPresented: $isPasscodeSettingActive) {
                PasswordValidationView(
                    isPasscodeSettingActive: $isPasscodeSettingActive,
                    enteredPasscode: $enteredPasscode,
                    stopMotionDetection: stopMotionDetection,
                    stopSoundPlay: {})
            }
        }
        .onAppear {
            configureMotionDetection()
        }
        .onDisappear {
            stopMotionDetection()
        }
    }
    
    private func configureMotionDetection() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.2
            motionManager.startAccelerometerUpdates(to: .main) { accelerometerData, error in
                if let acceleration = accelerometerData?.acceleration {
                    let magnitude = sqrt(acceleration.x * acceleration.x +
                                         acceleration.y * acceleration.y +
                                         acceleration.z * acceleration.z)

                    let movementThreshold: Double = 1.2

                    if magnitude > movementThreshold && isMotionDetectionActive {
                        capturePhotoInBackground()
                    }
                }
            }
        }
    }
    
    private func handlePlayStopButtonTap() {
        if let savedPasscode = UserDefaults.standard.string(forKey: "passcode"), !savedPasscode.isEmpty {
            if !isMotionDetectionActive {
                toggleMotionDetection()
            } else {
                isPasscodeSettingActive = true
            }
        } else {
            isPasscodeSettingActive = true
        }
    }
    
    private func toggleMotionDetection() {
        if isMotionDetectionActive {
            stopMotionDetection()
        } else {
            startMotionDetection()
        }
    }
    
    private func startMotionDetection() {
        isMotionDetectionActive = true
    }
    
    private func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
        isMotionDetectionActive = false
        endBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func capturePhotoInBackground() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [self] in
            self.endBackgroundTask()
        }
        
        DispatchQueue.global(qos: .background).async {
            self.capturePhoto()
        }
    }
    
    private func capturePhoto() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Front camera not available.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            let photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                
                captureSession.startRunning()
                
                let settings = AVCapturePhotoSettings()
                settings.flashMode = .on // Try different flash modes like .on or .off
                settings.photoQualityPrioritization = .balanced // You can experiment with different prioritizations
                if let availableFormat = photoOutput.availablePhotoPixelFormatTypes.first {
                           settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: availableFormat]
                       }
                photoOutput.capturePhoto(with: settings, delegate: photoCaptureHandler)
            }
        } catch {
            print("Error setting up camera input: \(error.localizedDescription)")
        }
    }
}

struct DTMPView_Previews: PreviewProvider {
    static var previews: some View {
        DTMPView()
    }
}

class PhotoCaptureHandler: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage?
    @Published var captureError: Error?

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            capturedImage = image
            captureError = nil
            savePhotoToLibrary(image)
        } else {
            capturedImage = nil
            captureError = error
        }
    }
    
    private func savePhotoToLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    if let error = error {
                        print("Error saving photo to library: \(error.localizedDescription)")
                    } else {
                        print("Photo saved to library successfully.")
                    }
                }
            } else {
                print("Permission denied to access photo library.")
            }
        }
    }
}
