import UIKit
import TVGuideLayout

class ExampleProvider: TVGuideViewControllerProvidable {
    
    init() {
        self.tileBackgroundImage = .createBackgroundTileCellImage()
        self.channelBackgroundImage = .createBackgroundChannelCellImage()
    }
    
    typealias MainSection = MainSectionDetails
    typealias MainItem = MainDetailsItem
    typealias MainCell = TVGuideTileCell
    typealias TimeItem = TimeDetailsItem
    typealias TimeCell = TVGuideTileCell
    typealias ChannelItem = ChannelDetailsItem
    typealias ChannelCell = TVGuideTileCell
    
    var backgroundColor: UIColor = .darkGray
    var pointsPerMinute: CGFloat = 5.0
    var mainCellHeight: CGFloat = 75.0
    var topCellHeight: CGFloat = 75.0
    var leftCellWidth: CGFloat = 75.0
    var minutesPerInterval: Int = 30
    private let tileBackgroundImage: UIImage
    private let channelBackgroundImage: UIImage
    private var startDate: Date?
    private var endDate: Date?
    
    func configureMain(cell: TVGuideTileCell, item: MainDetailsItem) {
        cell.configure(text: item.text)
        cell.backgroundImageView.image = tileBackgroundImage
    }
    
    func configureTime(cell: TVGuideTileCell, item: TimeDetailsItem) {
        cell.configure(text: item.text)
        cell.backgroundImageView.image = tileBackgroundImage
    }
    
    func configureChannel(cell: TVGuideTileCell, item: ChannelDetailsItem) {
        cell.configure(text: item.text)
        cell.backgroundImageView.image = channelBackgroundImage
        cell.label.textAlignment = .center
    }
    
    func itemWidth(item: MainDetailsItem) -> CGFloat {
        CGFloat(item.minutes) * pointsPerMinute
    }
    
    func timeBarXPosition() -> CGFloat {
        guard let startDate, let endDate else { return 0.0 }
        let now = Date().timeIntervalSince1970
        let start = startDate.timeIntervalSince1970
        let end = endDate.timeIntervalSince1970
        
        let pos = (now - start) / (end - start)
        let clampedPos = max(0, min(1, pos))
        
        return CGFloat(clampedPos)
    }
    
    func loadMoreData(
        loadTrigger: TVGuideLayout.TVGuideViewControllerTrigger,
        mainDataSource: UICollectionViewDiffableDataSource<MainSection, MainDetailsItem>,
        leftDataSource: UICollectionViewDiffableDataSource<Int, ChannelDetailsItem>,
        topDataSource: UICollectionViewDiffableDataSource<Int, TimeDetailsItem>) {
            
            self.startDate = Date.previousThirtyMinuteIncrement(from: Date())
            guard let startDate = self.startDate else { return }
            Task {
                self.endDate = Calendar.current.date(byAdding: .day, value: 5, to: startDate)!
                guard let endDate = self.endDate else { return }
                let programmingSchedule: ProgrammingSchedule =
                await mockSchedule(startTime: startDate, endTime: endDate, channelCount: 100)
                
                Task { @MainActor in
                    applyMainSnapshot(from: programmingSchedule, dataSource: mainDataSource)
                    applyTopSnapshot(from: startDate, to: endDate, dataSource: topDataSource)
                    applyLeftSnapshot(from: programmingSchedule, dataSource: leftDataSource)
                }
            }
        }
    
    private func applyMainSnapshot(from programmingSchedule: ProgrammingSchedule,
                                   dataSource: UICollectionViewDiffableDataSource<MainSection, MainItem>) {
        var snapshot = NSDiffableDataSourceSnapshot<MainSection, MainItem>()
        
        for channelSchedule in programmingSchedule.channelSchedules {
            let currentSection = MainSection(id: channelSchedule.channel.numberText, title: channelSchedule.channel.codeText)
            snapshot.appendSections([currentSection])
            var items = [MainItem]()
            for pItem in channelSchedule.programmingItems {
                let pItemMinutes = Calendar.current.dateComponents([.minute], from: pItem.startDate, to: pItem.endDate).minute ?? 0
                items.append(MainItem(id: pItem.title, text: pItem.description, minutes: pItemMinutes))
            }
            snapshot.appendItems(items, toSection: currentSection)
        }
        
        dataSource.apply(snapshot)
    }
    
    private func applyTopSnapshot(
        from: Date,
        to: Date,
        dataSource: UICollectionViewDiffableDataSource<Int, TimeDetailsItem>) {
            let calendar = Calendar.current
            guard let minutes = calendar.dateComponents([.minute], from: from, to: to).minute else { return }
            let intervals = minutes / minutesPerInterval
            
            var snapshot = NSDiffableDataSourceSnapshot<Int, TimeItem>()
            snapshot.appendSections([0])

            var from = from
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mm a"
            
            for _ in 0..<intervals {
                let time = dateFormatter.string(from: from)
                let timeItem = TimeItem(id: UUID().uuidString, text: time)
                snapshot.appendItems([timeItem], toSection: 0)
                
                let minuteComponent = calendar.component(.minute, from: from)
                if minuteComponent < 30 {
                    from = calendar.nextDate(after: from, matching: .init(minute: 30), matchingPolicy: .nextTime)!
                } else {
                    from = calendar.nextDate(after: from, matching: .init(minute: 0), matchingPolicy: .nextTime)!
                }
                
            }
            dataSource.apply(snapshot)
    }
    
    private func applyLeftSnapshot(
        from programmingSchedule: ProgrammingSchedule,
        dataSource: UICollectionViewDiffableDataSource<Int, ChannelItem>) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChannelItem>()
        snapshot.appendSections([0])
        
        for channelSchedule in programmingSchedule.channelSchedules {
            let channelDetailsItem = ChannelDetailsItem(
                id: channelSchedule.channel.codeText,
                text: channelSchedule.channel.numberText)
            snapshot.appendItems([channelDetailsItem], toSection: 0)
        }
        dataSource.apply(snapshot)
    }
}
