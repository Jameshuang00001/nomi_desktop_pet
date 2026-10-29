import Foundation

struct OriginalPosition:Codable,Equatable {let name:String;let x:Int;let y:Int}
// Accessed only on FolderBridge's serial queue. First origin wins until restored.
final class PositionHistory {
 let defaults:UserDefaults
 private(set) var entries:[OriginalPosition]
 init(defaults:UserDefaults = .standard){
  self.defaults=defaults
  entries=(defaults.data(forKey:"originalDesktopPositions").flatMap{try? JSONDecoder().decode([OriginalPosition].self,from:$0)}) ?? []
  if !defaults.bool(forKey:"positionHistoryLegacyImported") {
   if let last=defaults.dictionary(forKey:"lastFolderDrag"),let name=last["item"] as? String,let x=last["fromX"] as? Int,let end=last["toX"] as? Int,let y=last["y"] as? Int,x != end,(last["steps"] as? Int ?? 0)>0 {remember(name:name,x:x,y:y)}
   defaults.set(true,forKey:"positionHistoryLegacyImported")
  }
 }
 func remember(name:String,x:Int,y:Int){guard !entries.contains(where:{$0.name==name}) else{return};entries.append(OriginalPosition(name:name,x:x,y:y));save()}
 func restored(_ name:String){entries.removeAll{$0.name==name};save()}
 private func save(){if let data=try? JSONEncoder().encode(entries){defaults.set(data,forKey:"originalDesktopPositions")}}
}
