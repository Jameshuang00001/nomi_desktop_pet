import Foundation
@main struct Tests {
 static func main(){
  let domain="nomi.history.test.\(UUID())",d=UserDefaults(suiteName:domain)!
  defer{d.removePersistentDomain(forName:domain)}
  d.set(["item":"old","fromX":100,"toX":58,"y":40,"steps":6] as [String:Any],forKey:"lastFolderDrag")
  let h=PositionHistory(defaults:d);assert(h.entries==[OriginalPosition(name:"old",x:100,y:40)])
  h.remember(name:"cat",x:500,y:200);h.remember(name:"cat",x:458,y:200)
  let reloaded=PositionHistory(defaults:d);assert(reloaded.entries.last?.x==500)
  reloaded.restored("old");assert(PositionHistory(defaults:d).entries.count==1)
  reloaded.restored("cat");reloaded.remember(name:"cat",x:700,y:400)
  assert(PositionHistory(defaults:d).entries==[OriginalPosition(name:"cat",x:700,y:400)])
  print("PASS: first origin preserved, persistence, legacy import once, selective removal and fresh origin after restore")
 }
}
