import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var i2pdBridge: I2pdBridge?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize i2pd bridge
        if let controller = window?.rootViewController as? FlutterViewController {
            setupMethodChannel(controller: controller)
        }
        
        // Request background execution capability
        setupBackgroundExecution()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func setupMethodChannel(controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: "com.purplei2p.i2pd/native",
            binaryMessenger: controller.binaryMessenger
        )
        
        i2pdBridge = I2pdBridge()
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self, let bridge = self.i2pdBridge else {
                result(FlutterError(code: "UNAVAILABLE", message: "Bridge not initialized", details: nil))
                return
            }
            
            switch call.method {
            case "initialize":
                let dataPath = self.getDataPath()
                let success = bridge.initialize(dataPath: dataPath)
                result(success)
                
            case "start":
                let success = bridge.start()
                result(success)
                
            case "stop":
                bridge.stop()
                result(nil)
                
            case "getRouterInfo":
                let info = bridge.getRouterInfo()
                result(info)
                
            case "getDataPath":
                result(self.getDataPath())
                
            case "configureHttpProxy":
                if let args = call.arguments as? [String: Any],
                   let enabled = args["enabled"] as? Bool,
                   let port = args["port"] as? Int {
                    bridge.configureHttpProxy(enabled: enabled, port: port)
                }
                result(nil)
                
            case "configureSocksProxy":
                if let args = call.arguments as? [String: Any],
                   let enabled = args["enabled"] as? Bool,
                   let port = args["port"] as? Int {
                    bridge.configureSocksProxy(enabled: enabled, port: port)
                }
                result(nil)
                
            case "gracefulShutdown":
                bridge.gracefulShutdown()
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func getDataPath() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!
        let i2pdPath = (documentsPath as NSString).appendingPathComponent("i2pd")
        
        // Create directory if needed
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: i2pdPath) {
            try? fileManager.createDirectory(
                atPath: i2pdPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Create subdirectories
        let subdirs = ["certificates", "tunnels.d", "addressbook", "netDb"]
        for subdir in subdirs {
            let subdirPath = (i2pdPath as NSString).appendingPathComponent(subdir)
            if !fileManager.fileExists(atPath: subdirPath) {
                try? fileManager.createDirectory(
                    atPath: subdirPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        }
        
        // Copy bundled certificates if needed
        copyBundledCertificates(to: i2pdPath)
        
        return i2pdPath
    }
    
    private func copyBundledCertificates(to dataPath: String) {
        let fileManager = FileManager.default
        let certsPath = (dataPath as NSString).appendingPathComponent("certificates")
        
        guard let bundleCertsPath = Bundle.main.path(forResource: "certificates", ofType: nil) else {
            return
        }
        
        do {
            let items = try fileManager.contentsOfDirectory(atPath: bundleCertsPath)
            for item in items {
                let srcPath = (bundleCertsPath as NSString).appendingPathComponent(item)
                let dstPath = (certsPath as NSString).appendingPathComponent(item)
                
                if !fileManager.fileExists(atPath: dstPath) {
                    try fileManager.copyItem(atPath: srcPath, toPath: dstPath)
                }
            }
        } catch {
            print("Failed to copy certificates: \(error)")
        }
    }
    
    private func setupBackgroundExecution() {
        // Register for background tasks
        UIApplication.shared.setMinimumBackgroundFetchInterval(
            UIApplication.backgroundFetchIntervalMinimum
        )
    }
    
    override func applicationWillTerminate(_ application: UIApplication) {
        // Gracefully shutdown i2pd
        i2pdBridge?.gracefulShutdown()
        super.applicationWillTerminate(application)
    }
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        // Keep running in background if possible
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = application.beginBackgroundTask {
            application.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
