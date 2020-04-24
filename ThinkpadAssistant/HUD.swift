//
//  HUD.swift
//  ThinkpadAssistant
//
//  Copyright © 2020 Matthäus Szturc. All rights reserved.
//

import AppKit

typealias ProgressHUDDismissCompletion = () -> Void

class HUD: NSView {
    
    static let shared = HUD()
    
    private override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        // setup view
        autoresizingMask = [.maxXMargin, .minXMargin, .maxYMargin, .minYMargin]
        alphaValue = 0.0
        isHidden = true
        
        // setup status message label
        statusLabel.isEditable = false
        statusLabel.isSelectable = false
        statusLabel.alignment = .center
        statusLabel.backgroundColor = .clear
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.font = NSFont.systemFont(ofSize: 20)
        addSubview(statusLabel)
        
        // setup window into which to display the HUD
        let screen = NSScreen.screens[0]
        let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: true, screen: screen)
        window.level = .floating
        window.backgroundColor = .clear
        windowController = NSWindowController(window: window)
        
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Presents a HUD with an image + status, and dismisses the HUD a little bit later
    class func showImage(_ image: NSImage, status: String) {
        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        imageView.image = image
        HUD.shared.show(withStatus: status, imageView: imageView)
        HUD.dismiss(delay: 1.5)
    }
    
    /// Dismisses the currently visible `ProgressHUD` if visible, after a time interval
    class func dismiss(delay: TimeInterval) {
        HUD.shared.perform(#selector(hideDelayed), with: 1, afterDelay: delay)
    }
    
    private var image: NSView?
    private let statusLabel = NSText(frame: .zero)
    private var windowController: NSWindowController?
    
    private var hudView: NSView? {
        windowController?.showWindow(self)
        windowController?.window?.contentView?.insertVisualEffectView()
        return windowController?.window?.contentView
    }
    
    private func show(withStatus status: String, imageView: NSView) {
        guard let view = hudView else { return }
        
        if isHidden {
            frame = view.frame
            view.addSubview(self)
        } else {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
        }
        setupImage(view: imageView)
        setStatus(status)
        show()
    }
    
    private func show() {
        needsDisplay = true
        isHidden = false
        
        // Fade in
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.20
        animator().alphaValue = 1.0
        window?.animator().alphaValue = 1.0
        NSAnimationContext.endGrouping()
        
    }
    
    private func hide() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        // Fade out
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.20
        NSAnimationContext.current.completionHandler = {
            self.done()
        }
        animator().alphaValue = 0
        window?.animator().alphaValue = 0
        
        NSAnimationContext.endGrouping()
        
    }
    
    private func done() {
        alphaValue = 0.0
        window?.alphaValue = 0.0
        isHidden = true
        removeFromSuperview()
        image?.removeFromSuperview()
        image = nil
        statusLabel.string = ""
        windowController?.close()
    }
    
    private func setStatus(_ status: String) {
        statusLabel.string = status
        statusLabel.alignCenter(nil)
        statusLabel.sizeToFit()
    }
    
    private func setupImage(view: NSView) {
        image?.removeFromSuperview()
        image = view
        addSubview(image!)
    }
    
    @objc private func hideDelayed() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        hide()
    }
    
    // MARK: - Layout & Drawing
    
    override func draw(_ rect: NSRect) { //(0.0, 0.0, 1280.0, 720.0)
        
        var imageFrame = image?.bounds ?? .zero //128x128 Todo: Prüfen ob ein 2x bild verwendet wird
        
        
        var statusLabelSize: CGSize = statusLabel.string.count > 0 ? statusLabel.string.size(withAttributes: [NSAttributedString.Key.font: statusLabel.font!]) : CGSize.zero
        if statusLabelSize.width > 0.0 { //103x46
            statusLabelSize.width += 10.0
        }
        // Position elements
        var yPos = CGFloat(156)
        
        if statusLabelSize.height > 0.0 && imageFrame.size.height > 0.0 {
            yPos += statusLabelSize.height //175
        }
        let xPos: CGFloat = 0
        imageFrame.origin.y = yPos
        imageFrame.origin.x = round((bounds.size.width - imageFrame.size.width) / 2) + xPos //576
        image?.frame = imageFrame
        
        if statusLabelSize.height > 0.0 && imageFrame.size.height > 0.0 {
            yPos -= statusLabelSize.height //129
        }
        var statusLabelFrame = CGRect.zero
        statusLabelFrame.origin.y = yPos
        statusLabelFrame.origin.x = round((bounds.size.width - statusLabelSize.width) / 2) + xPos //583
        statusLabelFrame.size = statusLabelSize
        statusLabel.frame = statusLabelFrame
        
    }
    
}

class RoundedEffectView: NSVisualEffectView {
    
    var cornerRadius: CGFloat = 20 {
        didSet{
            needsDisplay = true
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        blendingMode = .behindWindow
        material = .popover
        state = .active
    }
    
    override func updateLayer() {
        super.updateLayer()
        let xPos = NSApplication.shared.windows[0].screen!.frame.width/2 - 100
        frame = NSRect(x: xPos, y: 140, width: 200, height: 200)
        layer?.cornerRadius = cornerRadius
    }
}


extension NSView{
    
    func insertVisualEffectView(){
        let vibrant = RoundedEffectView(frame: bounds)
        addSubview(vibrant, positioned: .below, relativeTo: nil)
    }
}
