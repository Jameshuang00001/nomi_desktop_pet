import Foundation

struct SleepPolicy {
 var locked = false
 var napUntil = Date.distantPast
 var awakeUntil = Date.distantPast
 static func isNight(_ date: Date, calendar: Calendar = .current) -> Bool {
  let hour = calendar.component(.hour, from: date)
  return hour >= 23 || hour < 6
 }
 mutating func rest() { locked = true; awakeUntil = .distantPast }
 mutating func unlocked(at now: Date) {
  locked = false; napUntil = now.addingTimeInterval(45); awakeUntil = .distantPast
 }
 mutating func wakeManually(at now: Date) {
  napUntil = .distantPast; awakeUntil = now.addingTimeInterval(20)
 }
 func sleeping(at now: Date, calendar: Calendar = .current) -> Bool {
  if locked { return true }
  if now < awakeUntil { return false }
  return now < napUntil || Self.isNight(now, calendar: calendar)
 }
}
