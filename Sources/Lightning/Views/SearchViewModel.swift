import Foundation
import Combine
import AppKit

/// View model for the search interface.
///
/// Manages the search query, results, selection state, and keyboard navigation.
/// Bridges user input to the search engine and back to the UI.
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [AppEntry] = []
    @Published var selectedIndex: Int = 0

    private var searchEngine = SearchEngine()
    private var appIndex: AppIndex?
    private var iconCache: IconCache?
    private var frecencyTracker: FrecencyTracker?
    private var adaptiveLearning: AdaptiveLearning?
    private var cancellables = Set<AnyCancellable>()

    /// Callback for when the panel height should change.
    var onHeightChange: ((CGFloat) -> Void)?

    /// Callback for when the panel should hide (after launch).
    var onDismiss: (() -> Void)?

    init() {
        $query
            .debounce(for: .milliseconds(10), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query)
            }
            .store(in: &cancellables)
    }

    /// Connects the view model to the app index, icon cache, and ranking components.
    func configure(
        appIndex: AppIndex,
        iconCache: IconCache,
        frecencyTracker: FrecencyTracker? = nil,
        adaptiveLearning: AdaptiveLearning? = nil
    ) {
        self.appIndex = appIndex
        self.iconCache = iconCache
        self.frecencyTracker = frecencyTracker
        self.adaptiveLearning = adaptiveLearning

        searchEngine.maxResults = UserPreferences.shared.maxResults

        if let frecencyTracker, let adaptiveLearning {
            searchEngine.scoreCalculator = ScoreCalculator(
                frecencyTracker: frecencyTracker,
                adaptiveLearning: adaptiveLearning
            )
        }
    }

    /// Resets query and prepares for new search session.
    func activate() {
        query = ""
        results = []
        selectedIndex = 0
        updateHeight()
    }

    /// Cleans up when the panel hides.
    func deactivate() {
        query = ""
        results = []
        selectedIndex = 0
    }

    /// Moves selection up.
    func moveUp() {
        guard !results.isEmpty else { return }
        selectedIndex = max(0, selectedIndex - 1)
    }

    /// Moves selection down.
    func moveDown() {
        guard !results.isEmpty else { return }
        selectedIndex = min(results.count - 1, selectedIndex + 1)
    }

    /// Launches the currently selected app.
    func launchSelected() {
        guard !results.isEmpty, selectedIndex < results.count else { return }
        let entry = results[selectedIndex]
        recordSelection(entry)
        AppLauncher.launch(entry)
        onDismiss?()
    }

    /// Launches a specific app entry (from click).
    func launch(_ entry: AppEntry) {
        recordSelection(entry)
        AppLauncher.launch(entry)
        onDismiss?()
    }

    // MARK: - Private

    private func recordSelection(_ entry: AppEntry) {
        appIndex?.recordLaunch(forBundleId: entry.id)
        frecencyTracker?.recordLaunch(bundleId: entry.id)
        if !query.isEmpty {
            adaptiveLearning?.recordSelection(bundleId: entry.id, query: query)
        }
    }

    private func performSearch(_ query: String) {
        guard let appIndex else { return }

        if query.isEmpty {
            results = []
            selectedIndex = 0
            updateHeight()
            return
        }

        let matched = searchEngine.search(query: query, in: appIndex.allEntries)

        // Load icons for results
        if let iconCache {
            Task {
                var withIcons = matched
                for i in withIcons.indices {
                    if withIcons[i].icon == nil {
                        let icon = await iconCache.icon(for: withIcons[i])
                        withIcons[i].icon = icon
                    }
                }
                let final_ = withIcons
                await MainActor.run {
                    self.results = final_
                    self.selectedIndex = 0
                    self.updateHeight()
                }
            }
        } else {
            results = matched
            selectedIndex = 0
            updateHeight()
        }
    }

    private func updateHeight() {
        let rowHeight: CGFloat = 44
        let searchHeight = PanelController.searchFieldHeight
        let resultsHeight = CGFloat(results.count) * rowHeight
        let totalHeight = searchHeight + resultsHeight
        onHeightChange?(totalHeight)
    }
}
