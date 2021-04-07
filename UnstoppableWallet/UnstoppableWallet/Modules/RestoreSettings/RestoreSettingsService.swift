import RxSwift
import RxRelay
import CoinKit

class RestoreSettingsService {
    private let manager: RestoreSettingsManager

    private let approveSettingsRelay = PublishRelay<CoinWithSettings>()
    private let rejectApproveSettingsRelay = PublishRelay<Coin>()

    private let requestRelay = PublishRelay<Request>()

    init(manager: RestoreSettingsManager) {
        self.manager = manager
    }

}

extension RestoreSettingsService {

    var approveSettingsObservable: Observable<CoinWithSettings> {
        approveSettingsRelay.asObservable()
    }

    var rejectApproveSettingsObservable: Observable<Coin> {
        rejectApproveSettingsRelay.asObservable()
    }

    var requestObservable: Observable<Request> {
        requestRelay.asObservable()
    }

    func approveSettings(coin: Coin, account: Account? = nil) {
        if let account = account, case .created = account.origin {
            approveSettingsRelay.accept(CoinWithSettings(coin: coin, settings: [:]))
            return
        }

        let existingSettings = account.map { manager.settings(account: $0, coin: coin) } ?? [:]

        if coin.type.restoreSettingTypes.contains(.birthdayHeight) && existingSettings[.birthdayHeight] == nil {
            let request = Request(
                    coin: coin,
                    type: .birthdayHeight
            )

            requestRelay.accept(request)
            return
        }

        approveSettingsRelay.accept(CoinWithSettings(coin: coin, settings: [:]))
    }

    func save(settings: RestoreSettings, account: Account, coin: Coin) {
        manager.save(settings: settings, account: account, coin: coin)
    }

    func enter(birthdayHeight: String?, coin: Coin) {
        var settings = RestoreSettings()
        settings[.birthdayHeight] = birthdayHeight

        let coinWithSettings = CoinWithSettings(coin: coin, settings: settings)
        approveSettingsRelay.accept(coinWithSettings)
    }

    func cancel(coin: Coin) {
        rejectApproveSettingsRelay.accept(coin)
    }

}

extension RestoreSettingsService {

    struct CoinWithSettings {
        let coin: Coin
        let settings: RestoreSettings
    }

    struct Request {
        let coin: Coin
        let type: RequestType
    }

    enum RequestType {
        case birthdayHeight
    }

}