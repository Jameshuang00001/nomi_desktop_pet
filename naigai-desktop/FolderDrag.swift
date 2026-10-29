import AppKit

struct DesktopFolder { let name:String; let x:Int; let y:Int }
final class FolderBridge {
 private let history=PositionHistory()
 private let queue=DispatchQueue(label:"nuomi.finder")
 static func literal(_ s:String)->String {"\""+s.replacingOccurrences(of:"\\",with:"\\\\").replacingOccurrences(of:"\"",with:"\\\"")+"\""}
 func nearby(_ completion:@escaping ([DesktopFolder],String?)->Void){
  queue.async {
   var error:NSDictionary?
   let script=NSAppleScript(source:"""
   tell application "Finder"
    set resultList to {}
    set desktopItems to get every item of desktop
    repeat with itemRef in desktopItems
     try
      set f to contents of itemRef
      if (class of f) is not disk then
       set p to get desktop position of f
       set itemName to get name of f
       set px to item 1 of p
       set py to item 2 of p
       set end of resultList to {itemName, px, py}
      end if
     end try
    end repeat
    return resultList
   end tell
   """)!
   let result=script.executeAndReturnError(&error)
   var folders:[DesktopFolder]=[]
   if error == nil && result.numberOfItems>0 {for i in 1...result.numberOfItems {if let r=result.atIndex(i),let name=r.atIndex(1)?.stringValue {folders.append(DesktopFolder(name:name,x:Int(r.atIndex(2)?.int32Value ?? -1),y:Int(r.atIndex(3)?.int32Value ?? -1)))}}}
   let message=error.map { e -> String in
    let code=(e[NSAppleScript.errorNumber] as? NSNumber)?.intValue ?? 0
    let detail=e[NSAppleScript.errorMessage] as? String ?? "未知错误"
    UserDefaults.standard.set("\(code): \(detail)",forKey:"finderLastError")
    if code == -1743 {return "macOS 拒绝了 Finder 自动化请求（-1743）。如果开关已经开启，可能是本地更新后签名变化导致旧授权失效，请重新关闭再开启糯米的 Finder 开关。"}
    return "Finder 调用失败（\(code)）：\(detail)"
   }
   if error == nil {UserDefaults.standard.set("success: \(folders.count) desktop items",forKey:"finderLastError")}
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
    if not (exists item \(name) of desktop) then return false
    set f to item \(name) of desktop
    set p to desktop position of f
    if (item 1 of p is not \(fromX)) or (item 2 of p is not \(folder.y)) then return false
    set desktop position of f to {\(toX), \(folder.y)}
    set p to desktop position of f
    return (item 1 of p is \(toX)) and (item 2 of p is \(folder.y))
   end tell
   """)!.executeAndReturnError(&error)
   let ok=error == nil && result.booleanValue
   if ok && fromX != toX {self.history.remember(name:folder.name,x:fromX,y:folder.y)}
   DispatchQueue.main.async{completion(ok)}
  }
 }
 func restorePositions(completion:@escaping(Int,Int)->Void){
  queue.async {
   var restored=0,failed=0
   for item in self.history.entries {
    var error:NSDictionary?
    let name=Self.literal(item.name)
    let result=NSAppleScript(source:"""
    tell application "Finder"
     if not (exists item \(name) of desktop) then return false
     set f to item \(name) of desktop
     set desktop position of f to {\(item.x), \(item.y)}
     set p to get desktop position of f
     return (item 1 of p is \(item.x)) and (item 2 of p is \(item.y))
    end tell
    """)!.executeAndReturnError(&error)
    if error == nil && result.booleanValue{restored+=1;self.history.restored(item.name)}else{failed+=1}
   }
   DispatchQueue.main.async{completion(restored,failed)}
  }
 }

}

extension Controller {
 @objc func restoreFilePositions(){
  guard !restoringPositions else{return}
  if desktopLayout().blocked{folderNotice("请先关闭桌面叠放，并将排序方式设为“无”，再还原文件位置。");return}
  cancelFolder();restoringPositions=true
  folderBridge.restorePositions{[weak self] restored,failed in
   guard let self=self else{return};self.restoringPositions=false
   self.nextFolder=ProcessInfo.processInfo.systemUptime+180
   if restored==0 && failed==0{self.folderNotice("没有可还原的位置记录。旧版本没有完整历史，无法推算此前所有文件的原位置。")}
   else{self.folderNotice("已还原 \(restored) 个桌面项目。"+(failed>0 ? "另有 \(failed) 个项目未能还原，记录已保留；请检查文件是否重命名、移出桌面或 Finder 权限。":""))}
  }
 }

 func folderNotice(_ message:String){let alert=NSAlert();alert.messageText="拖动桌面文件";alert.informativeText=message;alert.runModal()}
 @objc func dragNearestFile(){
  guard !restoringPositions else{return}
  cancelFolder()
  if animationPaused{pause()}
  if isSleeping{wakeManually()}
  if !panel.isVisible{toggleVisible()}
  web.evaluateJavaScript("finishPotty();stopLooking();roamUntil=0;setState(0);restUntil=performance.now()+10000"){[weak self] _,_ in
   guard let self=self else{return};self.pottyRunning=false;self.pottyPending=false
   self.attemptFolder(manual:true)
  }
 }

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
 func desktopLayout()->(blocked:Bool,iconSize:Double){
  CFPreferencesAppSynchronize("com.apple.finder" as CFString)
  let d=CFPreferencesCopyAppValue("DesktopViewSettings" as CFString,"com.apple.finder" as CFString) as? [String:Any] ?? [:]
  let icons=d["IconViewSettings"] as? [String:Any] ?? [:]
  let group=(d["GroupBy"] as? String ?? "None").lowercased()
  let arrangement=(icons["arrangeBy"] as? String ?? "none").lowercased()
  return (group != "none" || arrangement != "none",(icons["iconSize"] as? NSNumber)?.doubleValue ?? 64)
 }
 func attemptFolder(manual:Bool=false){
  guard !restoringPositions else{return}
  let layout=desktopLayout()
  if layout.blocked{if manual{folderNotice("桌面正在使用叠放或自动排序，项目坐标可能与可见图标不一致。请关闭“使用叠放”，将“排序方式”设为“无”后再拖动。")};return}
  let now=ProcessInfo.processInfo.systemUptime
  // Only work when Finder is foreground: do not drag icons behind another app.
  guard (manual || foldersAllowed),!folderBusy,!pottyRunning,!pottyPending,!dragging,!animationPaused,!isSleeping,!sleepPolicy.sleeping(at:Date()),panel.isVisible,panel.isOnActiveSpace,(manual || now>=nextFolder),(manual || NSWorkspace.shared.frontmostApplication?.bundleIdentifier=="com.apple.finder"),let screen=NSScreen.screens.first else{if manual{folderNotice("当前正在执行其他动作，或小猫不在当前桌面，请稍后再试。")};return}
  nextFolder=now+Double.random(in:90...180);folderBusy=true;folderGeneration+=1;let generation=folderGeneration
  folderBridge.nearby{[weak self] folders,error in
   guard let self=self,self.folderGeneration==generation else{return}
   if let error=error{self.folderFailure(error);return}
   let near=folders.filter { f in
    let point=NSPoint(x:f.x,y:Int(screen.frame.maxY)-f.y)
    return f.x>48 && f.y>0 && screen.visibleFrame.contains(point) && (manual || hypot(point.x-self.panel.frame.midX,point.y-self.panel.frame.midY)<180)
   }.min {a,b in hypot(Double(a.x)-self.panel.frame.midX,screen.frame.maxY-Double(a.y)-self.panel.frame.midY)<hypot(Double(b.x)-self.panel.frame.midX,screen.frame.maxY-Double(b.y)-self.panel.frame.midY)}
   guard let folder=near else{self.cancelFolder();if manual{self.folderNotice("当前主屏幕桌面没有可拖动的文件或文件夹。请确认图标已显示，且没有使用叠放隐藏它们。")};return}
   self.web.evaluateJavaScript("beginFolder()"){[weak self] value,_ in
    guard let self=self,self.folderGeneration==generation else{return}
    guard value as? Bool == true else{self.cancelFolder();if manual{self.folderNotice("动画尚未准备好或小猫正忙，请再点一次。")};return}
    let iconContact=NSPoint(x:Double(folder.x)-layout.iconSize/2+8,y:Double(screen.frame.maxY)-Double(folder.y)+layout.iconSize/2-8)
    let target=NSPoint(x:iconContact.x-134.8*self.sizeFactor,y:iconContact.y-31.6*self.sizeFactor)
    guard target.x-42>=screen.frame.minX else{self.cancelFolder();if manual{self.folderNotice("目标太靠近屏幕左侧，无法保持咬合拖动。请先将图标稍微向右移。")};return}
    UserDefaults.standard.set(["item":folder.name,"fromX":folder.x,"toX":folder.x,"y":folder.y,"steps":0] as [String:Any],forKey:"lastFolderDrag")
    let origin=self.panel.frame.origin;let start=ProcessInfo.processInfo.systemUptime
    var step=0,inFlight=false,currentX=folder.x
    self.folderTimer=Timer.scheduledTimer(withTimeInterval:1.0/30,repeats:true){[weak self] timer in
     guard let self=self,self.folderGeneration==generation else{timer.invalidate();return}
     guard (manual || self.foldersAllowed),!self.dragging,!self.animationPaused,!self.sleepPolicy.sleeping(at:Date()),self.panel.isVisible,self.panel.isOnActiveSpace,(manual || NSWorkspace.shared.frontmostApplication?.bundleIdentifier=="com.apple.finder") else{self.cancelFolder();return}
     let elapsed=ProcessInfo.processInfo.systemUptime-start
     if elapsed<1 {let t=elapsed*elapsed*(3-2*elapsed);self.panel.setFrameOrigin(NSPoint(x:origin.x+(target.x-origin.x)*t,y:origin.y+(target.y-origin.y)*t));return}
     if step==0 {
      self.panel.setFrameOrigin(target)
      guard hypot(self.panel.frame.minX-target.x,self.panel.frame.minY-target.y)<3 else{self.cancelFolder();if manual{self.folderNotice("目标靠近屏幕边缘，无法对齐嘴部，已停止拖动。")};return}
      self.web.evaluateJavaScript("folderPose(1)")
     }
     guard !inFlight,elapsed>=1.5+Double(step)*0.4 else{return}
     if step>=6{self.cancelFolder();self.motion.x=self.panel.frame.minX;return}
     inFlight=true;let nextX=currentX-7
     self.folderBridge.place(folder,fromX:currentX,toX:nextX){[weak self] ok in
      guard let self=self,self.folderGeneration==generation else{return};inFlight=false
      guard ok else{self.cancelFolder();if manual{self.folderNotice("Finder 未保持图标位置。请将桌面排序设为“无”，检查叠放设置，或确认该文件未被同时移动。")};return} // Auto-arrange or user changes: stop, never fight Finder.
      currentX=nextX;step+=1
      UserDefaults.standard.set(["item":folder.name,"fromX":folder.x,"toX":currentX,"y":folder.y,"steps":step] as [String:Any],forKey:"lastFolderDrag")
      self.panel.setFrameOrigin(NSPoint(x:target.x-Double(step)*7,y:target.y));self.motion.x=self.panel.frame.minX
      self.web.evaluateJavaScript("folderPose(\(step%2==0 ? 2:3))")
     }
    }
   }
  }
 }
}
