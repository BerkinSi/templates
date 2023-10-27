import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    // Request user's permission to show notifications
    func requestNotificationAuthorization(viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if !granted {
                    // You can present an alert to guide users to turn on notifications in settings
                    let alert = UIAlertController(title: "Enable Notifications", message: "Please enable notifications in Settings to stay updated.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl, completionHandler: nil)
                        }
                    })
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    viewController.present(alert, animated: true)
                }
                completion(granted)
            }
        }
    }

    // Schedule a local notification
    func scheduleNotification(hour: Int, minute: Int, message: String) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Create the content for the notification
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = message
        content.sound = .default

        // Specify date components for the trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create the request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // Add the notification request
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
