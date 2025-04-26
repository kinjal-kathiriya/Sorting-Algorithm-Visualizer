//
//  ViewController.swift
//  SortingVisualizer
//
//  Created by kinjal kathiriya on 4/8/25.
//
import UIKit
class ViewController: UIViewController {
    
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var sampleSizeLabel: UILabel!
    @IBOutlet weak var sampleSizeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var algorithmSegmentedControl1: UISegmentedControl!
    @IBOutlet weak var algorithmSegmentedControl2: UISegmentedControl!
    @IBOutlet weak var sortingView1: UIView!
    @IBOutlet weak var sortingView2: UIView!
    
    private let algorithms = ["Insertion", "Selection", "Quick", "Merge"]
    private let sampleSizes = [16, 32, 48, 64]
    private let sortingQueue = DispatchQueue(label: "sorting.queue", qos: .userInitiated, attributes: .concurrent)
    private var isSorting = false
    private var currentStep = 0
    private var stepTimer: Timer?
    private var animationSpeed: TimeInterval = 0.1
    private var runCount = 0
    private let maxRuns = 3 // Number of times to run the algorithms
    
    private class SortState {
        var data: [Int]
        var highlightedIndices: Set<Int> = []
        var description: String = ""
        
        init(data: [Int]) {
            self.data = data
        }
        
        func copy() -> SortState {
            let copy = SortState(data: self.data)
            copy.highlightedIndices = self.highlightedIndices
            copy.description = self.description
            return copy
        }
    }
    
    private var state1: SortState!
    private var state2: SortState!
    private var stepStates: [(state1: SortState, state2: SortState)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        resetDataSets()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        drawBars()
    }
    
    private func setupUI() {
        configureSegmentedControls()
        styleViews()
    }
    
    private func configureSegmentedControls() {
        // Sample size control
        sampleSizeSegmentedControl.removeAllSegments()
        for (index, size) in sampleSizes.enumerated() {
            sampleSizeSegmentedControl.insertSegment(withTitle: "\(size)", at: index, animated: false)
        }
        sampleSizeSegmentedControl.selectedSegmentIndex = 0
        
        // Algorithm controls
        algorithmSegmentedControl1.removeAllSegments()
        algorithmSegmentedControl2.removeAllSegments()
        for (index, algorithm) in algorithms.enumerated() {
            algorithmSegmentedControl1.insertSegment(withTitle: algorithm, at: index, animated: false)
            algorithmSegmentedControl2.insertSegment(withTitle: algorithm, at: index, animated: false)
        }
        algorithmSegmentedControl1.selectedSegmentIndex = 0
        algorithmSegmentedControl2.selectedSegmentIndex = 1
    }
    
    private func styleViews() {
        sortButton.layer.cornerRadius = 8
        sortingView1.layer.cornerRadius = 8
        sortingView2.layer.cornerRadius = 8
        sortingView1.layer.borderWidth = 0
        sortingView2.layer.borderWidth = 0
    }
    
    private func resetDataSets() {
        stopStepTimer()
        
        let size = sampleSizes[sampleSizeSegmentedControl.selectedSegmentIndex]
        state1 = SortState(data: (1...size).map { $0 }.shuffled())
        state2 = SortState(data: (1...size).map { $0 }.shuffled())
        sampleSizeLabel.text = "N = \(size)"
        
        stepStates = []
        currentStep = 0
        
        DispatchQueue.main.async {
            self.drawBars()
        }
    }
    
    private func drawBars() {
        guard sortingView1.bounds.width > 0, sortingView2.bounds.width > 0 else { return }
        
        drawBars(in: sortingView1, data: state1.data, highlights: state1.highlightedIndices)
        drawBars(in: sortingView2, data: state2.data, highlights: state2.highlightedIndices)
    }
    
    private func drawBars(in view: UIView, data: [Int], highlights: Set<Int>) {
        view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let barWidth = view.bounds.width / CGFloat(data.count)
        let maxValue = CGFloat(data.max() ?? 1)
        
        for (i, value) in data.enumerated() {
            let barHeight = view.bounds.height * CGFloat(value) / maxValue
            let barLayer = CALayer()
            barLayer.frame = CGRect(
                x: CGFloat(i) * barWidth,
                y: view.bounds.height - barHeight,
                width: barWidth,
                height: barHeight
            )
            barLayer.backgroundColor = highlights.contains(i) ? UIColor.systemRed.cgColor : UIColor.systemBlue.cgColor
            barLayer.cornerRadius = 2
            view.layer.addSublayer(barLayer)
        }
    }
    
    @IBAction func sortButtonTapped(_ sender: UIButton) {
        if isSorting {
            // If already sorting, just reset and enable controls
            isSorting = false
            setControlsEnabled(true)
            resetDataSets()
            sortButton.setTitle("Sort", for: .normal)
        } else {
            // Start a new sort
            isSorting = true
            setControlsEnabled(false)
            resetDataSets()
            runCount = 0
            sortButton.setTitle("Sort", for: .normal)
            startSingleRun()
        }
    }
    
    private func startSingleRun() {
        guard isSorting else { return }
        
        runCount += 1
        print("Starting run \(runCount)")
        
        let algorithm1 = algorithmSegmentedControl1.selectedSegmentIndex
        let algorithm2 = algorithmSegmentedControl2.selectedSegmentIndex
        
        // Create independent copies for each algorithm
        let state1Copy = state1.copy()
        let state2Copy = state2.copy()
        
        // Record initial state
        recordStep(state1: state1Copy.copy(), state2: state2Copy.copy(),
                  desc1: "Initial State", desc2: "Initial State")
        
        let dispatchGroup = DispatchGroup()
        
        // Start first algorithm
        dispatchGroup.enter()
        sortingQueue.async {
            switch algorithm1 {
            case 0:
                self.insertionSort(state: state1Copy) {
                    self.recordStep(state1: state1Copy.copy(),
                                  state2: state2Copy.copy(),
                                  desc1: "Insertion Sort",
                                  desc2: "Waiting")
                }
            case 1:
                self.selectionSort(state: state1Copy) {
                    self.recordStep(state1: state1Copy.copy(),
                                  state2: state2Copy.copy(),
                                  desc1: "Selection Sort",
                                  desc2: "Waiting")
                }
            case 2:
                self.quickSort(state: state1Copy) {
                    self.recordStep(state1: state1Copy.copy(),
                                  state2: state2Copy.copy(),
                                  desc1: "Quick Sort",
                                  desc2: "Waiting")
                }
            case 3:
                self.mergeSort(state: state1Copy) {
                    self.recordStep(state1: state1Copy.copy(),
                                  state2: state2Copy.copy(),
                                  desc1: "Merge Sort",
                                  desc2: "Waiting")
                }
            default: break
            }
            dispatchGroup.leave()
        }
        
        // Start second algorithm
        dispatchGroup.enter()
        sortingQueue.async {
            switch algorithm2 {
            case 0:
                self.insertionSort(state: state2Copy) {
                    self.recordStep(state1: state1Copy.copy(),
                                  state2: state2Copy.copy(),
                                  desc1: "Waiting",
                                  desc2: "Insertion Sort")
                }
            case 1:
                self.selectionSort(state: state2Copy) {
                    self.recordStep(state1: state1Copy.copy(),
                                  state2: state2Copy.copy(),
                                  desc1: "Waiting",
                                  desc2: "Selection Sort")
                }
            case 2:
                self.quickSort(state: state2Copy) {
                    self.recordStep(state1: state1Copy.copy(),
                                  state2: state2Copy.copy(),
                                  desc1: "Waiting",
                                  desc2: "Quick Sort")
                }
            case 3:
                self.mergeSort(state: state2Copy) {
                    self.recordStep(state1: state1Copy.copy(),
                                  state2: state2Copy.copy(),
                                  desc1: "Waiting",
                                  desc2: "Merge Sort")
                }
            default: break
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            // Record final state
            self.recordStep(state1: state1Copy.copy(),
                          state2: state2Copy.copy(),
                          desc1: "Complete",
                          desc2: "Complete")
            
            // Start animation
            self.startStepTimer()
            
            // Enable controls after visualization completed
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(self.stepStates.count) * self.animationSpeed + 0.5) {
                self.isSorting = false
                self.setControlsEnabled(true)
                self.sortButton.setTitle("Sort", for: .normal)
            }
        }
    }
    
    private func recordStep(state1: SortState, state2: SortState,
                          desc1: String, desc2: String) {
        let state1Copy = state1.copy()
        state1Copy.description = desc1
        
        let state2Copy = state2.copy()
        state2Copy.description = desc2
        
        DispatchQueue.main.async {
            self.stepStates.append((state1Copy, state2Copy))
        }
    }
    
    private func startStepTimer() {
        stopStepTimer()
        currentStep = 0
        
        stepTimer = Timer.scheduledTimer(withTimeInterval: animationSpeed, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.currentStep < self.stepStates.count {
                let step = self.stepStates[self.currentStep]
                self.state1 = step.state1
                self.state2 = step.state2
                self.drawBars()
                self.currentStep += 1
            } else {
                self.stopStepTimer()
            }
        }
    }
    
    private func stopStepTimer() {
        stepTimer?.invalidate()
        stepTimer = nil
    }
    
    private func insertionSort(state: SortState, processStep: () -> Void) {
        for i in 1..<state.data.count {
            var j = i
            while j > 0 {
                state.highlightedIndices = [j, j-1]
                processStep()
                
                if state.data[j] < state.data[j-1] {
                    state.data.swapAt(j, j-1)
                    j -= 1
                    
                    state.highlightedIndices = [j, j+1]
                    processStep()
                } else {
                    break
                }
            }
        }
    }
    
    private func selectionSort(state: SortState, processStep: () -> Void) {
        for i in 0..<state.data.count {
            var minIndex = i
            
            for j in i+1..<state.data.count {
                state.highlightedIndices = [minIndex, j]
                processStep()
                
                if state.data[j] < state.data[minIndex] {
                    minIndex = j
                }
            }
            
            if i != minIndex {
                state.highlightedIndices = [i, minIndex]
                processStep()
                
                state.data.swapAt(i, minIndex)
                
                state.highlightedIndices = [i, minIndex]
                processStep()
            }
        }
    }
    
    private func quickSort(state: SortState, processStep: () -> Void) {
        func quickSort(low: Int, high: Int) {
            if low < high {
                let p = partition(low: low, high: high)
                quickSort(low: low, high: p-1)
                quickSort(low: p+1, high: high)
            }
        }
        
        func partition(low: Int, high: Int) -> Int {
            let pivot = state.data[high]
            var i = low
            
            for j in low..<high {
                state.highlightedIndices = [j, high, i]
                processStep()
                
                if state.data[j] < pivot {
                    if i != j {
                        state.data.swapAt(i, j)
                        state.highlightedIndices = [i, j]
                        processStep()
                    }
                    i += 1
                }
            }
            
            if i != high {
                state.data.swapAt(i, high)
                state.highlightedIndices = [i, high]
                processStep()
            }
            
            return i
        }
        
        quickSort(low: 0, high: state.data.count-1)
    }
    
    private func mergeSort(state: SortState, processStep: () -> Void) {
        func mergeSort(low: Int, high: Int) {
            if low < high {
                let mid = (low + high) / 2
                mergeSort(low: low, high: mid)
                mergeSort(low: mid+1, high: high)
                merge(low: low, mid: mid, high: high)
            }
        }
        
        func merge(low: Int, mid: Int, high: Int) {
            var temp = [Int]()
            var left = low
            var right = mid + 1
            
            state.highlightedIndices = Set((low...high).map { $0 })
            processStep()
            
            while left <= mid && right <= high {
                state.highlightedIndices = [left, right]
                processStep()
                
                if state.data[left] <= state.data[right] {
                    temp.append(state.data[left])
                    left += 1
                } else {
                    temp.append(state.data[right])
                    right += 1
                }
            }
            
            while left <= mid {
                temp.append(state.data[left])
                left += 1
            }
            
            while right <= high {
                temp.append(state.data[right])
                right += 1
            }
            
            for i in low...high {
                state.data[i] = temp[i - low]
                state.highlightedIndices = [i]
                processStep()
            }
        }
        
        mergeSort(low: 0, high: state.data.count-1)
    }
    
    // Original IBAction methods
    @IBAction private func sampleSizeChanged(_ sender: UISegmentedControl) {
        resetDataSets()
    }
    
    @IBAction private func algorithmSegmentedControl1Changed(_ sender: UISegmentedControl) {
        resetDataSets()
    }
    
    @IBAction private func algorithmSegmentedControl2Changed(_ sender: UISegmentedControl) {
        resetDataSets()
    }
    
    // Compatibility methods to match ALL possible Interface Builder connections
    @IBAction func algorithm1Changed(_ sender: UISegmentedControl) {
        // Forward to our actual implementation
        algorithmSegmentedControl1Changed(sender)
    }
    
    @IBAction func algorithm2Changed(_ sender: UISegmentedControl) {
        // Forward to our actual implementation
        algorithmSegmentedControl2Changed(sender)
    }
    
    @IBAction func algorithmChanged(_ sender: UISegmentedControl) {
        // Figure out which control was triggered and forward accordingly
        if sender == algorithmSegmentedControl1 {
            algorithmSegmentedControl1Changed(sender)
        } else if sender == algorithmSegmentedControl2 {
            algorithmSegmentedControl2Changed(sender)
        }
    }
    
    @IBAction func sizeChanged(_ sender: UISegmentedControl) {
        // Forward to our actual implementation
        sampleSizeChanged(sender)
    }
    
    private func setControlsEnabled(_ enabled: Bool) {
        DispatchQueue.main.async {
            self.sampleSizeSegmentedControl.isEnabled = enabled
            self.algorithmSegmentedControl1.isUserInteractionEnabled = enabled
            self.algorithmSegmentedControl2.isUserInteractionEnabled = enabled
            
            // We don't disable the sort button - we change its functionality instead
        }
    }
}
