import AppKit

struct DesktopFolder { let name:String; let x:Int; let y:Int }
final class FolderBridge {
 private let queue=DispatchQueue(label:"nuomi.finder")
 static func literal(_ s:String)->String {"\""+s.replacingOccurrences(of:"\\",with:"\\\\").replacingOccurrences(of:"\"",with:"\\\"")+"\""}
 func nearby(_ completion:@escaping ([DesktopFolder],String?)->Void){
  queue.async {
   var error:NSDictionary?
   let script=NSAppleScript(source:"""
   tell application "Finder"
    set resultList to {}
    repeat with f in (folders of desktop)
     try
      set p to desktop position of f
      set end of resultList to {name of f, item 1 of p, item 2 of p}
     end try
    end repeat
    return resultList
   end tell
   """)!
   let result=script.executeAndReturnError(&error)
   var folders:[DesktopFolder]=[]
   if error == nil && result.numberOfItems>0 {for i in 1...result.numberOfItems {if let r=result.atIndex(i),let name=r.atIndex(1)?.stringValue {folders.append(DesktopFolder(name:name,x:Int(r.atIndex(2)?.int32Value ?? -1),y:Int(r.atIndex(3)?.int32Value ?? -1)))}}}
   let message=error == nil ? nil:"无法访问 Finder；请在系统设置的自动化权限中允许糯米控制 Finder。"
   DispatchQueue.main.async{completion(folders,message)}
  }
 }
 // Only change desktop icon coordinates. Never move, rename or open filesystem items.
 func place(_ folder:DesktopFolder,fromX:Int,toX:Int,completion:@escaping (Bool)->Void){
  let name=Self.literal(folder.name)
  queue.async {
   var error:NSDictionary?
   let result=NSAppleScript(source:"""
   tell application "Finder"
    if not (exists folder \(name) of desktop) then return false
    set f to folder \(name) of desktop
    set p to desktop position of f
    if (item 1 of p is not \(fromX)) or (item 2 of p is not \(folder.y)) then return false
    set desktop position of f to {\(toX), \(folder.y)}
    set p to desktop position of f
    return (item 1 of p is \(toX)) and (item 2 of p is \(folder.y))
   end tell
   """)!.executeAndReturnError(&error)
   let ok=error == nil && result.booleanValue
   DispatchQueue.main.async{completion(ok)}
  }
 }
}

extension Controller {
 @objc func toggleFolders(){
  foldersAllowed.toggle();UserDefaults.standard.set(foldersAllowed,forKey:"foldersAllowed");status.menu=menu()
  if !foldersAllowed{cancelFolder();return}
  nextFolder=ProcessInfo.processInfo.systemUptime+15
  folderBridge.nearby{[weak self] _,error in if let error=error{self?.folderFailure(error)}}
 }
 func folderFailure(_ message:String){
  foldersAllowed=false;UserDefaults.standard.set(false,forKey:"foldersAllowed");cancelFolder();status.menu=menu()
  let alert=NSAlert();alert.messageText="暂时不能拖动桌面文件夹";alert.informativeText=message;alert.runModal()
 }
 func cancelFolder(){
  guard folderBusy else{return};folderGeneration+=1;folderTimer?.invalidate();folderTimer=nil;folderBusy=false
  nextFolder=ProcessInfo.processInfo.systemUptime+Double.random(in:90...180)
  web?.evaluateJavaScript("endFolder()")
 }
 func attemptFolder(){
  let now=ProcessInfo.processInfo.systemUptime
  // Only work when Finder is foreground: do not drag icons behind another app.
  guard foldersAllowed,!folderBusy,!pottyRunning,!pottyPending,!dragging,!animationPaused,!isSleeping,!sleepPolicy.sleeping(at:Date()),panel.isVisible,panel.isOnActiveSpace,now>=nextFolder,NSWorkspace.shared.frontmostApplication?.bundleIdentifier=="com.apple.finder",let screen=NSScreen.screens.first else{return}
  nextFolder=now+Double.random(in:90...180);folderBusy=true;folderGeneration+=1;let generation=folderGeneration
  folderBridge.nearby{[weak self] folders,error in
   guard let self=self,self.folderGeneration==generation else{return}
   if let error=error{self.folderFailure(error);return}
   let near=folders.filter { f in
    let point=NSPoint(x:f.x,y:Int(screen.frame.maxY)-f.y)
    return f.x>100 && f.y>40 && screen.visibleFrame.contains(point) && hypot(point.x-self.panel.frame.midX,point.y-self.panel.frame.midY)<180
   }.min {a,b in hypot(Double(a.x)-self.panel.frame.midX,screen.frame.maxY-Double(a.y)-self.panel.frame.midY)<hypot(Double(b.x)-self.panel.frame.midX,screen.frame.maxY-Double(b.y)-self.panel.frame.midY)}
   guard let folder=near else{self.cancelFolder();return}
   self.web.evaluateJavaScript("beginFolder()"){[weak self] value,_ in
    guard let self=self,self.folderGeneration==generation else{return}
    guard value as? Bool == true else{self.cancelFolder();return}
    let target=NSPoint(x:Double(folder.x)-24-135*self.sizeFactor,y:Double(screen.frame.maxY)-Double(folder.y)+24.0-42.0*self.sizeFactor)
    guard screen.visibleFrame.contains(NSRect(origin:target,size:self.panel.frame.size)),target.x-42>=screen.visibleFrame.minX else{self.cancelFolder();return}
    let origin=self.panel.frame.origin;let start=ProcessInfo.processInfo.systemUptime
    var step=0,inFlight=false,currentX=folder.x
    self.folderTimer=Timer.scheduledTimer(withTimeInterval:1.0/30,repeats:true){[weak self] timer in
     guard let self=self,self.folderGeneration==generation else{timer.invalidate();return}
     guard self.foldersAllowed,!self.dragging,!self.animationPaused,!self.sleepPolicy.sleeping(at:Date()),self.panel.isVisible,self.panel.isOnActiveSpace,NSWorkspace.shared.frontmostApplication?.bundleIdentifier=="com.apple.finder" else{self.cancelFolder();return}
     let elapsed=ProcessInfo.processInfo.systemUptime-start
     if elapsed<1 {let t=elapsed*elapsed*(3-2*elapsed);self.panel.setFrameOrigin(NSPoint(x:origin.x+(target.x-origin.x)*t,y:origin.y+(target.y-origin.y)*t));return}
     if step==0 {self.panel.setFrameOrigin(target)}
     guard !inFlight,elapsed>=1.5+Double(step)*0.4 else{return}
     if step>=6{self.cancelFolder();self.motion.x=self.panel.frame.minX;return}
     inFlight=true;let nextX=currentX-7
     self.folderBridge.place(folder,fromX:currentX,toX:nextX){[weak self] ok in
      guard let self=self,self.folderGeneration==generation else{return};inFlight=false
      guard ok else{self.cancelFolder();return} // Auto-arrange or user changes: stop, never fight Finder.
      currentX=nextX;step+=1
      self.panel.setFrameOrigin(NSPoint(x:target.x-Double(step)*7,y:target.y));self.motion.x=self.panel.frame.minX
      self.web.evaluateJavaScript("folderPose(\(step%2==0 ? 2:3))")
     }
    }
   }
  }
 }
}
