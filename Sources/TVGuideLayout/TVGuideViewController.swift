import UIKit

public enum TVGuideViewControllerTrigger {
    case appear
    case hitEnd
}

public protocol TVGuideViewControllerProvidable {
    associatedtype MainSection where MainSection: Hashable & Identifiable & Sendable
    associatedtype MainItem where MainItem: Hashable & Identifiable & Sendable
    associatedtype MainCell: UICollectionViewCell

    associatedtype TimeItem where TimeItem: Hashable & Identifiable & Sendable
    associatedtype TimeCell: UICollectionViewCell
    
    associatedtype ChannelItem where ChannelItem: Hashable & Identifiable & Sendable
    associatedtype ChannelCell: UICollectionViewCell
    
    func configureMain(cell: MainCell, item: MainItem)
    func configureTime(cell: TimeCell, item: TimeItem)
    func configureChannel(cell: ChannelCell, item: ChannelItem)
    func itemWidth(item: MainItem) -> CGFloat
    // From 0 to 1. Tells us where in relation the data the bar should be positioned
    func timeBarXPosition() -> CGFloat
    
    var backgroundColor: UIColor { get }
    var minutesPerInterval: Int { get }
    var pointsPerMinute: CGFloat { get }
    var cellWidthHeight: CGFloat { get }
    
    func loadMoreData(
        loadTrigger: TVGuideViewControllerTrigger,
        mainDataSource: UICollectionViewDiffableDataSource<MainSection, MainItem>,
        leftDataSource: UICollectionViewDiffableDataSource<Int, ChannelItem>,
        topDataSource: UICollectionViewDiffableDataSource<Int, TimeItem>)
}

public class TVGuideViewController<P: TVGuideViewControllerProvidable>: UIViewController, UICollectionViewTVGuideLayoutDelegate
{
    private let provider: P
    
    private var mainCollectionView: UICollectionView!
    private var mainDataSource: UICollectionViewDiffableDataSource<P.MainSection, P.MainItem>!
    
    private var topCollectionView: UICollectionView!
    private var topCollectionViewDelegate: TopCollectionViewHandler!
    private var topDataSource: UICollectionViewDiffableDataSource<Int, P.TimeItem>!
    
    private var leftCollectionView: UICollectionView!
    private var leftCollectionViewDelegate = LeftCollectionViewHandler()
    private var leftDataSource: UICollectionViewDiffableDataSource<Int, P.ChannelItem>!
    
    public var showTimeBar: Bool { true }
    public var timeBarWidth: CGFloat { 2.0 }
    
    public var timeBarPosition: CGFloat {
        provider.timeBarXPosition()
    }
    
    public init(provider: P) {
        self.provider = provider
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        view.backgroundColor = provider.backgroundColor
        
        topCollectionViewDelegate = TopCollectionViewHandler(
            minutesPerInterval: provider.minutesPerInterval,
            pointsPerMinute: provider.pointsPerMinute)
        
        let mainLayout = UICollectionViewScheduleLayout(delegate: self)
        
        mainCollectionView = UICollectionView(frame: .zero, collectionViewLayout: mainLayout)
        mainCollectionView.delegate = self
        mainCollectionView.bounces = false
        mainCollectionView.panGestureRecognizer.cancelsTouchesInView = false
        mainCollectionView.showsHorizontalScrollIndicator = false
        mainCollectionView.showsVerticalScrollIndicator = false
        mainCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainCollectionView)
        
        let topLayout = UICollectionViewScheduleLayout(delegate: topCollectionViewDelegate)
        topCollectionView = UICollectionView(frame: .zero, collectionViewLayout: topLayout)
        topCollectionView.bounces = false
        topCollectionView.isUserInteractionEnabled = false
        topCollectionView.showsHorizontalScrollIndicator = false
        topCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topCollectionView)
        
        let leftLayout = UICollectionViewFlowLayout()
        leftLayout.scrollDirection = .vertical
        leftCollectionView = UICollectionView(frame: .zero, collectionViewLayout: leftLayout)
        leftCollectionView.bounces = false
        leftCollectionView.isUserInteractionEnabled = false
        leftCollectionView.delegate = leftCollectionViewDelegate
        leftCollectionView.showsVerticalScrollIndicator = false
        leftCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leftCollectionView)
                    
        NSLayoutConstraint.activate([
            mainCollectionView.leadingAnchor.constraint(equalTo: leftCollectionView.trailingAnchor),
            mainCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainCollectionView.topAnchor.constraint(equalTo: topCollectionView.bottomAnchor),
            mainCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            topCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            topCollectionView.heightAnchor.constraint(equalToConstant: provider.cellWidthHeight),
            topCollectionView.leadingAnchor.constraint(equalTo: leftCollectionView.trailingAnchor),
            topCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            leftCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: provider.cellWidthHeight),
            leftCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftCollectionView.widthAnchor.constraint(equalToConstant: provider.cellWidthHeight),
            leftCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let mainCellProvider = UICollectionView.CellRegistration<P.MainCell, P.MainItem> { cell, indexPath, item in
            self.provider.configureMain(cell: cell, item: item)
        }
        
        self.mainDataSource = UICollectionViewDiffableDataSource<P.MainSection, P.MainItem>(collectionView: mainCollectionView, cellProvider: { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: mainCellProvider, for: indexPath, item: item)
        })
        
        let topCellProvider = UICollectionView.CellRegistration<P.TimeCell, P.TimeItem> { cell, indexPath, item in
            self.provider.configureTime(cell: cell, item: item)
        }
        
        self.topDataSource = UICollectionViewDiffableDataSource<Int, P.TimeItem>(collectionView: topCollectionView, cellProvider: { collectionView, indexPath, item in
            self.topCollectionView.dequeueConfiguredReusableCell(using: topCellProvider, for: indexPath, item: item)
        })
        
        let leftCellProvider = UICollectionView.CellRegistration<P.ChannelCell, P.ChannelItem> { cell, indexPath, item in
            self.provider.configureChannel(cell: cell, item: item)
        }
        
        self.leftDataSource = UICollectionViewDiffableDataSource<Int, P.ChannelItem>(collectionView: leftCollectionView, cellProvider: { cell, indexPath, item in
            self.leftCollectionView.dequeueConfiguredReusableCell(using: leftCellProvider, for: indexPath, item: item)
        })
        
        provider.loadMoreData(
            loadTrigger: .appear,
            mainDataSource: mainDataSource,
            leftDataSource: leftDataSource,
            topDataSource: topDataSource)
    }
    
    // MARK: - UICollectionViewTVGuideLayoutDelegate (normally in an extension, but can't because of ObjC)
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let item = mainDataSource.itemIdentifier(for: indexPath) else {
            assertionFailure("Could not get item to determine item size in sizeForItemAt:")
            return .zero
        }
        let itemWidth = provider.itemWidth(item: item)
        return CGSize(width: itemWidth, height: provider.cellWidthHeight)
    }
    
    public func offsetDidChange(offset: CGPoint) {
        topCollectionView.setContentOffset(CGPoint(x: offset.x, y: 0), animated: false)
        leftCollectionView.setContentOffset(CGPoint(x: 0, y: offset.y), animated: false)
    }
}

private class LeftCollectionViewHandler: NSObject, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 75.0, height: 75.0)
    }
}

private class TopCollectionViewHandler: NSObject, UICollectionViewTVGuideLayoutDelegate {
    private let minutesPerInterval: Int
    private let pointsPerMinute: CGFloat
    var showTimeBar: Bool { false }
    
    var timeBarPosition: CGFloat { .zero }
    var timeBarWidth: CGFloat { .zero }
    
    init(minutesPerInterval: Int, pointsPerMinute: CGFloat) {
        (self.minutesPerInterval, self.pointsPerMinute) = (minutesPerInterval, pointsPerMinute)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: pointsPerMinute * CGFloat(minutesPerInterval), height: 75.0)
    }
    
    func offsetDidChange(offset: CGPoint) {
        
    }
}
