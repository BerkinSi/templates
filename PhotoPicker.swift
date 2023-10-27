import UIKit
import Photos
import AVFoundation

protocol PhotoPickerDelegate: AnyObject {
    func photoPickerDidSelect(image: UIImage?)
    func presentActionSheet(actionSheet: UIAlertController)
    func presentImagePicker(imagePicker: UIImagePickerController)
    func presentLimitedLib()
}

class PhotoPicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Define error type
    enum PhotoPickerError: Error {
        case accessRestricted
        case accessDenied
    }
    
    typealias PermissionDeniedHandler = (PhotoPickerError) -> Void
    
    private var imagePicker = UIImagePickerController()
    private weak var delegate: PhotoPickerDelegate?
    
    var onPermissionDenied: PermissionDeniedHandler?
    
    init(delegate: PhotoPickerDelegate) {
        super.init()
        self.delegate = delegate
        
        imagePicker.delegate = self
    }
    
    func presentPhotoOptions() {
        let actionSheet = UIAlertController(title: "Choose a source", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        delegate?.presentActionSheet(actionSheet: actionSheet)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        if sourceType == .photoLibrary {
            let photosAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
            
            switch photosAuthorizationStatus {
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { newStatus in
                    if newStatus == .authorized {
                        DispatchQueue.main.async {
                            showImagePickerForLibrary()
                        }
                    }
                }
            case .authorized:
                showImagePickerForLibrary()
            case .denied:
                onPermissionDenied?(.accessDenied)
            case .restricted:
                onPermissionDenied?(.accessRestricted)
            case .limited:
                // Ask if they'd like to modify their photo access selection
                let alert = UIAlertController(title: "Modify Photo Access",
                                              message: "Would you like to change which photos this app can access?",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Modify", style: .default, handler: { _ in
                    // Present the limited library picker to let the user modify their selection
                    self.delegate?.presentLimitedLib()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                delegate?.presentActionSheet(actionSheet: alert)
            @unknown default:
                break
            }
            
            func showImagePickerForLibrary() {
                imagePicker.mediaTypes = ["public.image"]
                imagePicker.allowsEditing = true
                imagePicker.sourceType = .photoLibrary
                imagePicker.accessibilityHint = "Select a photo to use for your profile."
                delegate?.presentImagePicker(imagePicker: imagePicker)
            }
        } else if sourceType == .camera {
            let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            
            switch cameraAuthorizationStatus {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        DispatchQueue.main.async {
                            showImagePickerForCamera()
                        }
                    }
                }
            case .authorized:
                showImagePickerForCamera()
            case .denied:
                onPermissionDenied?(.accessDenied)
            case .restricted:
                onPermissionDenied?(.accessRestricted)
            @unknown default:
                break
            }
            
            func showImagePickerForCamera() {
                imagePicker.mediaTypes = ["public.image"]
                imagePicker.allowsEditing = true
                imagePicker.sourceType = .camera
                delegate?.presentImagePicker(imagePicker: imagePicker)
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        delegate?.photoPickerDidSelect(image: selectedImage)
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
