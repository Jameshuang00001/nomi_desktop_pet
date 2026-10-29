import AppKit
@main struct Tests {
 static func main(){
  let name="local.nuomi.test.\(UUID())", defaults=UserDefaults(suiteName:name)!
  defer{defaults.removePersistentDomain(forName:name)}
  let store=Droppings(defaults:defaults)
  let a=Dropping(id:UUID(),x:12,y:34,size:24),b=Dropping(id:UUID(),x:56,y:78,size:24)
  store.records=[a,b];store.save()
  let loaded=try! JSONDecoder().decode([Dropping].self,from:defaults.data(forKey:"droppings")!)
  assert(loaded.count==2 && loaded[0].x==12 && loaded[1].id==b.id)
  store.remove(a.id);assert(store.records.count==1 && store.records[0].id==b.id)
  store.clear();assert(store.records.isEmpty)
  let empty=try! JSONDecoder().decode([Dropping].self,from:defaults.data(forKey:"droppings")!)
  assert(empty.isEmpty)
  print("PASS: durable IDs and positions, individual cleanup, clear-all and saved empty state")
 }
}
