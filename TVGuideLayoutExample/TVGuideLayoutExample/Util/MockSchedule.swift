import Foundation

struct ProgrammingSchedule {
    let startDate: Date
    let endDate: Date
    let channelSchedules: [ChannelSchedule]
}

struct ChannelSchedule {
    let channel: Channel
    let programmingItems: [ProgrammingItem]
}

struct Channel: Identifiable {
    let id: String
    let codeText: String
    let numberText: String
}

struct ProgrammingItem: Identifiable {
    let id: String
    let startDate: Date
    let endDate: Date
    let title: String
    let description: String
}

func mockSchedule(startTime: Date, endTime: Date, channelCount: Int = 100) async -> ProgrammingSchedule {
    let calendar = Calendar.current
    var channelSchedules = [ChannelSchedule]()
    for _ in 0..<channelCount {
        var currStart: Date = startTime
        var currEnd: Date = currStart
        
        var programmingItems = [ProgrammingItem]()
        
        while currStart < endTime {
            // End time massaging to make data look more organic
            switch Float.random(in: 0...1) {
            case 0...0.5:
                currEnd = calendar.nextDate(
                    after: currStart,
                    matching: DateComponents(minute: 0),
                    matchingPolicy: .nextTime)!
            case 0.5...0.9:
                currEnd = calendar.nextDate(
                    after: currStart,
                    matching: DateComponents(minute: 30),
                    matchingPolicy: .nextTime)!
            default:
                let randomDuration = Int.random(in: 1...12) * 5
                currEnd = calendar.date(byAdding: .minute, value: randomDuration, to: currStart)!
            }
            
            let programmingItem = ProgrammingItem(
                id: UUID().uuidString,
                startDate: currStart,
                endDate: currEnd,
                title: String.randomWords(maxCount: 5),
                description: String.randomWords(maxCount: 50))
            programmingItems.append(programmingItem)
            
            currStart = currEnd
        }
        
        let channel = Channel(
            id: UUID().uuidString,
            codeText: String.randomWord(maxCharCount: 3),
            numberText: String.randomWord(maxCharCount: 3))
        
        let channelSchedule = ChannelSchedule(channel: channel, programmingItems: programmingItems)
        channelSchedules.append(channelSchedule)
    }
    
    let programmingSchedule = ProgrammingSchedule(
        startDate: startTime,
        endDate: endTime,
        channelSchedules: channelSchedules)
    
    return programmingSchedule
}
