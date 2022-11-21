import AppKit
import Logging
import MQTTNIO
import SwiftSlash

@main
public struct MqttDisplay {
    static let logger = Logger(label: "mqtt_display")

    struct Config {
        private let env = ProcessInfo.processInfo.environment

        lazy var url = URL(string: env["MQTT_URL", default: "mqtt://localhost"])!

        lazy var hostname = String(Host.current().name!.split(separator: ".").first!)
        lazy var clientId = "mqtt_display.\(hostname).\(UUID())"

        lazy var stateTopic = "\(hostname)/display"
        lazy var commandTopic = "\(hostname)/display/set"
        lazy var availableTopic = "\(hostname)/display/available"

        lazy var onPayload = "on"
        lazy var offPayload = "off"
        lazy var availablePayload = "online"
        lazy var unavailablePayload = "offline"
    }

    private static func currentState() -> Bool {
        return CGDisplayIsAsleep(CGMainDisplayID()) == 0
    }

    private static func runAsync(_ command: String, _ arguments: String...) {
        Task {
            do {
                let result = try await Command(execute: command, arguments: arguments).runSync()
                if result.exitCode != 0 {
                    logger.error("exit code \(result.exitCode)", source: command)
                }
            } catch let error {
                logger.error("\(error)", source: command)
            }
        }
    }

    // swiftlint:disable:next function_body_length
    public static func main() {
        var config = Config()

        let mqtt = MQTTClient(
            configuration: .init(
                url: config.url,
                clientId: config.clientId,
                credentials: config.url.user != nil ? .init(
                    username: config.url.user!,
                    password: config.url.password
                ) : nil,
                willMessage: .init(
                    topic: config.availableTopic,
                    payload: config.unavailablePayload,
                    qos: .atLeastOnce,
                    retain: true
                ),
                keepAliveInterval: .seconds(30),
                connectionTimeoutInterval: .seconds(30),
                reconnectMode: .retry(minimumDelay: .seconds(1), maximumDelay: .seconds(30))
            ),
            logger: logger
        )

        mqtt.whenConnected { _ in
            mqtt.subscribe(
                to: config.commandTopic
            )
            mqtt.publish(
                config.availablePayload,
                to: config.availableTopic,
                qos: .atLeastOnce,
                retain: true
            )
            mqtt.publish(
                currentState() ? config.onPayload : config.offPayload,
                to: config.stateTopic,
                qos: .atLeastOnce,
                retain: true
            )
        }
        mqtt.whenMessage { message in
            switch message.topic {
            case config.commandTopic:
                switch message.payload.string {
                case config.onPayload:
                    runAsync("/usr/bin/caffeinate", "-u", "-t", "-1")
                case config.offPayload:
                    runAsync("/usr/bin/pmset", "displaysleepnow")
                default:
                    logger.warning("invalid payload: \(message.payload.string ?? "<empty>")")
                }
            default:
                logger.warning("unknown topic: \(message.topic)")
            }
        }

        let notifications = NSWorkspace.shared.notificationCenter
        notifications.addObserver(
            forName: NSWorkspace.screensDidSleepNotification,
            object: nil,
            queue: nil
        ) { _ in
            mqtt.publish(
                config.offPayload,
                to: config.stateTopic,
                qos: .atLeastOnce,
                retain: true
            )
        }
        notifications.addObserver(
            forName: NSWorkspace.screensDidWakeNotification,
            object: nil,
            queue: nil
        ) { _ in
            mqtt.publish(
                config.onPayload,
                to: config.stateTopic,
                qos: .atLeastOnce,
                retain: true
            )
        }

        mqtt.connect()

        let app = NSApplication.shared
        app.run()
    }
}
