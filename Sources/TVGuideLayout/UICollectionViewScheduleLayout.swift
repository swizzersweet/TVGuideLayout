import UIKit

public protocol UICollectionViewTVGuideLayoutDelegate: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize
    
    func offsetDidChange(offset: CGPoint)
    var showTimeBar: Bool { get }
    var timeBarPosition: CGFloat { get }
    var timeBarWidth: CGFloat { get }
}

// Requires a non-optional delegate as the it's impossible for this layout to function otherwise
public class UICollectionViewScheduleLayout: UICollectionViewLayout {
    private let ElementKindTimeBarDecoration = "TimeBarDecoration"
    
    private var items = [[UICollectionViewLayoutAttributes]]()
    private var originalFrame = [UICollectionViewLayoutAttributes: CGRect]()
    var contentBounds = CGRect.zero
    var sectionRects = [CGRect]()
    var cachedTimeBarAttributes: UICollectionViewLayoutAttributes!
    
    private var invalidateFromScroll = false
    private var invalidateFromTimerUpdate = false
    private var updateTimeBarTask: Task<(), any Error>?
    
    private weak var delegate: UICollectionViewTVGuideLayoutDelegate!
    
    public init(delegate: UICollectionViewTVGuideLayoutDelegate) {
        super.init()
        self.delegate = delegate
        register(TimeBarDecorationView.self, forDecorationViewOfKind: TimeBarDecorationView.kind)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    deinit {
        updateTimeBarTask?.cancel()
    }
    
    public override func prepare() {
        super.prepare()
        
        if invalidateFromScroll {
            invalidateFromScroll = false
            return
        } else if invalidateFromTimerUpdate {
            invalidateFromTimerUpdate = false
            return
        }
        
        guard let collectionView = collectionView else { return }
        
        collectionView.isDirectionalLockEnabled = true
        
        invalidateLayoutCaches()
        
        guard collectionView.numberOfSections > 0 else { return }
        
        // sections & items
        var yOffset = CGFloat(0)
        for sectionIndex in 0..<collectionView.numberOfSections {
            
            var rowAttributes = [UICollectionViewLayoutAttributes]()
            var xOffset = CGFloat(0)
            for itemIndex in 0..<collectionView.numberOfItems(inSection: sectionIndex) {
                let indexPath = IndexPath(row: itemIndex, section: sectionIndex)
                let cellSize = delegate.collectionView(collectionView, layout: self, sizeForItemAt: indexPath)
                
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: xOffset, y: yOffset, width: cellSize.width, height: cellSize.height)
                originalFrame[attributes] = attributes.frame
                rowAttributes.append(attributes)
                xOffset += cellSize.width
            }
            guard !rowAttributes.isEmpty else { continue }
            
            let sectionHeight = rowAttributes[0].size.height
            let sectionRect = CGRect(x: 0, y: yOffset, width: xOffset, height: sectionHeight)
            contentBounds = contentBounds.union(sectionRect)
            sectionRects.append(sectionRect)
            items.append(rowAttributes)
            
            yOffset += sectionHeight
        }
        
        // time bar
        guard delegate.showTimeBar else { return }
        let timeBarIndexPath = IndexPath(item: 0, section: 0)
        cachedTimeBarAttributes = UICollectionViewLayoutAttributes(forDecorationViewOfKind: TimeBarDecorationView.kind, with: timeBarIndexPath)
        cachedTimeBarAttributes.zIndex = 1
        startUpdateTimeBarTask()
    }
    
    private func startUpdateTimeBarTask() {
        updateTimeBarTask?.cancel()
        updateTimeBarTask = Task {
            while !Task.isCancelled {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                let context = UICollectionViewTVGuideLayoutInvalidationContext()
                context.fromTimerUpdate = true
                invalidateLayout(with: context)
            }
        }
    }
    
    fileprivate func invalidateLayoutCaches() {
        items.removeAll()
        sectionRects.removeAll()
        contentBounds = .zero
        originalFrame.removeAll()
        cachedTimeBarAttributes = nil
    }
    
    public override var collectionViewContentSize: CGSize {
        contentBounds.size
    }
    
    public override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        guard let context = context as? UICollectionViewTVGuideLayoutInvalidationContext else { return }
        if context.fromTimerUpdate {
            self.invalidateFromTimerUpdate = true
        }
        
        super.invalidateLayout(with: context)
    }
    
    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        delegate.offsetDidChange(offset: newBounds.origin)
        /*
         We always return true for 2 reasons:
         1. Seems to be a bug where some regions in layoutAttributesForElements is not called for all fresh regions
         2. We need to do this so our sticky headers can function
         */
        invalidateFromScroll = true
        return true
    }
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Find section indices
        guard let firstSectionIndex = findFirstSectionIndexBinary(query: rect, spaces: sectionRects) else { return nil }
        var attributes = [UICollectionViewLayoutAttributes]()
        var intersectingSectionIndexes = [Int]()
        
        // Sections & items
        for i in (0..<firstSectionIndex).reversed() {
            guard sectionRects[i].intersects(rect) else { break }
            intersectingSectionIndexes.append(i)
        }
        
        intersectingSectionIndexes.append(firstSectionIndex)
        
        for i in (firstSectionIndex+1)..<sectionRects.count {
            guard sectionRects[i].intersects(rect) else { break }
            intersectingSectionIndexes.append(i)
        }
        
        // add items for row (Apply BSP if too slow)
        for sectionIndex in intersectingSectionIndexes.sorted() {
            
            for sectionItem in items[sectionIndex] {
                var firstItemInRow = true
                if sectionItem.frame.intersects(rect) {
                    // Sticky header for first item that is visible
                    if collectionView!.bounds.intersects(sectionItem.frame), firstItemInRow {
                        let scrollX = collectionView!.contentOffset.x
                        let originalFrame = originalFrame[sectionItem]!
                        
                        let subAmount = max(originalFrame.minX, scrollX)
                        
                        sectionItem.frame = CGRect(
                            x: subAmount,
                            y: sectionItem.frame.minY,
                            width: originalFrame.maxX - subAmount,
                            height: sectionItem.frame.height)
                        
                        firstItemInRow = false
                    } else {
                        sectionItem.frame = originalFrame[sectionItem]!
                    }
                    
                    attributes.append(sectionItem)
                } else {
                    sectionItem.frame = originalFrame[sectionItem]!
                }
            }
        }
        
        // Time bar
        if delegate.showTimeBar, collectionView!.bounds.intersects(cachedTimeBarAttributes.frame) {
            let timeBarPositionX = contentBounds.width * delegate.timeBarPosition
            cachedTimeBarAttributes.frame = CGRect(
                x: timeBarPositionX,
                y: 0.0,
                width: delegate.timeBarWidth,
                height: contentBounds.height)
            attributes.append(cachedTimeBarAttributes)
        }
        
        return attributes
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        items[indexPath.section][indexPath.row]
    }
    
    open override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard elementKind == TimeBarDecorationView.kind else { return nil }
        return cachedTimeBarAttributes
    }
    
    open override class var invalidationContextClass: AnyClass {
        return UICollectionViewTVGuideLayoutInvalidationContext.self
    }
    
    private func findFirstSectionIndexBinary(query: CGRect, spaces: [CGRect]) -> Int? {
        guard !spaces.isEmpty else { return nil }
        
        var (l,r) = (0, spaces.count - 1)
        while l <= r {
            let m = l + (r - l) / 2
            let mSpace: CGRect = spaces[m]
            if mSpace.intersects(query) {
                return m
            } else if query.maxY < mSpace.minY {
                r = m - 1
            } else {
                l = m + 1
            }
        }
        
        return nil
    }
}

private class UICollectionViewTVGuideLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {
    var fromTimerUpdate = false
}


private class TimeBarDecorationView : UICollectionReusableView {
    static let kind: String = "TimeBarDecorationView"
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        backgroundColor = UIColor.red
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
