import UIKit

/// Persists catch/spot photos as JPEG files in the app's Documents directory.
enum FishPhotoStore {
    private static var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("FishingPhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    @discardableResult
    static func save(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let fileName = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return fileName
        } catch {
            return nil
        }
    }

    static func load(_ fileName: String) -> UIImage? {
        let url = directory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(_ fileName: String) {
        let url = directory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}
