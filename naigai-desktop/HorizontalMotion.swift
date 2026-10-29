import Foundation
struct HorizontalMotion {
 var x:CGFloat=0
 mutating func advance(by delta:CGFloat,minX:CGFloat,maxX:CGFloat)->(x:CGFloat,hitEdge:Bool){
  let desired=x+delta;x=min(max(desired,minX),maxX)
  return (x,x != desired)
 }
}
