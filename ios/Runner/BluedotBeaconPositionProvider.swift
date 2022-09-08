import UIKit
import MapsIndoors

class BluedotBeaconPositionProvider : NSObject, MPPositionProvider {
    var delegate: MPPositionProviderDelegate?
    private var running = false
    var latestPositionResult: MPPositionResult?
    var preferAlwaysLocationPermission: Bool = false
    var locationServicesActive: Bool = false
    var providerType: MPPositionProviderType = .GPS_POSITION_PROVIDER
    var heading:Double = 0

    private func updatePosition() {
        if running {
            latestPositionResult = MPPositionResult.init()
            latestPositionResult?.geometry = MPPoint.init(lat: 53.3961947, lon: -2.3721403)
            latestPositionResult?.provider = self
            latestPositionResult?.headingAvailable = true
            heading = (heading + 10).truncatingRemainder(dividingBy: 360)
            latestPositionResult?.setHeadingDegrees(heading)

            if let delegate = self.delegate, let latestPositionResult = self.latestPositionResult {
                delegate.onPositionUpdate(latestPositionResult)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.updatePosition()
            }
        }
    }

    func requestLocationPermissions() {
        locationServicesActive = true
    }

    func updateLocationPermissionStatus() {
        locationServicesActive = true
    }

    func startPositioning(_ arg: String?) {
        running = true
        updatePosition()
    }

    func startPositioning(after millis: Int32, arg: String?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (0.001 * Double(millis))) {
            self.startPositioning(arg)
        }
    }

    func stopPositioning(_ arg: String?) {
        running = false
    }

    func isRunning() -> Bool {
        return running
    }

}