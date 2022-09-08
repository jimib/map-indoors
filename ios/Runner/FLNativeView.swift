import Flutter
import UIKit

import GoogleMaps
import MapsIndoors

class FLNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
}

class FLNativeView: NSObject, FlutterPlatformView {
    private var _controller:MPMapControl?
    private var _view: GMSMapView
	private var _messenger: FlutterBinaryMessenger?
  	private var _channel: FlutterMethodChannel?
	private var _viewId: Int64?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
		
        self._view = GMSMapView.map(withFrame: frame, camera: GMSCameraPosition())
        self._controller = MPMapControl.init(map: _view)

		//enable the position provider
		self._controller?.showUserPosition(true)
		//register the position provider
		MapsIndoors.positionProvider = BluedotBeaconPositionProvider()
		MapsIndoors.positionProvider?.startPositioning(nil)

		self._messenger = messenger
   		self._viewId = viewId

		self._channel = FlutterMethodChannel(
			name: "MapView/\(viewId)", 
			binaryMessenger: messenger
		)

		super.init()
		
		self._channel?.setMethodCallHandler({ (call:FlutterMethodCall, result: FlutterResult) -> Void in
			switch call.method {
			case "syncContent":
				self.syncContent( )
				result("receiveFromFlutter success")
			case "clearMap":
				self.clearMap( )
				result("receiveFromFlutter success")
				
			case "gotoLocationByName":
				if let args = call.arguments as? [String: Any],
					let name = args["name"] as? String{
					self.gotoLocationByName( name )
					result("receiveFromFlutter success")
				} else {
					//didn't match
					result(FlutterError(code: "-1", message: "Error", details:"?"))
				}
			
			case "gotoLocationByCoords":
				if let args = call.arguments as? [String: Any],
					let lat = args["lat"] as? Double,
					let lng = args["lng"] as? Double
				{
					self.gotoLocationByCoords( lat: lat, lng: lng )
					result("receiveFromFlutter success")
				} else {
					//didn't match
					result(FlutterError(code: "-1", message: "Error", details:"?"))
				}
			case "setBearing":
				if let args = call.arguments as? [String: Any],
					let bearing = args["bearing"] as? Double
				{
					self.setBearing( bearing )
					result("receiveFromFlutter success")
				} else {
					//didn't match
					result(FlutterError(code: "-1", message: "Error", details:"?"))
				}
			default:
				result(FlutterMethodNotImplemented)
			}
		})

        
    }
    

    func view() -> UIView {
        return _view
    }

	func syncContent(){
		MapsIndoors.synchronizeContent{ (error) in
			NSLog("Completed sync");
		}
	}
	
	func clearMap(){
		_controller?.clearMap()
	}

	func gotoLocationByName( _ name: String ){
        let query = MPQuery.init()
        let filter = MPFilter.init()
        query.query = name
        filter.take = 1
        MPLocationService.sharedInstance().getLocationsUsing(query, filter: filter) { (locations, error) in
            if let location = locations?.first {
                // self._controller?.go(to:location)
				if let lat = location.geometry?.lat(), let lng = location.geometry?.lng() {
					self.gotoLocationByCoords( lat:lat, lng:lng )
				}

            }
        }
    }
	
	func gotoLocationByCoords( lat: Double, lng: Double, zoom:Float = 20 ){
		let camera = GMSCameraPosition.camera(
			withLatitude: lat,
			longitude: lng,
			zoom: zoom,
			bearing: self._view.camera.bearing,
			viewingAngle: self._view.camera.viewingAngle
		)

		NSLog("gotoLocationByCoords \(self._view.camera.bearing)");
		self._view.camera = camera
    }

	func setBearing( _ bearing: Double ){
		let camera = GMSCameraPosition.camera(
			withLatitude: self._view.camera.target.latitude,
			longitude: self._view.camera.target.longitude,
			zoom: self._view.camera.zoom,
			bearing: bearing,
			viewingAngle: self._view.camera.viewingAngle
		)
		self._view.camera = camera
    }

}
