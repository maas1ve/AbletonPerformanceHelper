import Foundation
import UserNotifications

class NotificationHelper {
    static func sendNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                center.add(request, withCompletionHandler: nil)
            }
        }
    }
}
