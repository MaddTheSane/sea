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

private let DocToolbarIdentifier = NSToolbar.Identifier("Document Toolbar Instance Identifier")

private let SelectionIdentifier	= NSToolbarItem.Identifier("Selection  Item Identifier")
private let DrawIdentifier		= NSToolbarItem.Identifier("Draw Item Identifier")
private let EffectIdentifier	= NSToolbarItem.Identifier("Effect Item Identifier")
private let TransformIdentifier	= NSToolbarItem.Identifier("Transform Item Identifier")
private let ColorsIdentifier	= NSToolbarItem.Identifier("Colors Item Identifier")

// Additional (Non-default) toolbar items
private let ZoomInToolbarItemIdentifier = NSToolbarItem.Identifier("Zoom In Toolbar Item Identifier")
private let ZoomOutToolbarItemIdentifier = NSToolbarItem.Identifier("Zoom Out Toolbar Item Identifier")
private let ActualSizeToolbarItemIdentifier = NSToolbarItem.Identifier("Actual Size Toolbar Item Identifier")
private let NewLayerToolbarItemIdentifier = NSToolbarItem.Identifier("New Layer Toolbar Item Identifier")
private let DuplicateLayerToolbarItemIdentifier = NSToolbarItem.Identifier("Duplicate Layer Toolbar Item Identifier")
private let ForwardToolbarItemIdentifier = NSToolbarItem.Identifier("Move Layer Forward  Toolbar Item Identifier")
private let BackwardToolbarItemIdentifier = NSToolbarItem.Identifier("Move Layer Backward Toolbar Item Identifier")
private let DeleteLayerToolbarItemIdentifier = NSToolbarItem.Identifier("Delete Layer Toolbar Item Identifier")
private let ToggleLayersToolbarItemIdentifier = NSToolbarItem.Identifier("Show/Hide Layers Item Identifier")
private let InspectorToolbarItemIdentifier = NSToolbarItem.Identifier("Show/Hide Inspector Toolbar Item Identifier")
private let FloatAnchorToolbarItemIdentifier = NSToolbarItem.Identifier("Float/Anchor Toolbar Item Identifier")
private let DuplicateSelectionToolbarItemIdentifier = NSToolbarItem.Identifier("Duplicate Selection Toolbar Item Identifier")
private let SelectNoneToolbarItemIdentifier = NSToolbarItem.Identifier("Select None Toolbar Item Identifier")
private let SelectAllToolbarItemIdentifier = NSToolbarItem.Identifier("Select All Toolbar Item Identifier")
private let SelectInverseToolbarItemIdentifier = NSToolbarItem.Identifier("Select Inverse Toolbar Item Identifier")
private let SelectAlphaToolbarItemIdentifier = NSToolbarItem.Identifier("Select Alpha Toolbar Item Identifier")


class ToolboxUtility2 : NSObject {
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
			delayTimer = Timer(timeInterval: 0.1, target: (document.tools! as Seashore.SeaTools).getTool(.text)!, selector: #selector(TextTool.preview(_:)), userInfo: nil, repeats: false)
			SeaController.utilitiesManager.statusUtility(for: document)!.updateQuickColor()
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
	private(set) var tool = SeaToolsDefines.invalid
	
	/// The old tool
	private var oldTool = SeaToolsDefines.invalid
	
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
		.selectRect,
		.selectEllipse,
		.lasso,
		.polygonLasso,
		.wand]
	private let drawTools: [SeaToolsDefines] = [
		.pencil,
		.brush,
		.text,
		.eraser,
		.bucket,
		.gradient];
	private let effectTools: [SeaToolsDefines] = [
		.effect,
		.smudge,
		.clone];
	private let transformTools: [SeaToolsDefines] = [
		.eyedrop,
		.crop,
		.zoom,
		.position];
	
	/// A timer that delays colour changes
	private var delayTimer: Timer?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Create the toolbar instance, and attach it to our document window
		toolbar = NSToolbar(identifier: DocToolbarIdentifier);

		// Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults
		toolbar.allowsUserCustomization = true
		toolbar.autosavesConfiguration = true
		toolbar.displayMode = .iconOnly
		
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
		if tool == .invalid {
			changeTool(to: .selectRect)
		}
		
		// Set the document appropriately
		colorView.document = document
		
		// Then pretend a tool change
		update(full: true)
	}
	
	/// Deactivates this utility.
	func deactivate() {
		colorView.document = document
		for i in SeaToolsDefines.firstSelection.rawValue ... SeaToolsDefines.lastSelection.rawValue {
			toolbox.cell(withTag: Int(i))?.isEnabled = true
		}
	}
	
	/// Updates the utility for the current document.
	/// - parameter full: `true` if the update is to also include setting 
	/// the cursor, `false` otherwise.
	@objc(update:) func update(full: Bool) {
		if full {
			/* Disable or enable the tool */
			if document.selection.isFloating {
				for i in SeaToolsDefines.firstSelection.rawValue ... SeaToolsDefines.lastSelection.rawValue {
					selectionTBView.setEnabled(false, forSegment: i)
				}
				selectionMenu.isEnabled = false
			} else {
				for i in SeaToolsDefines.firstSelection.rawValue ... SeaToolsDefines.lastSelection.rawValue {
					selectionTBView.setEnabled(true, forSegment: i)
				}
				selectionMenu.isEnabled = false
			}
			// Implement the change
			document.docView.needsDisplay = true
			optionsUtility.update()
			SeaController.seaHelp.updateInstantHelp(tool.rawValue)
		}
		colorView.update()
	}
	
	/// Called by menu item to change the tool.
	/// - parameter sender: An object with a tag that modulo-100 
	/// specifies the tool to be selected.
	@IBAction func selectToolUsingTag(_ sender: AnyObject) {
		let theTag = sender.tag
		let preTool = theTag! % 100
		if let newTool = SeaToolsDefines(rawValue: preTool) {
			changeTool(to: newTool)
		}
	}
	
	/// Called when the segmented controls get clicked.
	/// - parameter sender: The segemented control to select the tool.
	@IBAction func selectToolFromSender(_ sender: NSSegmentedControl) {
		if let newTool = SeaToolsDefines(rawValue: (sender.cell as! NSSegmentedCell).tag(forSegment: sender.selectedSegment) % 100) {
			changeTool(to: newTool)
		}
	}
	
	/// Preforms checks to make sure changing the tool is valid, and if any updates are needed.
	/// - parameter newTool: The index of the new tool.
	@objc(changeToolTo:) func changeTool(to newTool: SeaToolsDefines) {
		var updateCrop = false;
		
		document.helpers?.endLineDrawing()
		if (tool == .crop || newTool == .crop) {
			updateCrop = true;
			document.docView.needsDisplay = true
		}
		if tool == newTool, NSApp.currentEvent?.type == .leftMouseUp, let clickCnt = NSApp.currentEvent?.clickCount, clickCnt > 1 {
			SeaController.utilitiesManager.optionsUtility(for: document)!.show(nil)
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
			
			selectionTBView.selectSegment(withTag: Int(tool.rawValue))
			drawTBView.selectSegment(withTag: Int(tool.rawValue))
			effectTBView.selectSegment(withTag: Int(tool.rawValue))
			transformTBView.selectSegment(withTag: Int(tool.rawValue))
			
			update(full: true)
		}
		if (updateCrop) {
			SeaController.utilitiesManager.infoUtility(for: document)!.update()
		}
	}
	
	/// Selects the position tool.
	func floatTool() {
		// Show the banner
		document.warnings?.showFloatBanner()
		
		oldTool = tool;
		changeTool(to: .position)
	}
	
	/// Selects the last tool to call floatTool.
	func anchorTool() {
		// Hide the banner
		document.warnings?.hideFloatBanner()
		if oldTool != .invalid {
			changeTool(to: oldTool)
		}
	}
	
	func setEffectEnabled(_ enable: Bool) {
		effectTBView.setEnabled(enable, forSegment: SeaToolsDefines.effect.rawValue)
	}
	
	override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		if menuItem.tag >= 600 && menuItem.tag < 700 {
			menuItem.state = (menuItem.tag == Int(tool.rawValue) + 600) ? .on : .off
		}
		
		return true
	}
}

extension ToolboxUtility2: NSToolbarDelegate {
	func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
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
			return ImageToolbarItem(itemIdentifier: NewLayerToolbarItemIdentifier, label: NSLocalizedString("new", value: "New", comment: "New"), image: #imageLiteral(resourceName: "toolbar/new"), toolTip: NSLocalizedString("new tooltip", value: "Add a new layer to the image", comment: "new tooltip"), target: SeaController.utilitiesManager.pegasusUtility(for: document), selector: #selector(PegasusUtility.addLayer(_:)))
			
		case DuplicateLayerToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: DuplicateLayerToolbarItemIdentifier, label: NSLocalizedString("duplicate", value: "Duplicate", comment: "Duplicate"), image: #imageLiteral(resourceName: "toolbar/duplicate"), toolTip: NSLocalizedString("duplicate tooltip", value: "Duplicate the current layer", comment: "Duplicate the current layer"), target: SeaController.utilitiesManager.pegasusUtility(for: document), selector: #selector(PegasusUtility.duplicateLayer(_:)))

		case ForwardToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: ForwardToolbarItemIdentifier, label: NSLocalizedString("forward", value: "Forward", comment: "Forward"), image: #imageLiteral(resourceName: "toolbar/forward"), toolTip: NSLocalizedString("forward tooltip", value: "Move the current layer forward", comment: "Move the current layer forward"), target: SeaController.utilitiesManager.pegasusUtility(for: document), selector: #selector(PegasusUtility.forward(_:)))

		case BackwardToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: BackwardToolbarItemIdentifier, label: NSLocalizedString("backward", value: "Backward", comment: "Backward"), image: #imageLiteral(resourceName: "toolbar/backward"), toolTip: NSLocalizedString("backward tooltip", value: "Move the current layer backward", comment: "Move the current layer backward"), target: SeaController.utilitiesManager.pegasusUtility(for: document), selector: #selector(PegasusUtility.backward(_:)))

		case DeleteLayerToolbarItemIdentifier:
			let icon = NSWorkspace.shared.icon(forFileType: NSFileTypeForHFSTypeCode(OSType(kToolbarDeleteIcon)))
			return ImageToolbarItem(itemIdentifier: DeleteLayerToolbarItemIdentifier, label: NSLocalizedString("delete", value: "Delete", comment: "delete"), image: icon, toolTip: NSLocalizedString("delete tooltip", value: "Delete the current layer", comment: "Delete the current layer"), target: SeaController.utilitiesManager.pegasusUtility(for: document), selector: #selector(PegasusUtility.deleteLayer(_:)))
			
		case ZoomInToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: ZoomInToolbarItemIdentifier, label: NSLocalizedString("zoom in", value: "Zoom In", comment: "Zoom In"), image: #imageLiteral(resourceName: "toolbar/zoomIn"), toolTip: NSLocalizedString("zoom in tooltip", value: "Zoom in on the current view", comment: "Zoom in on the current view"), target: document.docView, selector: #selector(SeaView.zoomIn(_:)))

		case ZoomOutToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: ZoomOutToolbarItemIdentifier, label: NSLocalizedString("zoom out", value: "Zoom Out", comment: "Zoom Out"), image: #imageLiteral(resourceName: "toolbar/zoomOut"), toolTip: NSLocalizedString("zoom out tooltip", value: "Zoom out from the current view", comment: "Zoom out from the current view"), target: document.docView, selector: #selector(SeaView.zoomOut(_:)))

		case ActualSizeToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: ActualSizeToolbarItemIdentifier, label: NSLocalizedString("actual size", value: "Actual Size", comment: "Actual Size"), image: #imageLiteral(resourceName: "toolbar/actualSize"), toolTip: NSLocalizedString("actual size tooltip", value: "View the document at its actual size", comment: "View the document at its actual size"), target: document.docView, selector: #selector(SeaView.zoomNormal(_:)))

		case ToggleLayersToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: ToggleLayersToolbarItemIdentifier, label: NSLocalizedString("toggle layers", value: "Layers", comment: "toggle layers"), image: #imageLiteral(resourceName: "toolbar/showhidelayers"), toolTip: NSLocalizedString("toggle layers tooltip", value: "Show or hide the layers list view", comment: "Show or hide the layers list view"), target: SeaController.utilitiesManager.pegasusUtility(for: document), selector: #selector(PegasusUtility.toggleLayers(_:)))

		case InspectorToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: InspectorToolbarItemIdentifier, label: NSLocalizedString("information", value: "Information", comment: "Information"), imageNamed: .info, toolTip: NSLocalizedString("information tooltip", value: "Show or hide point information", comment: "Show or hide point information"), target: SeaController.utilitiesManager.infoUtility(for: document), selector: #selector(InfoUtility.toggle(_:)))
			
		case FloatAnchorToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: FloatAnchorToolbarItemIdentifier, label: NSLocalizedString("float", value: "Float", comment: "Float"), image: #imageLiteral(resourceName: "toolbar/float-tb"), toolTip: NSLocalizedString("float tooltip", value: "Float or anchor the current selection", comment: "Float or anchor the current selection"), target: document.contents, selector: #selector(SeaContent.toggleFloatingSelection(_:)))
			
		case DuplicateSelectionToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: DuplicateSelectionToolbarItemIdentifier, label: NSLocalizedString("duplicate", value: "Duplicate", comment: "Duplicate"), image: #imageLiteral(resourceName: "toolbar/duplicatesel"), toolTip: NSLocalizedString("duplicate tooltip", value: "Duplicate the current selection", comment: "Duplicate the current selection"), target: document.contents, selector: #selector(SeaContent.duplicate(_:)))

		case SelectNoneToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: SelectNoneToolbarItemIdentifier, label: NSLocalizedString("select none", value: "None", comment: "select none"), image: #imageLiteral(resourceName: "toolbar/none"), toolTip: NSLocalizedString("select none tooltip", value: "Select nothing", comment: "select none tooltip"), target: document.docView, selector: #selector(SeaView.selectNone(_:)))
			
		case SelectAllToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: SelectAllToolbarItemIdentifier, label: NSLocalizedString("select all", value: "All", comment: "select all"), image: #imageLiteral(resourceName: "toolbar/selectall"), toolTip: NSLocalizedString("select All tooltip", value: "Select all of the current layer", comment: "select All tooltip"), target: document.docView, selector: #selector(SeaView.selectAll(_:)))
			
		case SelectInverseToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: SelectInverseToolbarItemIdentifier, label: NSLocalizedString("select inverse", value: "Inverse", comment: "select inverse"), image: #imageLiteral(resourceName: "toolbar/selectinverse"), toolTip: NSLocalizedString("select inverse tooltip", value: "Select the inverse of the current selection", comment: "select inverse tooltip"), target: document.docView, selector: #selector(SeaView.selectInverse(_:)))
			
		case SelectAlphaToolbarItemIdentifier:
			return ImageToolbarItem(itemIdentifier: SelectAlphaToolbarItemIdentifier, label: NSLocalizedString("select alpha", value: "Alpha", comment: "select alpha"), image: #imageLiteral(resourceName: "toolbar/selectalpha"), toolTip: NSLocalizedString("select alpha tooltip", value: "Select a copy of the alpha transparency channel", comment: "select alpha tooltip"), target: document.docView, selector: #selector(SeaView.selectOpaque(_:)))

		default:
			break
		}
		
		return toolbarItem
	}
	
	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return [NSToolbarItem.Identifier.flexibleSpace,
		SelectionIdentifier,
		DrawIdentifier,
		EffectIdentifier,
		TransformIdentifier,
		NSToolbarItem.Identifier.flexibleSpace,
		ColorsIdentifier]
	}
	
	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
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
		NSToolbarItem.Identifier.customizeToolbar,
		NSToolbarItem.Identifier.flexibleSpace,
		NSToolbarItem.Identifier.space,
		NSToolbarItem.Identifier.separator]
	}
}
