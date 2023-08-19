//
//  DTMPView.swift
//  WTMP
//
//  Created by wecancity on 19/08/2023.
//


import SwiftUI
import AVFoundation
import CoreMotion

struct DTMPView: View {
    @State private var motionManager = CMMotionManager()
    @State private var isMotionDetectionActive = false
    @State private var isPasscodeSettingActive = false
    @State private var enteredPasscode = ""

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
                    handleStartButtonTap()
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
        }
    }

    private func handleStartButtonTap() {
        if let savedPasscode = UserDefaults.standard.string(forKey: "passcode"), !savedPasscode.isEmpty {
            if !isMotionDetectionActive {
                toggleMotionDetection()
            } else {
                isMotionDetectionActive = false
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
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.2
            motionManager.startAccelerometerUpdates(to: .main) { accelerometerData, error in
                if let acceleration = accelerometerData?.acceleration {
                    let magnitude = sqrt(acceleration.x * acceleration.x +
                                         acceleration.y * acceleration.y +
                                         acceleration.z * acceleration.z)

                    let movementThreshold: Double = 1.2

                    if magnitude > movementThreshold && isMotionDetectionActive {
                        capturePhoto()
                    }
                }
            }
        }
    }

    private func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
        isMotionDetectionActive = false
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
                photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate())
            }
            print("capture ")
            
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


class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    var photoCaptureCompletion: ((UIImage?, Error?) -> Void)?

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            photoCaptureCompletion?(image, nil)
            
            // Save the captured image to the photo library
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            
        } else {
            photoCaptureCompletion?(nil, error)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image to photo library: \(error.localizedDescription)")
        } else {
            print("Image saved to photo library successfully.")
        }
    }
}
