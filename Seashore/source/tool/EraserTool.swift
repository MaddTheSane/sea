//
//  EraserTool.swift
//  Seashore
//
//  Created by C.W. Betts on 9/3/17.
//

import Cocoa
import SeashoreKit

private let EPSILON = 0.0001
///Specifies the maximum number of points.
private let kMaxETPoints = 16384

private func sqr<A: FloatingPoint>(_ val: A) -> A {
	return val * val
}

/// A macro that when given two unsigned characters (bytes)
/// determines the product of the two. The returned value is scaled
/// so it is between 0 and 255.
private func int_mult(_ a: UInt8, _ b: UInt8) -> UInt8 {
	let t = Int(a) * Int(b) + 0x80
	return UInt8((((t) >> 8) + (t)) >> 8)
}

class EraserTool: AbstractTool, SeaOptions {
	typealias OptionClass = EraserOptions
	
	/// Specifies a point to be drawn.
	struct PointRecord {
		/// The point to be drawn.
		var point: IntPoint
		/// The presure of the point to be drawn
		var pressure: UInt8
		/// 0 = normal, 2 = terminate
		var special: UInt8
	}
	
	class var toolType: SeaToolsDefines {
		return .eraser
	}
	
	/// The last point we've been (there is a difference from the last point a brush was plotted)
	var lastPoint: NSPoint = .zero
	
	/// The last point a brush was plotted (there is a difference from the last point we've been)
	var lastPlotPoint: NSPoint = .zero
	
	/// The set of pixels upon which to base the brush plot
	var basePixel: [UInt8] = [0,0,0,0]

	/// The distance travelled by the brush so far
	var distance: Double = 0
	
	/// The current position in the list we have drawing
	var drawingPos = 0
	
	/// The current position in the list
	var pos = 0

	/// The list of points
	var points = [PointRecord]()
	
	/// Have we finished drawing?
	var drawingDone = false
	
	/// Is drawing multithreaded?
	var multithreaded = false
	
	/// Has the first touch been done?
	var firstTouchDone = false
	
	/// The last where recorded
	var lastWhere: IntPoint = IntPoint(x: 0, y: 0)

	override var toolId: SeaToolsDefines {
		return .eraser
	}
	
	override var acceptsLineDraws: Bool {
		return true
	}
	
	override var useMouseCoalescing: Bool {
		return false
	}
	
	private func plot(brush: SeaBrush, at point: NSPoint, pressure: Int32) {
		guard let document = document, let layer = document.contents.activeLayer, let boptions = SeaController.utilitiesManager.optionsUtility(for: document)?.options(for: BrushTool.self) else {
			return
		}
		let overlay = document.whiteboard.overlay
		var brushData: UnsafeMutablePointer<UInt8>? = nil
		let brushWidth = brush.fakeWidth
		let brushHeight = brush.fakeHeight
		let ipoint = IntPoint(nsPoint: point)
		let width = layer.width
		let height = layer.height
		var overlayPos: Int32 = 0
		let spp = document.contents.samplesPerPixel
		
		if brush.usePixmap {
			// We can't handle this for anything but 4 samples per pixel
			guard spp == 4 else {
				return;
			}
			
			// Get the approrpiate brush data for the point
			brushData = brush.pixmap(for: point)
			
			// Go through all valid points
			for j in 0 ..< brushHeight {
				for i in 0 ..< brushWidth {
					if (ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height) {
						
						// Change the pixel colour appropriately
						overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * 4;
						SeaSpecialMerge(4, overlay, overlayPos, brushData, (j * brushWidth + i) * 4, pressure);
						
					}
				}
			}
		} else {
			// Get the approrpiate brush data for the point
			if boptions.scale {
				brushData = brush.mask(for: point, pressure: pressure)
			} else {
				brushData = brush.mask(for: point, pressure: 255)
			}
			
			// Go through all valid points
			for j in 0 ..< brushHeight {
				for i in 0 ..< brushWidth {
					if ipoint.x + i >= 0 && ipoint.y + j >= 0 && ipoint.x + i < width && ipoint.y + j < height {
						
						// Change the pixel colour appropriately
						overlayPos = (width * (ipoint.y + j) + ipoint.x + i) * spp;
						basePixel[Int(spp - 1)] = brushData![Int(j * brushWidth + i)];
						SeaSpecialMerge(spp, overlay, overlayPos, &basePixel, 0, pressure);
					}
				}
			}
		}
		// Set the last plot point appropriately
		lastPlotPoint = point
	}
	
	override func mouseDown(at where1: IntPoint, with event: NSEvent?) {
		guard let document = document,
			let curBrush = SeaController.utilitiesManager.brushUtility(for: document)?.activeBrush,
			let boptions = SeaController.utilitiesManager.optionsUtility(for: document)?.options(for: BrushTool.self),
			let layer = document.contents.activeLayer else {
				return
		}
		let curPoint = where1.nsPoint
		let hasAlpha = layer.hasAlpha
		var rect = IntRect()
		let spp = document.contents.samplesPerPixel
		
		// Determine whether operation should continue
		lastWhere = where1
		multithreaded = SeaController.seaPrefs!.multithreaded
		let ignoreFirstTouch = SeaController.seaPrefs!.ignoreFirstTouch
		if (ignoreFirstTouch && (event?.type == .leftMouseDown || event?.type == .rightMouseDown) && boptions.pressureSensitive && !((options as! EraserOptions).modifier() == .shift)) {
			firstTouchDone = false;
			return;
		} else {
			firstTouchDone = true;
		}

		let pressure: Int32
		if (options as! EraserOptions).mimicBrush {
			pressure =  boptions.pressureValue(event)
		} else {
			pressure = 255;
		}

		// Determine background colour and hence the brush colour
		let color = document.contents.background
		if spp == 4 {
			basePixel[0] = UInt8(color.redComponent * 255)
			basePixel[1] = UInt8(color.greenComponent * 255)
			basePixel[2] = UInt8(color.blueComponent * 255)
			basePixel[3] = 255;
		} else {
			basePixel[0] = UInt8(color.whiteComponent * 255)
			basePixel[1] = 255;
		}
	
		// Set the appropriate overlay opacity
		if hasAlpha {
			document.whiteboard.overlayBehaviour = .erasing
		}
		document.whiteboard.overlayOpacity = (options as! EraserOptions).opacity
		
		// Plot the initial point
		rect.size.width = curBrush.fakeWidth + 1;
		rect.size.height = curBrush.fakeHeight + 1;
		let temp = NSPoint(x: curPoint.x - CGFloat(curBrush.width / 2) - 1.0, y: curPoint.y - CGFloat(curBrush.height / 2) - 1.0)
		rect.origin = IntPoint(nsPoint: temp)
		rect.origin.x -= 1; rect.origin.y -= 1;
		rect = rect.constrain(into: IntRect(x: 0, y: 0, width: layer.width, height: layer.height))
		if rect.size.width > 0 && rect.size.height > 0 {
			plot(brush: curBrush, at: temp, pressure: pressure)
			document.helpers?.overlayChanged(rect, inThread: true)
		}
		
		// Record the position as the last point
		lastPoint = curPoint
		lastPlotPoint = curPoint;
		distance = 0;
		
		// Create the points list
		points = [PointRecord](repeating: PointRecord(point: IntPoint(), pressure: 0, special: 0), count: kMaxETPoints)
		pos = 0
		drawingPos = 0

		// Detach the thread
		if multithreaded {
			drawingDone = false
			Thread.detachNewThreadSelector(#selector(EraserTool.drawThread(_:)), toTarget: self, with: nil)
		}
	}
	
	@objc func drawThread(_ object: AnyObject?) {
		autoreleasepool { () -> Void in
			// Set-up variables
			guard let document = document,
				let boptions: BrushOptions = SeaController.utilitiesManager.optionsUtility(for: document)?.options(for: BrushTool.self),
				let layer = document.contents.activeLayer,
				let bUtil = SeaController.utilitiesManager.brushUtility(for: document),
				let curBrush = bUtil.activeBrush else {
				return
			}
			
			let layerWidth = layer.width
			let layerHeight = layer.height
			let brushWidth = curBrush.fakeWidth
			let brushHeight = curBrush.fakeHeight
			let brushSpacing = Double(bUtil.spacing) / 100.0;
			let fade = (options as! EraserOptions).mimicBrush && boptions.fade
			let fadeValue = boptions.fadeValue;
			var bigRect = IntMakeRect(0, 0, 0, 0);
			var lastDate = Date()
			var t0: Double = 0
			var dt: Double = 0
			var tn: Double = 0
			var dtx: Double = 0
			var n: Int32
			var num_points: Int32
			var pressure: Int32 = 0

			// While we are not done...
			repeat {
				if drawingPos < pos {
					// Get the next record and carry on
					let curPoint = IntPointMakeNSPoint(points[drawingPos].point);
					let origPressure = points[drawingPos].pressure;
					if (points[drawingPos].special == 2) {
						if (bigRect.size.width != 0) {
							document.helpers?.overlayChanged(bigRect, inThread: true)
						}
						drawingDone = true
						return;
					}
					drawingPos += 1
					
					// Determine the change in the x and y directions
					let deltaX = curPoint.x - lastPoint.x;
					let deltaY = curPoint.y - lastPoint.y;
					if deltaX == 0.0 && deltaY == 0.0 {
						if (multithreaded) {
							continue
						} else {
							return;
						}
					}
					
					// Determine the number of brush strokes in the x and y directions
					var mag = Double(brushWidth / 2);
					let xd = (mag * Double(deltaX)) / sqr(mag);
					mag = Double(brushHeight / 2);
					let yd = (mag * Double(deltaY)) / sqr(mag);
					
					// Determine the brush stroke distance and hence determine the initial and total distance
					let dist = 0.5 * sqrt(sqr(xd) + sqr(yd));		// Why is this halved?
					var total = dist + distance;
					let initial = distance;
					
					var stFactor: Double = 0
					var stOffset: Double = 0
					// Determine the stripe factor and offset
					if sqr(deltaX) > sqr(deltaY) {
						stFactor = Double(deltaX)
						stOffset = Double(lastPoint.x - 0.5)
					} else {
						stFactor = Double(deltaY)
						stOffset = Double(lastPoint.y - 0.5)
					}
					
					if fabs(stFactor) > dist / brushSpacing {
						// We want to draw the maximum number of points
						dt = brushSpacing / dist;
						n = Int32(initial / brushSpacing + 1.0 + EPSILON);
						t0 = (Double(n) * brushSpacing - initial) / dist;
						num_points = 1 + Int32(floor((1 + EPSILON - t0) / dt))
					} else if fabs(stFactor) < EPSILON {
						// We can't draw any points - this does actually get called albeit once in a blue moon
						lastPoint = curPoint;
						if multithreaded {
							continue
						} else {
							return;
						}
					} else {
						// We want to draw a number of points
						let direction: Int32 = stFactor > 0 ? 1 : -1;
						
						var s0 = Int32(floor(stOffset + 0.5))
						var sn = Int32(floor(stOffset + stFactor + 0.5))
						
						t0 = (Double(s0) - stOffset) / stFactor;
						tn = (Double(sn) - stOffset) / stFactor;
						
						var x = Int32(floor(lastPoint.x.native + t0 * deltaX.native))
						var y = Int32(floor(lastPoint.y.native + t0 * deltaY.native))
						if t0 < 0.0 && !(x == Int32(floor(lastPoint.x)) && y == Int32(floor(lastPoint.y))) {
							s0 += direction;
						}
						if x == Int32(floor(lastPlotPoint.x)) && y == Int32(floor(lastPlotPoint.y)) {
							s0 += direction;
						}
						x = Int32(floor(lastPoint.x.native + tn * deltaX.native))
						y = Int32(floor(lastPoint.y.native + tn * deltaY.native))
						if tn > 1.0 && !(x == Int32(floor(lastPoint.x)) && y == Int32(floor(lastPoint.y))) {
							sn -= direction;
						}
						t0 = (Double(s0) - stOffset) / stFactor;
						tn = (Double(sn) - stOffset) / stFactor;
						dt = Double(direction) * 1.0 / stFactor;
						num_points = 1 + direction * (sn - s0);
						
						if (num_points >= 1) {
							if (tn < 1) {
							total = initial + tn * dist;
							}
							total = brushSpacing * floor(total / brushSpacing + 0.5);
							total += (1.0 - tn) * dist;
						}
					}
					
					// Draw all the points
					for n in 0 ..< num_points {
						let t = t0 + Double(n) * dt
						var rect = IntRect()
						rect.size.width = brushWidth + 1;
						rect.size.height = brushHeight + 1;
						let temp = NSPoint(x: lastPoint.x.native + deltaX.native * t - Double(brushWidth / 2), y: lastPoint.y.native + deltaY.native * t - Double(brushHeight / 2));
						rect.origin = NSPointMakeIntPoint(temp);
						rect.origin.x -= 1; rect.origin.y -= 1;
						rect = IntConstrainRect(rect, IntMakeRect(0, 0, layerWidth, layerHeight));
						if fade {
							dtx = (initial + t * dist) / Double(fadeValue)
							pressure = Int32(exp ( -dtx * dtx * 5.541) * 255.0);
							pressure = Int32(int_mult(UInt8(pressure), origPressure));
						} else {
							pressure = Int32(origPressure);
						}
						if rect.size.width > 0 && rect.size.height > 0 && pressure > 0 {
							plot(brush: curBrush, at: temp, pressure: pressure)
							if (bigRect.size.width == 0) {
								bigRect = rect;
							} else {
								var trect = IntRect()
								trect.origin.x = min(rect.origin.x, bigRect.origin.x);
								trect.origin.y = min(rect.origin.y, bigRect.origin.y);
								trect.size.width = max(rect.origin.x + rect.size.width - trect.origin.x, bigRect.origin.x + bigRect.size.width - trect.origin.x);
								trect.size.height = max(rect.origin.y + rect.size.height - trect.origin.y, bigRect.origin.y + bigRect.size.height - trect.origin.y);
								bigRect = trect;
							}
						}
					}
					
					// Update the distance and plot points
					distance = total;
					lastPoint.x = lastPoint.x + deltaX;
					lastPoint.y = lastPoint.y + deltaY;
				} else {
					if multithreaded {
						Thread.sleep(until: Date(timeIntervalSinceNow: 0.01))
					}
				}
				
				// Update periodically
				if multithreaded {
					if bigRect.size.width != 0 && Date().timeIntervalSince(lastDate) > 0.02 {
						document.helpers?.overlayChanged(bigRect, inThread: true)
						lastDate = Date()
						bigRect = IntMakeRect(0, 0, 0, 0);
					}
				} else {
					document.helpers?.overlayChanged(bigRect, inThread: true)
				}
			} while multithreaded
		}
	}
	
	override func mouseDragged(to where1: IntPoint, with event: NSEvent?) {
		let boptions: BrushOptions? = SeaController.utilitiesManager.optionsUtility(for: document!)?.options(for: BrushTool.self)
		
		// Have we registerd the first touch
		if !firstTouchDone {
			mouseDown(at: where1, with: event)
			firstTouchDone = true
		}
		
		// Check this is a new point
		if where1 == lastWhere {
			return;
		} else {
			lastWhere = where1
		}
		// Add to the list
		if pos < kMaxETPoints - 1 {
			points[pos].point = where1
			if (options as! EraserOptions).mimicBrush {
				points[pos].pressure = UInt8(boptions?.pressureValue(event) ?? 255)
			} else {
				points[pos].pressure = 255;
			}
			pos += 1
		} else if pos == kMaxETPoints - 1 {
			points[pos].special = 2;
			pos += 1
		}
		
		// Draw if drawing is not multithreaded
		if !multithreaded {
			drawThread(nil)
		}
	}
	
	func endLineDrawing() {
		// Tell the other thread to terminate
		if pos < kMaxETPoints {
			points[pos].special = 2;
			pos += 1
		}
		
		// If multithreaded, wait until the other thread finishes
		if multithreaded {
			while !drawingDone {
				Thread.sleep(until: Date(timeIntervalSinceNow: 0.1))
			}
		} else {
			drawThread(nil)
		}
	}
	
	override func mouseUp(at where: IntPoint, with event: NSEvent?) {
		// Apply the changes
		endLineDrawing()
		document?.helpers?.applyOverlay()
	}
	
	func startStroke(_ awhere: IntPoint) {
		mouseDown(at: awhere, with: nil)
	}
	
	func intermediateStroke(_ awhere: IntPoint) {
		mouseDragged(to: awhere, with: nil)
	}

	func endStroke(_ awhere: IntPoint) {
		mouseUp(at: awhere, with: nil)
	}
}
