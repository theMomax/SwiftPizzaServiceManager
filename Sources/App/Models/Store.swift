import FluentMySQL
import Vapor

final class DBStore: MySQLModel {
    
    var id: Int?
    
    init(id: Int? = nil) {
        self.id = id
    }
    
}

extension DBStore {
    
    var items: Children<DBStore, DBResource> {
        return children(\.storeID)
    }
    
    static var semaphore = DispatchSemaphore.init(value: 1)
    
    func remove(_ items: [DBResource], on con: DatabaseConnectable) throws -> EventLoopFuture<Void> {
        let signal = con.eventLoop.newPromise(Void.self)
        
        DispatchQueue.global().async {
            
            do {
                
                var changed: [DBResource] = []
                
                DBStore.semaphore.wait()
                defer {
                    DBStore.semaphore.signal()
                }
                
                for r in items {
                    
                    let available: [DBResource] = try self.items.query(on: con).filter(\.name == r.name).all().wait()
                    
                    var i = 0
                    
                    while i < available.count && r.amount > 0 {
                        let m = min(available[i].amount, r.amount)
                        available[i].amount -= m
                        r.amount -= m
                        changed.append(available[i])
                        i += 1
                    }
                    
                    if r.amount > 0 {
                        throw StoreError.outOf(item: r.name)
                    }
                }
                
                for i in 0..<changed.count {
                    _ = changed[i].save(on: con)
                    if changed[i].amount <= 0 {
                        _ = changed[i].delete(on: con)
                    }
                }
                signal.succeed()
            } catch {
                signal.fail(error: error)
            }
        }
        
        
        return signal.futureResult
    }
    
    
    /*
     func (s *Store) Remove(items ...*Resource) error {
        changed := make([]*Resource, 0)
        sM.Lock()
        defer sM.Unlock()
        for _, r := range items {
            var available []*Resource
            DB.Model(S).Where("name = ?", r.Name).Related(&available)
            i := 0
            for i < len(available) && r.Amount > 0 {
                min := math.Min(available[i].Amount, r.Amount)
                available[i].Amount -= min
                r.Amount -= min
                changed = append(changed, available[i])
                i++
            }
            if r.Amount > 0 {
                return errors.New("not enough " + r.Name + " available")
            }
        }
        for i := range changed {
            DB.Save(changed[i])
            if changed[i].Amount <= 0 {
                DB.Delete(changed[i])
            }
        }
     
        return nil
     }
    */
}

extension DBStore: Migration { }
