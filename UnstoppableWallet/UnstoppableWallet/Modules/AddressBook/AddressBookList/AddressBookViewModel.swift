import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class AddressBookViewModel {
    private let service: AddressBookService
    private let disposeBag = DisposeBag()

    private let notFoundVisibleRelay = BehaviorRelay<Bool>(value: false)

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private var viewItems: [ViewItem] = [] {
        didSet {
            viewItemsRelay.accept(viewItems)
        }
    }

    init(service: AddressBookService) {
        self.service = service

        subscribe(disposeBag, service.contactObservable) { [weak self] in self?.sync(contacts: $0) }
        sync(contacts: service.contacts)
    }

    private func sync(contacts: [Contact]) {
        viewItems = contacts.map { contact in
            ViewItem(
                    uid: contact.uid,
                    title: contact.name,
                    tag: nil,
                    subtitle: "Addresses: " + contact.addresses.count.description,
                    showDisclosure: false
            )
        }
        notFoundVisibleRelay.accept(viewItems.isEmpty)
    }

}

extension AddressBookViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var notFoundVisibleDriver: Driver<Bool> {
        notFoundVisibleRelay.asDriver()
    }

}

extension AddressBookViewModel {

    struct ViewItem {
        let uid: String
        let title: String
        let tag: String?
        let subtitle: String
        let showDisclosure: Bool
    }

}