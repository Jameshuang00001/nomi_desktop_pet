import Foundation
@main struct TestMotion {
 static func main(){
  for hz in [60,120] {
   var right=HorizontalMotion(x:500),left=HorizontalMotion(x:500)
   for _ in 0..<(hz*5) { _=right.advance(by:18/Double(hz),minX:0,maxX:1000);_=left.advance(by:-18/Double(hz),minX:0,maxX:1000) }
   precondition(abs(right.x-590)<0.00001 && abs(left.x-410)<0.00001)
  }
  var edge=HorizontalMotion(x:999.9);precondition(edge.advance(by:0.3,minX:0,maxX:1000).hitEdge)
  precondition(edge.advance(by:-0.3,minX:0,maxX:1000).x<1000)
  print("PASS symmetric 90pt/5s travel at60/120Hz, boundary reverse")
 }
}
