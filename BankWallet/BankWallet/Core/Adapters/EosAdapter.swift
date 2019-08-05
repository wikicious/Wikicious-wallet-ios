import EosKit
import RxSwift

class EosAdapter {
    private let irreversibleThreshold = 330

    private let eosKit: EosKit
    private let addressParser: IAddressParser
    private let asset: Asset

    let wallet: Wallet
    let decimal: Int = 4

    init(wallet: Wallet, eosKit: EosKit, addressParser: IAddressParser, token: String, symbol: String) {
        self.wallet = wallet
        self.eosKit = eosKit
        self.addressParser = addressParser

        asset = eosKit.register(token: token, symbol: symbol)
    }

    private func transactionRecord(fromTransaction transaction: Transaction) -> TransactionRecord {
        let from = TransactionAddress(
                address: transaction.from,
                mine: transaction.from == eosKit.account
        )

        let to = TransactionAddress(
                address: transaction.to,
                mine: transaction.to == eosKit.account
        )

        return TransactionRecord(
                transactionHash: transaction.id,
                transactionIndex: 0,
                interTransactionIndex: transaction.actionSequence,
                blockHeight: transaction.blockNumber,
                amount: transaction.quantity.amount * (from.mine ? -1 : 1),
                date: transaction.date,
                from: [from],
                to: [to]
        )
    }

    static func validate(account: String) throws {
        //regex taken from here: https://github.com/EOSIO/eos/issues/955#issuecomment-351866599
        let regex = try! NSRegularExpression(pattern: "^[a-z][a-z1-5\\.]{0,10}([a-z1-5]|^\\.)[a-j1-5]?$")
        guard regex.firstMatch(in: account, range: NSRange(location: 0, length: account.count)) != nil else {
            throw ValidationError.invalidAccount
        }
    }

    static func validate(privateKey: String) throws {
        try EosKit.validate(privateKey: privateKey)
    }

}

extension EosAdapter: IAdapter {

    var confirmationsThreshold: Int {
        return irreversibleThreshold
    }

    var refreshable: Bool {
        return true
    }

    func start() {
        // started via EosKitManager
    }

    func stop() {
        // stopped via EosKitManager
    }

    func refresh() {
        // refreshed via EosKitManager
    }

    var lastBlockHeight: Int? {
        return eosKit.irreversibleBlockHeight.map { $0 + irreversibleThreshold }
    }

    var lastBlockHeightUpdatedObservable: Observable<Void> {
        return eosKit.irreversibleBlockHeightObservable.map { _ in () }
    }

    var state: AdapterState {
        switch asset.syncState {
        case .synced: return .synced
        case .notSynced: return .notSynced
        case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }

    var stateUpdatedObservable: Observable<Void> {
        return asset.syncStateObservable.map { _ in () }
    }

    var balance: Decimal {
        return asset.balance
    }

    var balanceUpdatedObservable: Observable<Void> {
        return asset.balanceObservable.map { _ in () }
    }

    var transactionRecordsObservable: Observable<[TransactionRecord]> {
        return asset.transactionsObservable.map { [weak self] in
            $0.compactMap { self?.transactionRecord(fromTransaction: $0) }
        }
    }

    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]> {
        return eosKit.transactionsSingle(asset: asset, fromActionSequence: from?.interTransactionIndex, limit: limit)
                .map { [weak self] transactions -> [TransactionRecord] in
                    return transactions.compactMap { self?.transactionRecord(fromTransaction: $0) }
                }
    }

    func sendSingle(params: [String : Any]) -> Single<Void> {
        guard let amount: Decimal = params[AdapterField.amount.rawValue] as? Decimal,
              let address: String = params[AdapterField.address.rawValue] as? String else {
            return Single.error(AdapterError.wrongParameters)
        }

        let memo = params[AdapterField.memo.rawValue] as? String
        return eosKit.sendSingle(asset: asset, to: address, amount: amount, memo: memo ?? "from Unstoppable Wallet")
                .map { _ in () }
    }

    func availableBalance(params: [String : Any]) -> Decimal {
        return asset.balance
    }

    func feeRate(priority: FeeRatePriority) -> Int {
        return 0
    }

    func fee(params: [String : Any]) -> Decimal {
        return 0
    }

    func validate(address: String) throws {
        try EosAdapter.validate(account: address)
    }

    func validate(params: [String : Any]) throws -> [SendStateError] {
        guard let amount: Decimal = params[AdapterField.amount.rawValue] as? Decimal else {
            throw AdapterError.wrongParameters
        }

        var errors = [SendStateError]()

        let balance = asset.balance
        if amount > balance {
            errors.append(.insufficientAmount(availableBalance: balance))
        }

        return errors
    }

    func parse(paymentAddress: String) -> PaymentRequestAddress {
        let paymentData = addressParser.parse(paymentAddress: paymentAddress)
        var validationError: Error?
        do {
            try validate(address: paymentData.address)
        } catch {
            validationError = error
        }
        return PaymentRequestAddress(address: paymentData.address, amount: paymentData.amount.map { Decimal($0) }, error: validationError)
    }

    var receiveAddress: String {
        return eosKit.account
    }

    var debugInfo: String {
        return ""
    }

}

extension EosAdapter {
    enum ValidationError: Error {
        case invalidAccount
    }
}