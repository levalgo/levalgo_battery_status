import Flutter
import UIKit
import XCTest

// Imported without @testable on purpose: these tests only touch the plugin's
// public surface, which is the same one the generated registrant sees. If
// anything stopped being `public`, these tests would stop compiling.
import levalgo_battery_status

/// Test double with fixed values.
///
/// It is a class rather than a struct so its state can be changed mid-test
/// and so it can record whether monitoring was requested.
///
/// This is what lets the whole suite run on the simulator: without the
/// protocol it would have to read `UIDevice`, which never reports real
/// battery data there.
final class StubBattery: BatteryProviding {
  var level: Float
  var state: UIDevice.BatteryState
  private(set) var monitoringEnabled = false

  init(level: Float = 0.5, state: UIDevice.BatteryState = .unplugged) {
    self.level = level
    self.state = state
  }

  func enableMonitoring() {
    monitoringEnabled = true
  }
}

final class LevalgoBatteryStatusPluginTests: XCTestCase {
  private var battery: StubBattery!
  private var notificationCenter: NotificationCenter!
  private var plugin: LevalgoBatteryStatusPlugin!

  override func setUp() {
    super.setUp()
    battery = StubBattery()
    // A private center rather than the shared one, so no test can receive
    // notifications posted by another, or by the system.
    notificationCenter = NotificationCenter()
    plugin = LevalgoBatteryStatusPlugin(
      battery: battery,
      notificationCenter: notificationCenter
    )
  }

  override func tearDown() {
    _ = plugin.onCancel(withArguments: nil)
    plugin = nil
    notificationCenter = nil
    battery = nil
    super.tearDown()
  }

  /// Runs a channel method and returns whatever the result block receives.
  private func handle(_ method: String) -> Any? {
    let call = FlutterMethodCall(methodName: method, arguments: nil)
    var captured: Any?
    let done = expectation(description: "the result block must be called")

    plugin.handle(call) { result in
      captured = result
      done.fulfill()
    }

    wait(for: [done], timeout: 1)
    return captured
  }

  // MARK: - getBatteryLevel

  func testGetBatteryLevelReturnsPercentage() {
    battery.level = 0.87

    XCTAssertEqual(handle("getBatteryLevel") as? Int, 87)
  }

  func testGetBatteryLevelRoundsToNearestInteger() {
    battery.level = 0.876

    XCTAssertEqual(handle("getBatteryLevel") as? Int, 88)
  }

  func testGetBatteryLevelReturnsErrorWhenUnavailable() throws {
    // This is what the iOS simulator reports.
    battery.level = -1.0

    let error = try XCTUnwrap(handle("getBatteryLevel") as? FlutterError)

    XCTAssertEqual(error.code, "UNAVAILABLE")
  }

  func testGetBatteryLevelEnablesMonitoring() {
    XCTAssertFalse(battery.monitoringEnabled)

    _ = handle("getBatteryLevel")

    XCTAssertTrue(battery.monitoringEnabled)
  }

  // MARK: - getBatteryState

  func testGetBatteryStateTranslatesEveryState() {
    let cases: [(UIDevice.BatteryState, String)] = [
      (.full, "full"),
      (.charging, "charging"),
      (.unplugged, "discharging"),
      (.unknown, "unknown"),
    ]

    for (state, expected) in cases {
      battery.state = state

      XCTAssertEqual(
        handle("getBatteryState") as? String,
        expected,
        "state \(state.rawValue) should translate to \(expected)"
      )
    }
  }

  // MARK: - Unknown methods

  func testUnknownMethodReturnsNotImplemented() {
    let result = handle("aMethodThatDoesNotExist")

    XCTAssertTrue(result is NSObject)
    XCTAssertEqual(result as? NSObject, FlutterMethodNotImplemented as? NSObject)
  }

  // MARK: - Event stream

  func testOnListenEnablesMonitoring() {
    XCTAssertFalse(battery.monitoringEnabled)

    _ = plugin.onListen(withArguments: nil) { _ in }

    XCTAssertTrue(battery.monitoringEnabled)
  }

  /// Asynchronous test: the observer is registered on the main queue, so the
  /// event does not arrive on the same turn of the run loop.
  func testEmitsStateWhenNotificationArrives() {
    battery.state = .charging

    let received = expectation(description: "an event must arrive")
    var events: [String] = []

    _ = plugin.onListen(withArguments: nil) { event in
      if let event = event as? String {
        events.append(event)
      }
      received.fulfill()
    }

    battery.state = .full
    notificationCenter.post(
      name: UIDevice.batteryStateDidChangeNotification,
      object: nil
    )

    wait(for: [received], timeout: 1)
    // The state is read again: the notification only announces the change,
    // it does not carry it.
    XCTAssertEqual(events, ["full"])
  }

  func testDoesNotEmitAfterCancel() {
    let mustNotArrive = expectation(description: "no event must arrive")
    mustNotArrive.isInverted = true

    _ = plugin.onListen(withArguments: nil) { _ in
      mustNotArrive.fulfill()
    }
    _ = plugin.onCancel(withArguments: nil)

    notificationCenter.post(
      name: UIDevice.batteryStateDidChangeNotification,
      object: nil
    )

    // This is what the Objective-C version had to remember to do by hand,
    // keeping the observer token around in order to unregister it.
    wait(for: [mustNotArrive], timeout: 0.5)
  }

  func testSubscribingTwiceDoesNotDuplicateEvents() {
    let received = expectation(description: "exactly one event must arrive")
    received.expectedFulfillmentCount = 1
    received.assertForOverFulfill = true

    let sink: FlutterEventSink = { _ in received.fulfill() }
    _ = plugin.onListen(withArguments: nil, eventSink: sink)
    _ = plugin.onListen(withArguments: nil, eventSink: sink)

    notificationCenter.post(
      name: UIDevice.batteryStateDidChangeNotification,
      object: nil
    )

    wait(for: [received], timeout: 1)
  }
}
