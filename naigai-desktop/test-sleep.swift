import Foundation
@main struct Tests {
 static func main(){
  var c=Calendar(identifier:.gregorian);c.timeZone=TimeZone(secondsFromGMT:0)!
  func date(_ hour:Int,_ minute:Int=0)->Date {c.date(from:DateComponents(year:2026,month:10,day:29,hour:hour,minute:minute))!}
  var p=SleepPolicy()
  for (h,m,v) in [(22,59,false),(23,0,true),(0,0,true),(5,59,true),(6,0,false)] {assert(p.sleeping(at:date(h,m),calendar:c)==v)}
  let noon=date(12);p.rest();assert(p.sleeping(at:noon,calendar:c));p.unlocked(at:noon)
  assert(p.sleeping(at:noon.addingTimeInterval(44),calendar:c));assert(!p.sleeping(at:noon.addingTimeInterval(45),calendar:c))
  p.wakeManually(at:noon);assert(!p.sleeping(at:noon,calendar:c))
  let night=date(23);p.wakeManually(at:night);assert(!p.sleeping(at:night.addingTimeInterval(19),calendar:c));assert(p.sleeping(at:night.addingTimeInterval(20),calendar:c))
  p.rest();assert(p.sleeping(at:night,calendar:c));p.unlocked(at:night);assert(p.sleeping(at:night.addingTimeInterval(60),calendar:c))
  assert(!p.sleeping(at:date(6).addingTimeInterval(86400),calendar:c))
  print("Sleep schedule: boundaries, unlock nap, manual wake, lock priority passed")
 }
}
