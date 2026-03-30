import Foundation
import Combine

class FSEventWatcher: ObservableObject {
    private var sources: [DispatchSourceFileSystemObject] = []
    private var fileDescriptors: [Int32] = []
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.5

    func watch(paths: [URL], onChange: @escaping (URL) -> Void) {
        stopAll()

        for url in paths {
            let fd = open(url.path, O_EVTONLY)
            guard fd >= 0 else { continue }

            fileDescriptors.append(fd)

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: .write,
                queue: .main
            )

            source.setEventHandler { [weak self] in
                self?.debounceWorkItem?.cancel()
                let workItem = DispatchWorkItem {
                    onChange(url)
                }
                self?.debounceWorkItem = workItem
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + (self?.debounceInterval ?? 0.5),
                    execute: workItem
                )
            }

            source.setCancelHandler {
                close(fd)
            }

            source.resume()
            sources.append(source)
        }
    }

    func stopAll() {
        debounceWorkItem?.cancel()
        for source in sources {
            source.cancel()
        }
        sources.removeAll()
        fileDescriptors.removeAll()
    }

    deinit {
        stopAll()
    }
}
