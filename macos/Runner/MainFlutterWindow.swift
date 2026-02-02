import Cocoa
import FlutterMacOS
import AVFoundation
import Speech

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Make window always stay on top
    self.level = .floating
    self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    
    // Add glass/frosted background effect
    self.isOpaque = false
    self.backgroundColor = .clear
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    
    // Add visual effect view (frosted glass)
    // let visualEffectView = NSVisualEffectView(frame: self.contentView!.bounds)
    // visualEffectView.autoresizingMask = [.width, .height]
    // visualEffectView.material = .hudWindow
    // visualEffectView.state = .active
    // visualEffectView.blendingMode = .behindWindow
    
    // self.contentView?.addSubview(visualEffectView, positioned: .below, relativeTo: nil)

    // Screen capture channel
    let channel = FlutterMethodChannel(
      name: "interx/screen_capture",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        return result(FlutterError(code: "NO_WINDOW", message: nil, details: nil))
      }

      switch call.method {
      case "setHidden":
        guard let isHidden = call.arguments as? Bool else {
          return result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
        }
        DispatchQueue.main.async {
          self.sharingType = isHidden ? .none : .readOnly
          result(nil)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Permission channel
    let permissionChannel = FlutterMethodChannel(
      name: "com.musicplayer/permissions",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    permissionChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "checkMicrophonePermission":
        Self.checkMicrophonePermission(result: result)
      case "requestMicrophonePermission":
        Self.requestMicrophonePermission(result: result)
      case "checkSpeechRecognitionPermission":
        Self.checkSpeechRecognitionPermission(result: result)
      case "requestSpeechRecognitionPermission":
        Self.requestSpeechRecognitionPermission(result: result)
      case "requestAllPermissions":
        Self.requestAllPermissions(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
  
  // MARK: - Permission Methods
  
  private static func checkMicrophonePermission(result: @escaping FlutterResult) {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    switch status {
    case .authorized:
      result("authorized")
    case .denied, .restricted:
      result("denied")
    case .notDetermined:
      result("notDetermined")
    @unknown default:
      result("notDetermined")
    }
  }
  
  private static func requestMicrophonePermission(result: @escaping FlutterResult) {
    AVCaptureDevice.requestAccess(for: .audio) { granted in
      DispatchQueue.main.async {
        result(granted ? "authorized" : "denied")
      }
    }
  }
  
  private static func checkSpeechRecognitionPermission(result: @escaping FlutterResult) {
    let status = SFSpeechRecognizer.authorizationStatus()
    switch status {
    case .authorized:
      result("authorized")
    case .denied, .restricted:
      result("denied")
    case .notDetermined:
      result("notDetermined")
    @unknown default:
      result("notDetermined")
    }
  }
  
  private static func requestSpeechRecognitionPermission(result: @escaping FlutterResult) {
    // First check current status
    let currentStatus = SFSpeechRecognizer.authorizationStatus()
    
    // If already determined, return the status
    if currentStatus != .notDetermined {
      switch currentStatus {
      case .authorized:
        result("authorized")
      case .denied, .restricted:
        result("denied")
      default:
        result("notDetermined")
      }
      return
    }
    
    // Only request if not determined
    SFSpeechRecognizer.requestAuthorization { status in
      DispatchQueue.main.async {
        switch status {
        case .authorized:
          result("authorized")
        case .denied, .restricted:
          result("denied")
        case .notDetermined:
          result("notDetermined")
        @unknown default:
          result("notDetermined")
        }
      }
    }
  }
  
  private static func requestAllPermissions(result: @escaping FlutterResult) {
    // First request microphone
    AVCaptureDevice.requestAccess(for: .audio) { micGranted in
      // Then request speech recognition
      SFSpeechRecognizer.requestAuthorization { speechStatus in
        DispatchQueue.main.async {
          let bothGranted = micGranted && (speechStatus == .authorized)
          result([
            "microphone": micGranted ? "authorized" : "denied",
            "speechRecognition": speechStatus == .authorized ? "authorized" : "denied",
            "allGranted": bothGranted
          ])
        }
      }
    }
  }
}
