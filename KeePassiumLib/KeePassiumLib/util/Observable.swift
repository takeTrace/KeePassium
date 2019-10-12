//
//  Observable.swift
//  KeePassiumLib
//
//  Created by Andrei Popleteev on 2019-10-12.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

public protocol Observer: class {
    // left empty
}

public struct Subscriber {
    weak var observer: Observer?
}

public protocol Observable: class {
    var subscribers: [ObjectIdentifier: Subscriber] { get set }
}

public extension Observable {
    func addObserver(_ observer: Observer) {
        objc_sync_enter(subscribers)
        defer { objc_sync_exit(subscribers) }

        let id = ObjectIdentifier(observer)
        subscribers[id] = Subscriber(observer: observer)
    }

    func removeObserver(_ observer: Observer) {
        objc_sync_enter(subscribers)
        defer { objc_sync_exit(subscribers) }
        
        let id = ObjectIdentifier(observer)
        subscribers.removeValue(forKey: id)
    }

//    private func notifyObservers(didAddFile fileRef: URLReference, fileType: FileType) {
//        // observers might add/remove other observers,
//        // so we work with a copy to avoid deadlocks.
//        objc_sync_enter(observers)
//        let observersCopy = observers
//        objc_sync_exit(observers)
//
//        for (id, observer) in observersCopy {
//            guard let obs = observer.observer else {
//                // the observer is gone, remove it
//                observers.removeValue(forKey: id)
//                continue
//            }
//            DispatchQueue.main.async {
//                obs.fileKeeper(didAddFile: fileRef, fileType: fileType)
//            }
//        }
//    }
}
