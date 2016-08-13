//
//  IntRectAdditions.swift
//  Seashore
//
//  Created by C.W. Betts on 7/26/16.
//
//

import Foundation
import GIMPCore

public func ==(lhs: IntPoint, rhs: IntPoint) -> Bool {
	return lhs.x == rhs.x && lhs.y == rhs.y
}

public func ==(lhs: IntSize, rhs: IntSize) -> Bool {
	return lhs.height == rhs.height && lhs.width == rhs.width
}

public func ==(lhs: IntRect, rhs: IntRect) -> Bool {
	return lhs.origin == rhs.origin && lhs.size == rhs.size
}

extension IntPoint: Equatable {
}

extension IntPoint {
	public init(NSPoint point: Foundation.NSPoint) {
		x = Int32(floor(point.x))
		y = Int32(floor(point.y))
	}
	
	public var NSPoint: Foundation.NSPoint {
		return CGPoint(x: Int(x), y: Int(y))
	}
}

extension IntSize: Equatable {
	
}

extension IntSize {
	public init(NSSize size: Foundation.NSSize) {
		width = Int32(ceil(size.width))
		height = Int32(ceil(size.height))
	}
	
	public var NSSize: Foundation.NSSize {
		return CGSize(width: Int(width), height: Int(height))
	}
}

extension IntRect: Equatable {
	public init(x: Int32, y: Int32, width: Int32, height: Int32) {
		origin = IntPoint(x: x, y: y)
		size = IntSize(width: width, height: height)
	}
	
	public func constrain(into bigRect: IntRect) -> IntRect {
		return IntConstrainRect(self, bigRect)
	}
	
	public func constrain(using littleRect: IntRect) -> IntRect {
		return IntConstrainRect(littleRect, self)
	}
	
	public func offset(x x: Int32, y: Int32) -> IntRect {
		var tmpRect = self
		tmpRect.offsetInPlace(x: x, y: y)
		return tmpRect
	}
	
	/// Offsets the current `IntRect` by the specified coordinates.
	/// - parameter x: The amount by which to offset the x coordinates.
	/// - parameter y: The amount by which to offset the y coordinates.
	public mutating func offsetInPlace(x x: Int32, y: Int32) {
		IntOffsetRect(&self, x, y)
	}
	
	/// Tests to see if a given `IntPoint` lies within
	/// this `IntRect`. This function assumes a flipped coordinate system like that
	/// used by QuickDraw or `NSPointInRect()`.
	/// - parameter point: The point to be tested.
	/// - returns: `true` if the point lies within the rectangle, `false` otherwise.
	public func contains(point point: IntPoint) -> Bool {
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
	public func sum(addendRect: IntRect) -> IntRect {
		return IntSumRects(self, addendRect)
	}
}

extension IntRect {
	/// Given an `NSRect`, makes an `IntRect` with similar values,  the
	/// `IntRect` will always exceed the `NSRect` in size.
	///
	/// - parameter rect: The `NSRect` to convert.
	/// - returns: an `IntRect` at least the size of `NSRect`.
	public init(NSRect rect: Foundation.NSRect) {
		origin = IntPoint(NSPoint: rect.origin)
		size = IntSize(NSSize: rect.size)
	}
	
	/// An `NSRect` with similar values to this `IntRect`
	public var NSRect: Foundation.NSRect {
		let newRect = CGRect(origin: origin.NSPoint, size: size.NSSize)
		
		return newRect
	}
}
