//
//  ToolboxUtility.swift
//  Seashore
//
//  Created by C.W. Betts on 8/3/16.
//
//

import Cocoa
import SeashoreKit.SeaDocument
import SeashoreKit

private let DocToolbarIdentifier = "Document Toolbar Instance Identifier";

private let SelectionIdentifier	= "Selection  Item Identifier";
private let DrawIdentifier		= "Draw Item Identifier";
private let EffectIdentifier	= "Effect Item Identifier";
private let TransformIdentifier	= "Transform Item Identifier";
private let ColorsIdentifier	= "Colors Item Identifier";

// Additional (Non-default) toolbar items
private let ZoomInToolbarItemIdentifier = "Zoom In Toolbar Item Identifier";
private let ZoomOutToolbarItemIdentifier = "Zoom Out Toolbar Item Identifier";
private let ActualSizeToolbarItemIdentifier = "Actual Size Toolbar Item Identifier";
private let NewLayerToolbarItemIdentifier = "New Layer Toolbar Item Identifier";
private let DuplicateLayerToolbarItemIdentifier = "Duplicate Layer Toolbar Item Identifier";
private let ForwardToolbarItemIdentifier = "Move Layer Forward  Toolbar Item Identifier";
private let BackwardToolbarItemIdentifier = "Move Layer Backward Toolbar Item Identifier";
private let DeleteLayerToolbarItemIdentifier = "Delete Layer Toolbar Item Identifier";
private let ToggleLayersToolbarItemIdentifier = "Show/Hide Layers Item Identifier";
private let InspectorToolbarItemIdentifier = "Show/Hide Inspector Toolbar Item Identifier";
private let FloatAnchorToolbarItemIdentifier = "Float/Anchor Toolbar Item Identifier";
private let DuplicateSelectionToolbarItemIdentifier = "Duplicate Selection Toolbar Item Identifier";
private let SelectNoneToolbarItemIdentifier = "Select None Toolbar Item Identifier";
private let SelectAllToolbarItemIdentifier = "Select All Toolbar Item Identifier";
private let SelectInverseToolbarItemIdentifier = "Select Inverse Toolbar Item Identifier";
private let SelectAlphaToolbarItemIdentifier = "Select Alpha Toolbar Item Identifier";


class ToolboxUtility : NSObject {
	/// The document which is the focus of this utility
	@IBOutlet weak var document: SeaDocument!
	
	/// The proxy object
	@IBOutlet weak var seaProxy: SeaProxy!

	/// The current foreground colour
	@NSCopying var foreground: NSColor = NSColor(deviceWhite: 1, alpha: 1) {
		didSet {
			if let delayTimer = delayTimer {
				delayTimer.invalidate()
			}
			delayTimer = NSTimer(timeInterval: 0.1, target: (document.tools as Seashore.SeaTools).getTool(.kTextTool)!, selector: #selector(TextTool.preview(_:)), userInfo: nil, repeats: false)
			SeaController.utilitiesManager().statusUtility(for: document)!.updateQuickColor()
		}
	}
	
	/// The current background colour
	@NSCopying var background = NSColor(deviceWhite: 0, alpha: 1)
	
	/// The colorSelectView associated with this utility
	@IBOutlet weak var colorView: ColorSelectView!

	/// The toolbox
	@IBOutlet weak var toolbox: NSMatrix!
	
	/// The options utility object
	@IBOutlet weak var optionsUtility: OptionsUtility!
	
	/// The tag of the currently selected tool
	private(set) var tool = SeaToolsDefines.SeaToolsInvalid
	
	/// The old tool
	private var oldTool = SeaToolsDefines.SeaToolsInvalid
	
	/// The toolbar
	var toolbar: NSToolbar!
	
	@IBOutlet weak var selectionTBView: NSSegmentedControl!
	@IBOutlet weak var drawTBView: NSSegmentedControl!
	@IBOutlet weak var effectTBView: NSSegmentedControl!
	@IBOutlet weak var transformTBView: NSSegmentedControl!
	
	@IBOutlet weak var selectionMenu: NSMenuItem!
	@IBOutlet weak var drawMenu: NSMenuItem!
	@IBOutlet weak var effectMenu: NSMenuItem!
	@IBOutlet weak var transformMenu: NSMenuItem!
	@IBOutlet weak var colorsMenu: NSMenuItem!

	private let selectionTools: [SeaToolsDefines] = [
		.kRectSelectTool,
		.kEllipseSelectTool,
		.kLassoTool,
		.kPolygonLassoTool,
		.kWandTool]
	private let drawTools: [SeaToolsDefines] = [
		.kPencilTool,
		.kBrushTool,
		.kTextTool,
		.kEraserTool,
		.kBucketTool,
		.kGradientTool];
	private let effectTools: [SeaToolsDefines] = [
		.kEffectTool,
		.kSmudgeTool,
		.kCloneTool];
	private let transformTools: [SeaToolsDefines] = [
		.kEyedropTool,
		.kCropTool,
		.kZoomTool,
		.kPositionTool];
	
	/// A timer that delays colour changes
	private var delayTimer: NSTimer?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Create the toolbar instance, and attach it to our document window
		toolbar = NSToolbar(identifier: DocToolbarIdentifier);

		// Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
		toolbar.allowsUserCustomization = true
		toolbar.autosavesConfiguration = true
		toolbar.displayMode = .IconOnly
		
		// We are the delegate
		toolbar.delegate = self
		
		// Attach the toolbar to the document window
		document.window().toolbar = toolbar
	}
	
	/// Returns whether or not the window accepts the first mouse click 
	/// upon it.
	/// - parameter event: Ignored.
	/// - returns: `true` indicating that the window does accept
	/// the first mouse click upon it.
	func acceptsFirstMouse(event: NSEvent) -> Bool {
		return true
	}
	
	/// Activates this utility with its document.
	func activate() {
		if tool == .SeaToolsInvalid {
			changeTool(to: .kRectSelectTool)
		}
		
		// Set the document appropriately
		colorView.document = document
		
		// Then pretend a tool change
		update(true)
	}
	
	/// Deactivates this utility.
	func deactivate() {
		colorView.document = document
		for i in SeaToolsDefines.kFirstSelectionTool.rawValue ... SeaToolsDefines.kLastSelectionTool.rawValue {
			toolbox.cellWithTag(Int(i))?.enabled = true
		}
	}
	
	/// Updates the utility for the current document.
	/// - parameter full: `true` if the update is to also include setting 
	/// the cursor, `false` otherwise.
	func update(full: Bool) {
		if full {
			/* Disable or enable the tool */
			if document.selection.floating {
				for i in SeaToolsDefines.kFirstSelectionTool.rawValue ... SeaToolsDefines.kLastSelectionTool.rawValue {
					selectionTBView.setEnabled(false, forSegment: Int(i))
				}
				selectionMenu.enabled = false
			} else {
				for i in SeaToolsDefines.kFirstSelectionTool.rawValue ... SeaToolsDefines.kLastSelectionTool.rawValue {
					selectionTBView.setEnabled(true, forSegment: Int(i))
				}
				selectionMenu.enabled = false
			}
			// Implement the change
			document.docView.needsDisplay = true
			optionsUtility.update()
			SeaController.seaHelp().updateInstantHelp(tool.rawValue)
		}
		colorView.update()
	}
	
	/// Called by menu item to change the tool.
	/// - parameter sender: An object with a tag that modulo-100 
	/// specifies the tool to be selected.
	@IBAction func selectToolUsingTag(sender: AnyObject) {
		let theTag = sender.tag()
		let preTool = Int32(theTag % 100)
		if let newTool = SeaToolsDefines(rawValue: preTool) {
			changeTool(to: newTool)
		}
	}
	
	/// Called when the segmented controls get clicked.
	/// - parameter sender: The segemented control to select the tool.
	@IBAction func selectToolFromSender(sender: NSSegmentedControl) {
		if let newTool = SeaToolsDefines(rawValue: Int32((sender.cell as! NSSegmentedCell).tagForSegment(sender.selectedSegment) % 100)) {
			changeTool(to: newTool)
		}
	}
	
	/// Preforms checks to make sure changing the tool is valid, and if any updates are needed.
	/// - parameter newTool: The index of the new tool.
	@objc(changeToolTo:) func changeTool(to newTool: SeaToolsDefines) {
		var updateCrop = false;
		
		document.helpers.endLineDrawing()
		if (tool == .kCropTool || newTool == .kCropTool) {
			updateCrop = true;
			document.docView.needsDisplay = true
		}
		if (tool == newTool && NSApp.currentEvent?.type == .LeftMouseUp && NSApp.currentEvent?.clickCount > 1) {
			SeaController.utilitiesManager().optionsUtility(for: document)!.show(nil)
		} else {
			tool = newTool;
			// Deselect the old tool
			for i in 0..<selectionTools.count {
				selectionTBView.setSelected(false, forSegment: i)
			}
			for i in 0..<drawTools.count {
				drawTBView.setSelected(false, forSegment: i)
			}
			for i in 0..<effectTools.count {
				effectTBView.setSelected(false, forSegment: i)
			}
			for i in 0..<transformTools.count {
				transformTBView.setSelected(false, forSegment: i)
			}
			
			selectionTBView.selectSegmentWithTag(Int(tool.rawValue))
			drawTBView.selectSegmentWithTag(Int(tool.rawValue))
			effectTBView.selectSegmentWithTag(Int(tool.rawValue))
			transformTBView.selectSegmentWithTag(Int(tool.rawValue))
			
			update(true)
		}
		if (updateCrop) {
			SeaController.utilitiesManager().infoUtility(for: document)!.update()
		}
	}
	
	/// Selects the position tool.
	func floatTool() {
		// Show the banner
		document.warnings.showFloatBanner()
		
		oldTool = tool;
		changeTool(to: .kPositionTool)
	}
	
	/// Selects the last tool to call floatTool.
	func anchorTool() {
		// Hide the banner
		document.warnings.hideFloatBanner()
		if oldTool != .SeaToolsInvalid {
			changeTool(to: oldTool)
		}
	}
	
	func setEffectEnabled(enable: Bool) {
		effectTBView.setEnabled(enable, forSegment: Int(SeaToolsDefines.kEffectTool.rawValue))
	}
	
	override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
		if menuItem.tag >= 600 && menuItem.tag < 700 {
			menuItem.state = (menuItem.tag == Int(tool.rawValue) + 600) ? NSOnState : NSOffState
		}
		
		return true
	}
}

extension ToolboxUtility: NSToolbarDelegate {
	func toolbar(toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: String, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
		var toolbarItem: SeaToolbarItem?
		
		switch itemIdentifier {
		case SelectionIdentifier:
			toolbarItem = SeaToolbarItem(itemIdentifier: SelectionIdentifier)
			toolbarItem!.view = selectionTBView
			toolbarItem!.label = "Selection Tools"
			toolbarItem!.paletteLabel = "Selection Tools"
			toolbarItem!.menuFormRepresentation = selectionMenu
			// set sizes
			toolbarItem!.minSize = selectionTBView.frame.size
			toolbarItem!.maxSize = selectionTBView.frame.size
			
		case DrawIdentifier:
			toolbarItem = SeaToolbarItem(itemIdentifier: DrawIdentifier)
			toolbarItem!.view = drawTBView
			toolbarItem!.label = "Draw Tools"
			toolbarItem!.paletteLabel = "Draw Tools"
			toolbarItem!.menuFormRepresentation = drawMenu
			toolbarItem!.minSize = drawTBView.frame.size
			toolbarItem!.maxSize = drawTBView.frame.size
			
		case EffectIdentifier:
			toolbarItem = SeaToolbarItem(itemIdentifier: EffectIdentifier)
			toolbarItem!.view = effectTBView
			toolbarItem!.label = "Effect Tools"
			toolbarItem!.paletteLabel = "Effect Tools"
			toolbarItem!.menuFormRepresentation = effectMenu
			toolbarItem!.minSize = effectTBView.frame.size
			toolbarItem!.maxSize = effectTBView.frame.size

		case TransformIdentifier:
			toolbarItem = SeaToolbarItem(itemIdentifier: TransformIdentifier)
			toolbarItem!.view = transformTBView
			toolbarItem!.label = "Transform Tools"
			toolbarItem!.paletteLabel = "Transform Tools"
			toolbarItem!.menuFormRepresentation = transformMenu
			toolbarItem!.minSize = transformTBView.frame.size
			toolbarItem!.maxSize = transformTBView.frame.size

		case ColorsIdentifier:
			toolbarItem = SeaToolbarItem(itemIdentifier: ColorsIdentifier)
			toolbarItem!.view = colorView
			toolbarItem!.label = "Colors"
			toolbarItem!.paletteLabel = "Colors"
			toolbarItem!.menuFormRepresentation = colorsMenu
			toolbarItem!.minSize = colorView.frame.size
			toolbarItem!.maxSize = colorView.frame.size

		case NewLayerToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: NewLayerToolbarItemIdentifier, label: NSLocalizedString("new", value: "New", comment: "New"), imageNamed: "toolbar/new", toolTip: NSLocalizedString("new tooltip", value: "Add a new layer to the image", comment: "new tooltip"), target: SeaController.utilitiesManager().pegasusUtility(for: document), selector: #selector(PegasusUtility.addLayer(_:)))
			
		case DuplicateLayerToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: DuplicateLayerToolbarItemIdentifier, label: NSLocalizedString("duplicate", value: "Duplicate", comment: "Duplicate"), imageNamed: "toolbar/duplicate", toolTip: NSLocalizedString("duplicate tooltip", value: "Duplicate the current layer", comment: "Duplicate the current layer"), target: SeaController.utilitiesManager().pegasusUtility(for: document), selector: #selector(PegasusUtility.duplicateLayer(_:)))

		case ForwardToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: ForwardToolbarItemIdentifier, label: NSLocalizedString("forward", value: "Forward", comment: "Forward"), imageNamed: "toolbar/forward", toolTip: NSLocalizedString("forward tooltip", value: "Move the current layer forward", comment: "Move the current layer forward"), target: SeaController.utilitiesManager().pegasusUtility(for: document), selector: #selector(PegasusUtility.forward(_:)))

		case BackwardToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: BackwardToolbarItemIdentifier, label: NSLocalizedString("backward", value: "Backward", comment: "Backward"), imageNamed: "toolbar/backward", toolTip: NSLocalizedString("backward tooltip", value: "Move the current layer backward", comment: "Move the current layer backward"), target: SeaController.utilitiesManager().pegasusUtility(for: document), selector: #selector(PegasusUtility.backward(_:)))

		case DeleteLayerToolbarItemIdentifier:
			let icon = NSWorkspace.sharedWorkspace().iconForFileType(NSFileTypeForHFSTypeCode(OSType(kToolbarDeleteIcon)))
			return ImageToolbarItem(itemIdentifier: DeleteLayerToolbarItemIdentifier, label: NSLocalizedString("delete", value: "Delete", comment: "delete"), image: icon, toolTip: NSLocalizedString("delete tooltip", value: "Delete the current layer", comment: "Delete the current layer"), target: SeaController.utilitiesManager().pegasusUtility(for: document), selector: #selector(PegasusUtility.deleteLayer(_:)))
			
		case ZoomInToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: ZoomInToolbarItemIdentifier, label: NSLocalizedString("zoom in", value: "Zoom In", comment: "Zoom In"), imageNamed: "toolbar/zoomIn", toolTip: NSLocalizedString("zoom in tooltip", value: "Zoom in on the current view", comment: "Zoom in on the current view"), target: document.docView, selector: #selector(SeaView.zoomIn(_:)))

		case ZoomOutToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: ZoomOutToolbarItemIdentifier, label: NSLocalizedString("zoom out", value: "Zoom Out", comment: "Zoom Out"), imageNamed: "toolbar/zoomOut", toolTip: NSLocalizedString("zoom out tooltip", value: "Zoom out from the current view", comment: "Zoom out from the current view"), target: document.docView, selector: #selector(SeaView.zoomOut(_:)))

		case ActualSizeToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: ActualSizeToolbarItemIdentifier, label: NSLocalizedString("actual size", value: "Actual Size", comment: "Actual Size"), imageNamed: "toolbar/actualSize", toolTip: NSLocalizedString("actual size tooltip", value: "View the document at its actual size", comment: "View the document at its actual size"), target: document.docView, selector: #selector(SeaView.zoomNormal(_:)))

		case ToggleLayersToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: ToggleLayersToolbarItemIdentifier, label: NSLocalizedString("toggle layers", value: "Layers", comment: "toggle layers"), imageNamed: "toolbar/showhidelayers", toolTip: NSLocalizedString("toggle layers tooltip", value: "Show or hide the layers list view", comment: "Show or hide the layers list view"), target: SeaController.utilitiesManager().pegasusUtility(for: document), selector: #selector(PegasusUtility.toggleLayers(_:)))

		case InspectorToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: InspectorToolbarItemIdentifier, label: NSLocalizedString("information", value: "Information", comment: "Information"), imageNamed: NSImageNameInfo, toolTip: NSLocalizedString("information tooltip", value: "Show or hide point information", comment: "Show or hide point information"), target: SeaController.utilitiesManager().infoUtility(for: document), selector: #selector(InfoUtility.toggle(_:)))
			
		case FloatAnchorToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: FloatAnchorToolbarItemIdentifier, label: NSLocalizedString("float", value: "Float", comment: "Float"), imageNamed: "toolbar/float-tb", toolTip: NSLocalizedString("float tooltip", value: "Float or anchor the current selection", comment: "Float or anchor the current selection"), target: document.contents, selector: #selector(SeaContent.toggleFloatingSelection(_:)))
			
		case DuplicateSelectionToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: DuplicateSelectionToolbarItemIdentifier, label: NSLocalizedString("duplicate", value: "Duplicate", comment: "Duplicate"), imageNamed: "toolbar/duplicatesel", toolTip: NSLocalizedString("duplicate tooltip", value: "Duplicate the current selection", comment: "Duplicate the current selection"), target: document.contents, selector: #selector(SeaContent.duplicate(_:)))

		case SelectNoneToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: SelectNoneToolbarItemIdentifier, label: NSLocalizedString("select none", value: "None", comment: "select none"), imageNamed: "toolbar/none", toolTip: NSLocalizedString("select none tooltip", value: "Select nothing", comment: "select none tooltip"), target: document.docView, selector: #selector(SeaView.selectNone(_:)))
			
		case SelectAllToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: SelectAllToolbarItemIdentifier, label: NSLocalizedString("select all", value: "All", comment: "select all"), imageNamed: "toolbar/selectall", toolTip: NSLocalizedString("select All tooltip", value: "Select all of the current layer", comment: "select All tooltip"), target: document.docView, selector: #selector(SeaView.selectAll(_:)))
			
		case SelectInverseToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: SelectInverseToolbarItemIdentifier, label: NSLocalizedString("select inverse", value: "Inverse", comment: "select inverse"), imageNamed: "toolbar/selectinverse", toolTip: NSLocalizedString("select inverse tooltip", value: "Select the inverse of the current selection", comment: "select inverse tooltip"), target: document.docView, selector: #selector(SeaView.selectInverse(_:)))
			
		case SelectAlphaToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: SelectAlphaToolbarItemIdentifier, label: NSLocalizedString("select alpha", value: "Alpha", comment: "select alpha"), imageNamed: "toolbar/selectalpha", toolTip: NSLocalizedString("select alpha tooltip", value: "Select a copy of the alpha transparency channel", comment: "select alpha tooltip"), target: document.docView, selector: #selector(SeaView.selectOpaque(_:)))

		default:
			break
		}
		
		return toolbarItem
	}
	
	func toolbarDefaultItemIdentifiers(toolbar: NSToolbar) -> [String] {
		return [NSToolbarFlexibleSpaceItemIdentifier,
		SelectionIdentifier,
		DrawIdentifier,
		EffectIdentifier,
		TransformIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		ColorsIdentifier]
	}
	
	func toolbarAllowedItemIdentifiers(toolbar: NSToolbar) -> [String] {
		return [SelectionIdentifier,
		DrawIdentifier,
		EffectIdentifier,
		TransformIdentifier,
		ColorsIdentifier,
		//NewLayerToolbarItemIdentifier,
		//DuplicateLayerToolbarItemIdentifier,
		//ForwardToolbarItemIdentifier,
		//BackwardToolbarItemIdentifier,
		//DeleteLayerToolbarItemIdentifier,
		//ToggleLayersToolbarItemIdentifier,
		ZoomInToolbarItemIdentifier,
		ZoomOutToolbarItemIdentifier,
		ActualSizeToolbarItemIdentifier,
		//InspectorToolbarItemIdentifier,
		FloatAnchorToolbarItemIdentifier,
		DuplicateSelectionToolbarItemIdentifier,
		SelectNoneToolbarItemIdentifier,
		SelectAllToolbarItemIdentifier,
		SelectInverseToolbarItemIdentifier,
		SelectAlphaToolbarItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarSeparatorItemIdentifier]
	}
}
