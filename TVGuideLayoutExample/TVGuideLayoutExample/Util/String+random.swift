import Foundation

extension String {
    static func randomWords(maxCount: Int = 5) -> String {
        var words = [String]()
        for _ in 0...maxCount {
            words.append(randomWord())
        }
        return words.joined(separator: " ")
    }
    
    private static var alphaChars: [Character] = {
        var result = [Character]()
        for asciiValue in Character("a").asciiValue!...Character("z").asciiValue! {
            result.append(Character(Unicode.Scalar(asciiValue)))
        }
        return result
    }()
    
    static func randomWord(maxCharCount: Int = 5) -> String {
        var chars = [Character]()
        for _ in 1...maxCharCount {
            chars.append(alphaChars.randomElement()!)
        }
        return String(chars)
    }
}
