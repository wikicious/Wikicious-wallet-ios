import Foundation
import RxSwift
import RxRelay
import RxCocoa

class WalletConnectXListViewModel {
    private let service: WalletConnectXListService
    private let disposeBag = DisposeBag()

    private let newConnectionErrorRelay = PublishRelay<String>()
    private let showWalletConnectMainServiceRelay = PublishRelay<IWalletConnectXMainService>()
    private let showWalletConnectV1SessionRelay = PublishRelay<WalletConnectSession>()

    init(service: WalletConnectXListService) {
        self.service = service

        subscribe(disposeBag, service.createModuleObservable) { [weak self] in self?.show(service: $0) }
        subscribe(disposeBag, service.connectionErrorObservable) { [weak self] in self?.show(connectionError: $0) }
    }

    private func show(service: IWalletConnectXMainService) {
        showWalletConnectMainServiceRelay.accept(service)
    }

    private func show(connectionError: Error) {
        newConnectionErrorRelay.accept(connectionError.smartDescription)
    }

}

extension WalletConnectXListViewModel {

    // NewConnection section
    var emptySessionList: Bool {
        service.emptySessionList
    }

    var showWalletConnectMainModuleSignal: Signal<IWalletConnectXMainService> {
        showWalletConnectMainServiceRelay.asSignal()
    }

    var newConnectionErrorSignal: Signal<String> {
        newConnectionErrorRelay.asSignal()
    }

    func didScan(string: String) {
        service.connect(uri: string)
    }

}

extension WalletConnectXListViewModel {

    class ViewItem {
        let id: Int
        let title: String
        let description: String
        let imageUrl: String?

        init(id: Int, title: String, description: String, imageUrl: String?) {
            self.id = id
            self.title = title
            self.description = description
            self.imageUrl = imageUrl
        }

    }

}

extension WalletConnectUriHandler.ConnectionError : LocalizedError {

    var errorDescription: String? {
        switch self {
        case .unsupportedV2: return "UNSUPPORTED V2"
        case .wrongUri: return "WRONG URI"
        }
    }

}
