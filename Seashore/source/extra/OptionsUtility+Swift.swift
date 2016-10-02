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
		return .kRectSelectTool
	}
}


extension EllipseSelectTool: SeaOptions {
	typealias OptionClass = EllipseSelectOptions
	
	class var toolType: SeaToolsDefines {
		return .kEllipseSelectTool
	}
}


extension LassoTool: SeaOptions {
	typealias OptionClass = LassoOptions
	
	class var toolType: SeaToolsDefines {
		return .kLassoTool
	}
}

extension PolygonLassoTool {
	typealias OptionClass = PolygonLassoOptions
	
	override class var toolType: SeaToolsDefines {
		return .kPolygonLassoTool
	}
}

extension WandTool: SeaOptions {
	typealias OptionClass = WandOptions
	
	class var toolType: SeaToolsDefines {
		return .kWandTool
	}
}

extension PencilTool: SeaOptions {
	typealias OptionClass = PencilOptions
	
	class var toolType: SeaToolsDefines {
		return .kPencilTool
	}
}

extension BrushTool: SeaOptions {
	typealias OptionClass = BrushOptions
	
	class var toolType: SeaToolsDefines {
		return .kBrushTool
	}
}

extension BucketTool: SeaOptions {
	typealias OptionClass = BucketOptions
	
	class var toolType: SeaToolsDefines {
		return .kBucketTool
	}
}

extension TextTool: SeaOptions {
	typealias OptionClass = TextOptions
	
	class var toolType: SeaToolsDefines {
		return .kTextTool
	}
}

extension EyedropTool: SeaOptions {
	typealias OptionClass = EyedropOptions
	
	class var toolType: SeaToolsDefines {
		return .kEyedropTool
	}
}

extension EraserTool: SeaOptions {
	typealias OptionClass = EraserOptions
	
	class var toolType: SeaToolsDefines {
		return .kEraserTool
	}
}

extension PositionTool: SeaOptions {
	typealias OptionClass = PositionOptions
	
	class var toolType: SeaToolsDefines {
		return .kPositionTool
	}
}

extension GradientTool: SeaOptions {
	typealias OptionClass = GradientOptions
	
	class var toolType: SeaToolsDefines {
		return .kGradientTool
	}
}

extension SmudgeTool: SeaOptions {
	typealias OptionClass = SmudgeOptions
	
	class var toolType: SeaToolsDefines {
		return .kSmudgeTool
	}
}

extension CloneTool: SeaOptions {
	typealias OptionClass = CloneOptions
	
	class var toolType: SeaToolsDefines {
		return .kCloneTool
	}
}

extension CropTool: SeaOptions {
	typealias OptionClass = CropOptions
	
	class var toolType: SeaToolsDefines {
		return .kCropTool
	}
}

extension EffectTool: SeaOptions {
	typealias OptionClass = EffectOptions
	
	class var toolType: SeaToolsDefines {
		return .kEffectTool
	}
}


extension OptionsUtility {
	func options<B: SeaOptions>(for tool: B.Type) -> B.OptionClass {
		return getOptions(B.toolType) as! B.OptionClass
	}
}
