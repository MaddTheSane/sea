//
//  OptionsUtility+Swift.swift
//  Seashore
//
//  Created by C.W. Betts on 10/2/16.
//
//

import Cocoa
import SeashoreKit


protocol SeaOptions: NSObjectProtocol {
	associatedtype OptionClass: AbstractOptions
	
	static var toolType: SeaToolsDefines {get}
}

extension RectSelectTool: SeaOptions {
	typealias OptionClass = RectSelectOptions

	class var toolType: SeaToolsDefines {
		return .selectRect
	}
}


extension EllipseSelectTool: SeaOptions {
	typealias OptionClass = EllipseSelectOptions
	
	class var toolType: SeaToolsDefines {
		return .selectEllipse
	}
}


extension LassoTool: SeaOptions {
	typealias OptionClass = LassoOptions
	
	@objc class var toolType: SeaToolsDefines {
		return .lasso
	}
}

extension PolygonLassoTool {
	typealias OptionClass = PolygonLassoOptions
	
	override class var toolType: SeaToolsDefines {
		return .polygonLasso
	}
}

extension WandTool: SeaOptions {
	typealias OptionClass = WandOptions
	
	class var toolType: SeaToolsDefines {
		return .wand
	}
}

extension PencilTool: SeaOptions {
	typealias OptionClass = PencilOptions
	
	class var toolType: SeaToolsDefines {
		return .pencil
	}
}

extension BrushTool: SeaOptions {
	typealias OptionClass = BrushOptions
	
	class var toolType: SeaToolsDefines {
		return .brush
	}
}

extension BucketTool: SeaOptions {
	typealias OptionClass = BucketOptions
	
	class var toolType: SeaToolsDefines {
		return .bucket
	}
}

extension TextTool: SeaOptions {
	typealias OptionClass = TextOptions
	
	class var toolType: SeaToolsDefines {
		return .text
	}
}

extension EyedropTool: SeaOptions {
	typealias OptionClass = EyedropOptions
	
	class var toolType: SeaToolsDefines {
		return .eyedrop
	}
}

extension PositionTool: SeaOptions {
	typealias OptionClass = PositionOptions
	
	class var toolType: SeaToolsDefines {
		return .position
	}
}

extension GradientTool: SeaOptions {
	typealias OptionClass = GradientOptions
	
	class var toolType: SeaToolsDefines {
		return .gradient
	}
}

extension SmudgeTool: SeaOptions {
	typealias OptionClass = SmudgeOptions
	
	class var toolType: SeaToolsDefines {
		return .smudge
	}
}

extension CloneTool: SeaOptions {
	typealias OptionClass = CloneOptions
	
	class var toolType: SeaToolsDefines {
		return .clone
	}
}

extension CropTool: SeaOptions {
	typealias OptionClass = CropOptions
	
	class var toolType: SeaToolsDefines {
		return .crop
	}
}

extension EffectTool: SeaOptions {
	typealias OptionClass = EffectOptions
	
	class var toolType: SeaToolsDefines {
		return .effect
	}
}


extension OptionsUtility {
	///	Returns the options object associated with a given tool.
	/// - parameter tool: The tool type whose options object you are
	/// seeking (see SeaTools).
	/// - returns: Returns the options object associated with the given index.
	func options<B: SeaOptions>(for tool: B.Type) -> B.OptionClass {
		return getOptions(B.toolType) as! B.OptionClass
	}
}
