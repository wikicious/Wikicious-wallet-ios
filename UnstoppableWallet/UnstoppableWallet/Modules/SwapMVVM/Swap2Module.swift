import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import EthereumKit
import ThemeKit


//TODO: move to another place
func subscribe<T>(_ disposeBag: DisposeBag, _ driver: Driver<T>, _ onNext: ((T) -> Void)? = nil) {
    driver.drive(onNext: onNext).disposed(by: disposeBag)
}

func subscribe<T>(_ disposeBag: DisposeBag, _ observable: Observable<T>, _ onNext: ((T) -> Void)? = nil) {
    observable.subscribe(onNext: onNext).disposed(by: disposeBag)
}

struct Swap2Module {

    enum PriceImpactLevel: Int {
    case none
    case normal
    case warning
    case forbidden
    }

    struct TradeItem {
        let coinIn: Coin
        let coinOut: Coin
        let type: TradeType
        let executionPrice: Decimal?
        let priceImpact: Decimal?
        let minMaxAmount: Decimal?
    }

    struct TradeViewItem {
        let executionPrice: String?
        let priceImpact: String?
        let priceImpactLevel: PriceImpactLevel
        let minMaxTitle: String?
        let minMaxAmount: String?
    }

    struct AllowanceItem {
        let amount: CoinValue
        let isSufficient: Bool
    }

    struct AllowanceViewItem {
        let amount: String?
        let isSufficient: Bool
    }

    struct ApproveData {
        let coin: Coin
        let spenderAddress: Address
        let amount: Decimal
    }

    struct ProceedData {
    }

    enum SwapState {
        case idle
        case approveRequired
        case waitingForApprove
        case allowed
    }

    static func instance(wallet: Wallet) -> UIViewController? {
        guard let ethereumKit = try? App.shared.ethereumKitManager.ethereumKit(account: wallet.account) else {
            return nil
        }
        let swapKit = UniswapKit.Kit.instance(ethereumKit: ethereumKit)
        let allowanceRepository = AllowanceRepository(walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager)
        let swapCoinProvider = SwapCoinProvider(coinManager: App.shared.coinManager, walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager)

        let service = Swap2Service(uniswapRepository: UniswapRepository(swapKit: swapKit), allowanceRepository: allowanceRepository, swapCoinProvider: swapCoinProvider, adapterManager: App.shared.adapterManager, coin: wallet.coin)
        let viewModel = Swap2ViewModel(service: service, decimalParser: SendAmountDecimalParser())

        return ThemeNavigationController(rootViewController: Swap2ViewController(viewModel: viewModel))
    }

}

enum SwapValidationError: Error, LocalizedError {
    case insufficientBalance(availableBalance: CoinValue?)
    case insufficientAllowance

    var errorDescription: String? {
        switch self {
        case .insufficientBalance(let availableBalance):
            if let availableBalance = availableBalance {
                return "swap.amount_error.maximum_amount".localized(ValueFormatter.instance.format(coinValue: availableBalance) ?? "")
            }
            return "swap.amount_error.no_balance".localized
        case .insufficientAllowance:
            return "swap.allowance_error.insufficient_allowance".localized
        }
    }

}

extension UniswapKit.Kit.TradeError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .tradeNotFound: return "swap.trade_error.not_found".localized
        default: return nil
        }
    }

}
