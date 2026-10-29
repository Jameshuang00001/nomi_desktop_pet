import AppKit
import WebKit

final class Controller: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate {
 let folderBridge=FolderBridge()
 var foldersAllowed=UserDefaults.standard.bool(forKey:"foldersAllowed"), folderBusy=false
 var folderGeneration=0,folderTimer:Timer?
 var nextFolder=ProcessInfo.processInfo.systemUptime+30
 let droppings=Droppings()
 var pottyAllowed=UserDefaults.standard.bool(forKey:"pottyAllowed"), pottyRunning=false, pottyPending=false, deposited=false
 var nextPotty=ProcessInfo.processInfo.systemUptime+Double.random(in:120...240)
 var sleepPolicy=SleepPolicy(), isSleeping=false, pageReady=false
 var sleepTimer:Timer?
 var followUntil=0.0, lookRequestPending=false
 var lookTimer:Timer?, nextLook=ProcessInfo.processInfo.systemUptime+4
 var motion=HorizontalMotion(), motionSamples=0
 var motionTotals:[String:Double]=["leftRequested":0,"leftActual":0,"rightRequested":0,"rightActual":0]
 let sizeFactors:[Double]=[0.55,0.75,1,1.3,1.6]
 var panel:NSPanel!, web:WKWebView!, status:NSStatusItem!
 var sizeFactor=UserDefaults.standard.double(forKey:"sizeFactor"), roaming=true, animationPaused=false
 var start=NSPoint.zero, origin=NSPoint.zero, dragging=false
 func applicationDidFinishLaunching(_ notification:Notification) {
  panel=NSPanel(contentRect:NSRect(x:0,y:0,width:180,height:170),styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
  panel.title="糯米桌面宠物";panel.isOpaque=false;panel.backgroundColor = .clear;panel.hasShadow=false;panel.level = .floating
  panel.hidesOnDeactivate=false;panel.collectionBehavior=[.canJoinAllSpaces,.fullScreenNone,.fullScreenDisallowsTiling]
  let config=WKWebViewConfiguration();config.userContentController.add(self,name:"pet")
  web=WKWebView(frame:panel.contentView!.bounds,configuration:config);web.autoresizingMask=[.width,.height];web.setValue(false,forKey:"drawsBackground");web.navigationDelegate=self
  panel.contentView=web
  let html=Bundle.main.resourceURL!.appendingPathComponent("pet.html")
  web.loadFileURL(html,allowingReadAccessTo:html.deletingLastPathComponent())
  status=NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
  status.button?.image=NSImage(systemSymbolName:"pawprint.fill",accessibilityDescription:"糯米桌面宠物")
  let workspace=NSWorkspace.shared.notificationCenter
  workspace.addObserver(self,selector:#selector(sessionRest),name:NSWorkspace.sessionDidResignActiveNotification,object:nil)
  workspace.addObserver(self,selector:#selector(sessionRest),name:NSWorkspace.willSleepNotification,object:nil)
  workspace.addObserver(self,selector:#selector(sessionWake),name:NSWorkspace.sessionDidBecomeActiveNotification,object:nil)
  workspace.addObserver(self,selector:#selector(sessionWake),name:NSWorkspace.didWakeNotification,object:nil)
  let distributed=DistributedNotificationCenter.default()
  distributed.addObserver(self,selector:#selector(sessionRest),name:Notification.Name("com.apple.screenIsLocked"),object:nil)
  distributed.addObserver(self,selector:#selector(sessionWake),name:Notification.Name("com.apple.screenIsUnlocked"),object:nil)
  sleepTimer=Timer.scheduledTimer(timeInterval:1,target:self,selector:#selector(refreshSleep),userInfo:nil,repeats:true)
  roaming=UserDefaults.standard.object(forKey:"roaming") as? Bool ?? true
  if sizeFactor<=0 {sizeFactor=1};applySize();status.menu=menu();reset();droppings.restore();panel.orderFrontRegardless()
 }
 func webView(_ webView:WKWebView,didFinish navigation:WKNavigation!) {pageReady=true;refreshSleep();webView.evaluateJavaScript("setRoaming(\(roaming));document.body.dataset.nativeReady='true'");lookTimer?.invalidate();lookTimer=Timer.scheduledTimer(timeInterval:0.05,target:self,selector:#selector(tryLook),userInfo:nil,repeats:true)}
 @objc func tryLook(){
  let now=ProcessInfo.processInfo.systemUptime
  guard panel.isVisible,panel.isOnActiveSpace,!dragging,!animationPaused,!isSleeping,!pottyRunning,!folderBusy else{
   if followUntil>0 {followUntil=0;web.evaluateJavaScript("stopLooking()")};return
  }
  guard now<followUntil || (now>=nextLook && !lookRequestPending) else{return}
  let mouse=NSEvent.mouseLocation
  let dx=mouse.x-panel.frame.midX,dy=(panel.frame.maxY-panel.frame.height*0.32)-mouse.y
  if now<followUntil {
   web.evaluateJavaScript("updateLook(\(dx),\(dy))"){[weak self] value,_ in if value as? Bool == false {self?.followUntil=0}}
  } else {
   let duration=Double.random(in:3...5)
   nextLook=now+duration+Double.random(in:3...7);lookRequestPending=true
   web.evaluateJavaScript("occasionalLook(\(dx),\(dy),\(duration*1000))"){[weak self] value,_ in
    guard let self=self else{return};self.lookRequestPending=false
    if value as? Bool == true {self.followUntil=ProcessInfo.processInfo.systemUptime+duration}
   }
  }
 }
 @objc func togglePotty(){
  pottyAllowed.toggle();UserDefaults.standard.set(pottyAllowed,forKey:"pottyAllowed")
  if !pottyAllowed {web.evaluateJavaScript("finishPotty()");pottyRunning=false}
  nextPotty=ProcessInfo.processInfo.systemUptime+Double.random(in:30...60);status.menu=menu()
 }
 @objc func clearDroppings(){droppings.clear()}
 func attemptPotty(){
  let now=ProcessInfo.processInfo.systemUptime
  guard !folderBusy,pottyAllowed,!pottyRunning,!pottyPending,!sleepPolicy.sleeping(at:Date()),!animationPaused,!dragging,panel.isVisible,panel.isOnActiveSpace,now>=nextPotty else{return}
  pottyPending=true;nextPotty=now+5
  web.evaluateJavaScript("startPotty()"){[weak self] value,_ in
   guard let self=self else{return};self.pottyPending=false
   if value as? Bool == true {self.pottyRunning=true;self.deposited=false;self.followUntil=0}
  }
 }
 @objc func sessionRest(){sleepPolicy.rest();refreshSleep()}
 @objc func sessionWake(){sleepPolicy.unlocked(at:Date());refreshSleep()}
 @objc func wakeManually(){sleepPolicy.wakeManually(at:Date());refreshSleep()}
 @objc func refreshSleep(){
  guard pageReady else{return}
  if sleepPolicy.sleeping(at:Date()) || animationPaused || !panel.isVisible || !panel.isOnActiveSpace {cancelFolder()}
  attemptFolder()
  attemptPotty()
  let desired=sleepPolicy.sleeping(at:Date())
  guard desired != isSleeping else{return}
  isSleeping=desired;followUntil=0;nextLook=ProcessInfo.processInfo.systemUptime+4
  web.evaluateJavaScript("setSleeping(\(desired))")
  status.menu=menu()
 }
 func item(_ name:String,_ selector:Selector)->NSMenuItem {let i=NSMenuItem(title:name,action:selector,keyEquivalent:"");i.target=self;return i}
 func menu()->NSMenu {
  let m=NSMenu();m.addItem(NSMenuItem(title:"糯米 · 桌面宠物",action:nil,keyEquivalent:""))
  m.addItem(NSMenuItem(title:isSleeping ? "正在睡觉 · 夜间 23:00–06:00":"清醒中 · 夜间 23:00–06:00",action:nil,keyEquivalent:""))
  let wake=item("手动唤醒（夜间清醒20秒）",#selector(wakeManually));wake.isEnabled=isSleeping;m.addItem(wake)
  m.addItem(item("拖动文件（立即拖动最近的文件）",#selector(dragNearestFile)))
  let folders=item("允许糯米拖动文件夹",#selector(toggleFolders));folders.state=foldersAllowed ? .on:.off;m.addItem(folders)
  let potty=item("允许糯米拉屎",#selector(togglePotty));potty.state=pottyAllowed ? .on:.off;m.addItem(potty)
  m.addItem(item("一键清理",#selector(clearDroppings)))
  let roam=item("自由移动（原版动作）",#selector(toggleRoaming));roam.state=roaming ? .on:.off;m.addItem(roam)
  let sizes=NSMenuItem(title:"小猫大小",action:nil,keyEquivalent:"");let sub=NSMenu()
  for (i,label) in ["超小 · 74像素","迷你 · 100像素","小号 · 134像素","中号 · 175像素","大号 · 215像素"].enumerated(){let option=item(label,#selector(changeSize(_:)));option.tag=i;option.state=abs(sizeFactor-sizeFactors[i])<0.01 ? .on:.off;sub.addItem(option)}
  sizes.submenu=sub;m.addItem(sizes)
  m.addItem(item("挥挥爪",#selector(wave)));m.addItem(item(animationPaused ? "继续动画":"暂停动画",#selector(pause)));m.addItem(item("隐藏 / 显示",#selector(toggleVisible)));m.addItem(item("回到右下角",#selector(reset)));m.addItem(.separator());m.addItem(item("退出糯米",#selector(quit)));return m
 }
 func applySize(){let center=panel.frame.midX,bottom=panel.frame.minY;let size=NSSize(width:180*sizeFactor,height:170*sizeFactor);panel.setFrame(NSRect(x:center-size.width/2,y:bottom,width:size.width,height:size.height),display:true);web.pageZoom=sizeFactor;clamp()}
 @objc func changeSize(_ sender:NSMenuItem){cancelFolder();sizeFactor=sizeFactors[sender.tag];UserDefaults.standard.set(sizeFactor,forKey:"sizeFactor");applySize();status.menu=menu()}
 @objc func toggleRoaming(){roaming.toggle();UserDefaults.standard.set(roaming,forKey:"roaming");web.evaluateJavaScript("setRoaming(\(roaming))");status.menu=menu()}
 func userContentController(_ userContentController:WKUserContentController,didReceive message:WKScriptMessage) {
  guard message.frameInfo.isMainFrame,let body=message.body as? [String:Any],let action=body["action"] as? String else{return}
  switch action {
  case "dropping":
   if pottyRunning && pottyAllowed && !deposited && !isSleeping {
    deposited=true
    let size=max(18,24*sizeFactor)
    droppings.add(at:NSPoint(x:panel.frame.minX+135*sizeFactor-size/2,y:panel.frame.maxY-155*sizeFactor),size:size)
   }
  case "pottyFinished":pottyRunning=false;pottyPending=false;nextPotty=ProcessInfo.processInfo.systemUptime+Double.random(in:300...600)
  case "step":
   if !folderBusy && !pottyRunning && !isSleeping && roaming && !dragging && !animationPaused && panel.isVisible,let dx=body["dx"] as? Double,dx.isFinite,abs(dx)<2,let screen=panel.screen ?? NSScreen.main {let bounds=screen.visibleFrame;let previous=panel.frame.minX;let result=motion.advance(by:dx,minX:bounds.minX,maxX:bounds.maxX-panel.frame.width);panel.setFrameOrigin(NSPoint(x:result.x,y:panel.frame.minY));recordMotion(dx:dx,actual:panel.frame.minX-previous);if result.hitEdge {web.evaluateJavaScript("reverseRoaming(\(dx>0 ? -1:1))")}}
  case "down": cancelFolder();if let x=body["x"] as? Double,let y=body["y"] as? Double {start=NSPoint(x:x,y:y);origin=panel.frame.origin;motion.x=origin.x;dragging=true}
  case "move": if dragging,let x=body["x"] as? Double,let y=body["y"] as? Double {panel.setFrameOrigin(NSPoint(x:origin.x+x-start.x,y:origin.y-y+start.y))}
  case "up": dragging=false;clamp()
  case "menu": cancelFolder();dragging=false;let p=panel.convertPoint(fromScreen:NSEvent.mouseLocation);menu().popUp(positioning:nil,at:p,in:web)
  default: break
  }
 }
 // Bounded aggregate diagnostic; verifies actual window movement, not just JS messages.
 func recordMotion(dx:Double,actual:Double){let side=dx>=0 ? "right":"left";motionTotals[side+"Requested",default:0]+=dx;motionTotals[side+"Actual",default:0]+=actual;motionSamples+=1
  if motionSamples%120==0 {let values=motionTotals;let url=Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("motion-check.json");DispatchQueue.global(qos:.utility).async{if let data=try? JSONSerialization.data(withJSONObject:values,options:.prettyPrinted){try? data.write(to:url,options:.atomic)}}}
 }
 func clamp(){guard let screen=panel.screen ?? NSScreen.main else{return};let r=screen.visibleFrame;panel.setFrameOrigin(NSPoint(x:min(max(panel.frame.minX,r.minX),r.maxX-panel.frame.width),y:min(max(panel.frame.minY,r.minY),r.maxY-panel.frame.height)));motion.x=panel.frame.minX}
 @objc func reset(){cancelFolder();guard let s=NSScreen.main else{return};panel.setFrameOrigin(NSPoint(x:s.visibleFrame.maxX-panel.frame.width-20,y:s.visibleFrame.minY+20));motion.x=panel.frame.minX}
 @objc func wave(){guard !folderBusy && !pottyRunning && !isSleeping else{return};web.evaluateJavaScript("roamUntil=0;restUntil=performance.now()+3000;setState(3,1200)")}
 @objc func pause(){cancelFolder();animationPaused.toggle();web.evaluateJavaScript("roamUntil=0;restUntil=performance.now()+2000;if(isLooking)setState(0);cancelLook();document.getElementById('pause').click()");status.menu=menu()}
 @objc func toggleVisible(){cancelFolder();if panel.isVisible{panel.orderOut(nil);web.evaluateJavaScript("nativeHidden=true;roamUntil=0")}else{panel.orderFrontRegardless();web.evaluateJavaScript("nativeHidden=false;restUntil=performance.now()+2000")}}
 @objc func quit(){NSApp.terminate(nil)}
 // NSPanel is not a normal document window. Closing AppKit's temporary menu
 // window can invoke this callback even though the pet panel is still visible.
 // This menu-bar companion must stay alive until the explicit Quit action.
 func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication)->Bool{false}
}
let app=NSApplication.shared;app.setActivationPolicy(.accessory);let controller=Controller();app.delegate=controller;app.run()
