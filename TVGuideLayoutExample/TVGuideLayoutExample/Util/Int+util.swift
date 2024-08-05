//
//  Int+util.swift
//  TVGuideLayoutExample
//
//  Created by Jonathan Menard on 2024-08-11.
//

import Foundation

extension Date {
    static func previousThirtyMinuteIncrement(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        guard let minute = components.minute else { return date }
        
        let previousIncrement: Int
        if minute < 30 {
            previousIncrement = 0
        } else {
            previousIncrement = 30
        }
        
        var newComponents = DateComponents()
        newComponents.year = components.year
        newComponents.month = components.month
        newComponents.day = components.day
        newComponents.hour = components.hour
        newComponents.minute = previousIncrement
        
        return calendar.date(from: newComponents) ?? date
    }
}

extension Int {
    func roundedToNearest(multiple: Int) -> Int {
        Int(round(Float(self) / Float(multiple))) * multiple
    }
}
