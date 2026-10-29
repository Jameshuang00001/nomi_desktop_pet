import AppKit

struct Dropping: Codable {
 var id:UUID; var x:Double; var y:Double; var size:Double
}
final class DroppingView:NSView {
 var clean:(()->Void)?
 var moved:(()->Void)?
 var image:NSImage?
 var dragStart=NSPoint.zero, windowStart=NSPoint.zero
 override func acceptsFirstMouse(for event:NSEvent?)->Bool{true}
 override func draw(_ dirtyRect:NSRect){image?.draw(in:bounds)}
 override func mouseDown(with event:NSEvent){dragStart=NSEvent.mouseLocation;windowStart=window!.frame.origin}
 override func mouseDragged(with event:NSEvent){let p=NSEvent.mouseLocation;window?.setFrameOrigin(NSPoint(x:windowStart.x+p.x-dragStart.x,y:windowStart.y+p.y-dragStart.y))}
 override func mouseUp(with event:NSEvent){moved?()}
 override func rightMouseDown(with event:NSEvent){let m=NSMenu();let i=NSMenuItem(title:"清理这颗便便",action:#selector(removeThis),keyEquivalent:"");i.target=self;m.addItem(i);m.popUp(positioning:nil,at:convert(event.locationInWindow,from:nil),in:self)}
 @objc func removeThis(){clean?()}
}
final class Droppings {
 var records:[Dropping]=[]
 var windows:[UUID:NSPanel]=[:]
 let defaults:UserDefaults
 init(defaults:UserDefaults = .standard){self.defaults=defaults}
 func restore(){if let d=defaults.data(forKey:"droppings"),let items=try? JSONDecoder().decode([Dropping].self,from:d){records=items.filter{$0.x.isFinite && $0.y.isFinite && $0.size.isFinite && $0.size>=12 && $0.size<=100};for r in records{show(r)}}}
 func save(){if let d=try? JSONEncoder().encode(records){defaults.set(d,forKey:"droppings")}}
 func add(at point:NSPoint,size:Double){let r=Dropping(id:UUID(),x:point.x,y:point.y,size:size);records.append(r);show(r);save()}
 func show(_ r:Dropping){
  let p=NSPanel(contentRect:NSRect(x:r.x,y:r.y,width:r.size,height:r.size),styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
  p.title="糯米的便便";p.isOpaque=false;p.backgroundColor = .clear;p.hasShadow=false;p.level = .floating;p.hidesOnDeactivate=false
  p.collectionBehavior=[.canJoinAllSpaces,.fullScreenNone,.fullScreenDisallowsTiling]
  let v=DroppingView(frame:NSRect(x:0,y:0,width:r.size,height:r.size));v.setAccessibilityElement(true);v.setAccessibilityRole(.button);v.setAccessibilityLabel("便便，左键拖动，右键清理");v.image=NSImage(contentsOf:Bundle.main.resourceURL!.appendingPathComponent("poop.png"))
  v.clean={ [weak self] in self?.remove(r.id) };v.moved={ [weak self] in self?.recordPosition(r.id) }
  p.contentView=v;windows[r.id]=p
  // Restore off-screen positions to a currently connected display.
  if !NSScreen.screens.contains(where:{$0.visibleFrame.intersects(p.frame)}),let s=NSScreen.main{p.setFrameOrigin(NSPoint(x:s.visibleFrame.midX,y:s.visibleFrame.minY+20))}
  p.orderFront(nil);recordPosition(r.id)
 }
 func recordPosition(_ id:UUID){guard let p=windows[id],let i=records.firstIndex(where:{$0.id==id}) else{return};records[i].x=p.frame.minX;records[i].y=p.frame.minY;save()}
 func remove(_ id:UUID){windows.removeValue(forKey:id)?.orderOut(nil);records.removeAll{$0.id==id};save()}
 func clear(){for w in windows.values{w.orderOut(nil)};windows.removeAll();records.removeAll();save()}
}
