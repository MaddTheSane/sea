//
//  IntRectAdditions.swift
//  Seashore
//
//  Created by C.W. Betts on 7/26/16.
//
//

import Foundation
import GIMPCore

extension IntPoint: Equatable {
	static public func ==(lhs: IntPoint, rhs: IntPoint) -> Bool {
		return lhs.x == rhs.x && lhs.y == rhs.y
	}
}

extension IntPoint {
	/// Given an `NSPoint`, makes an `IntPoint` with similar values 
	/// (fields are rounded down if necessary).
	/// - parameter point: The `NSPoint` to convert.
	public init(nsPoint point: Foundation.NSPoint) {
		self.init(x: Int32(floor(point.x)), y: Int32(floor(point.y)))
	}
	
	/// Given an `NSPoint`, makes an `IntPoint` with similar values
	/// (fields are rounded down if necessary).
	/// - parameter point: The `NSPoint` to convert.
	public init(_ point: Foundation.NSPoint) {
		self.init(x: Int32(floor(point.x)), y: Int32(floor(point.y)))
	}
	
	public var nsPoint: Foundation.NSPoint {
		return CGPoint(x: Int(x), y: Int(y))
	}
}

extension IntSize: Equatable {
	static public func ==(lhs: IntSize, rhs: IntSize) -> Bool {
		return lhs.height == rhs.height && lhs.width == rhs.width
	}
}

extension IntSize {
	/// Given an `NSSize`, makes an `IntSize` with similar values 
	/// (fields are rounded up if necessary).
	/// - parameter size: The `NSSize` to convert.
	public init(nsSize size: Foundation.NSSize) {
		self.init(width: Int32(ceil(size.width)), height: Int32(ceil(size.height)))
	}
	
	/// Given an `NSSize`, makes an `IntSize` with similar values
	/// (fields are rounded up if necessary).
	/// - parameter size: The `NSSize` to convert.
	public init(_ size: Foundation.NSSize) {
		self.init(width: Int32(ceil(size.width)), height: Int32(ceil(size.height)))
	}
	
	public var nsSize: Foundation.NSSize {
		return CGSize(width: Int(width), height: Int(height))
	}
}

extension IntRect: Equatable {
	public init(x: Int32, y: Int32, width: Int32, height: Int32) {
		self.init(origin: IntPoint(x: x, y: y), size: IntSize(width: width, height: height))
	}
	
	public func constrain(into bigRect: IntRect) -> IntRect {
		return IntConstrainRect(self, bigRect)
	}
	
	public func constrain(using littleRect: IntRect) -> IntRect {
		return IntConstrainRect(littleRect, self)
	}
	
	public func offset(x: Int32, y: Int32) -> IntRect {
		var tmpRect = self
		tmpRect.formOffset(x: x, y: y)
		return tmpRect
	}
	
	/// Offsets the current `IntRect` by the specified coordinates.
	/// - parameter x: The amount by which to offset the x coordinates.
	/// - parameter y: The amount by which to offset the y coordinates.
	public mutating func formOffset(x: Int32, y: Int32) {
		IntOffsetRect(&self, x, y)
	}
	
	@available(*, unavailable, renamed: "formOffset(x:y:)")
	public mutating func offsetInPlace(x: Int32, y: Int32) {
		IntOffsetRect(&self, x, y)
	}

	
	/// Tests to see if a given `IntPoint` lies within
	/// this `IntRect`. This function assumes a flipped coordinate system like that
	/// used by QuickDraw or `NSPointInRect()`.
	/// - parameter point: The point to be tested.
	/// - returns: `true` if the point lies within the rectangle, `false` otherwise.
	public func contains(point: IntPoint) -> Bool {
		return IntPointInRect(point, self)
	}
	
	/// Tests to see if we entirely contain another
	///`IntRect`.
	/// - parameter littleRect: The IntRect with which to test the above condition.
	/// - returns: Returns `true if the we entirely contain the `littleRect`, `false`
	///otherwise.
	public func contains(rect littleRect: IntRect) -> Bool {
		return IntContainsRect(self, littleRect)
	}
	
	//extern IntRect IntSumRects(IntRect augendRect, IntRect addendRect);
	public func sum(_ addendRect: IntRect) -> IntRect {
		return IntSumRects(self, addendRect)
	}
	
	static public func ==(lhs: IntRect, rhs: IntRect) -> Bool {
		return lhs.origin == rhs.origin && lhs.size == rhs.size
	}
}

extension IntRect {
	/// Given an `NSRect`, makes an `IntRect` with similar values,  the
	/// `IntRect` will always exceed the `NSRect` in size.
	///
	/// - parameter rect: The `NSRect` to convert.
	/// - returns: an `IntRect` at least the size of `NSRect`.
	public init(nsRect rect: Foundation.NSRect) {
		self.init(origin: IntPoint(nsPoint: rect.origin), size: IntSize(nsSize: rect.size))
	}

	/// Given an `NSRect`, makes an `IntRect` with similar values,  the
	/// `IntRect` will always exceed the `NSRect` in size.
	///
	/// - parameter rect: The `NSRect` to convert.
	/// - returns: an `IntRect` at least the size of `NSRect`.
	public init(_ rect: Foundation.NSRect) {
		self.init(origin: IntPoint(nsPoint: rect.origin), size: IntSize(nsSize: rect.size))
	}

	/// An `NSRect` with similar values to this `IntRect`
	public var nsRect: Foundation.NSRect {
		let newRect = CGRect(origin: origin.nsPoint, size: size.nsSize)
		
		return newRect
	}
}

extension IntRect {
	public var maxX: Int32 {
		return (origin.x + size.width)
	}
	
	public var maxY: Int32 {
		return (origin.y + size.height);
	}
	
	public var midX: Int32 {
		return (origin.x + Int32(round(Double(size.width) * 0.5)))
	}
	
	public var midY: Int32 {
		return (origin.y + Int32(round(Double(size.height) * 0.5)))
	}
	
	public var minX: Int32 {
		return self.origin.x
	}
	
	public var minY: Int32 {
		return self.origin.y
	}
}
