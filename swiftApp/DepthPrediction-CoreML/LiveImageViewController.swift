//
//  LiveImageViewController.swift
//  DepthPrediction-CoreML
//
//  Created by Doyoung Gwak on 20/07/2019.
//  Copyright © 2019 Doyoung Gwak. All rights reserved.
//

import UIKit
import Vision

var avgOut: Float = 0.0

class LiveImageViewController: UIViewController {

    // MARK: - UI Properties
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var drawingView: DrawingHeatmapView!
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
//    @IBOutlet weak var pixelLabel: UILabel!
    // MARK: - AV Properties
    var videoCapture: VideoCapture!
    
    // MARK - Core ML model
    // FCRN(iOS11+), FCRNFP16(iOS11+)
    let estimationModel = FCRN()
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    let postprocessor = HeatmapPostProcessor()
    
    // MARK: - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup ml model
        setUpModel()
        
        // setup camera
        setUpCamera()
        
        // setup delegate for performance measurement
        👨‍🔧.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.videoCapture.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.videoCapture.stop()
    }
    
    // MARK: - Setup Core ML
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: estimationModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError()
        }
    }
    
    // MARK: - Setup camera
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            
            if success {
                // UI에 비디오 미리보기 뷰 넣기
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // 초기설정이 끝나면 라이브 비디오를 시작할 수 있음
                self.videoCapture.start()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
}

// MARK: - VideoCaptureDelegate
extension LiveImageViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?/*, timestamp: CMTime*/) {
        
        // the captured image from camera is contained on pixelBuffer
        if let pixelBuffer = pixelBuffer {
            // start of measure
            self.👨‍🔧.🎬👏()
            
            // predict!
            predict(with: pixelBuffer)
        }
    }
}

// MARK: - Inference
extension LiveImageViewController {
    // prediction
    func predict(with pixelBuffer: CVPixelBuffer) {
        guard let request = request else { fatalError() }
        
        // vision framework configures the input size of image following our model's input configuration automatically
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    // post-processing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        
        self.👨‍🔧.🏷(with: "endInference")
        
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let heatmap = observations.first?.featureValue.multiArrayValue {
            // shape -> [128, 160]
            
//            let centerX = 42 // Adjust as per your requirement
//            let centerY = 0 // Adjust as per your requirement
//            let width = 43 // Adjust as per your requirement
//            let height = 160 // Adjust as per your requirement
//
//            // Extract the region of interest from the heatmap
//            var flattenedArray: [Float] = []
//
//            for y in centerY..<(centerY + height) {
//                for x in centerX..<(centerX + width) {
//                    if let pixelValue = heatmap[y * 128 + x] as? Float {
//                        flattenedArray.append(pixelValue)
//                    }
//                }
//            }
            
            let gridRowCount = 3
            let gridColumnCount = 3
            
            let heatmapWidth = 160 // Adjust according to your heatmap dimensions
            let heatmapHeight = 128 // Adjust according to your heatmap dimensions

            let cellWidth = heatmapWidth / gridRowCount
            let cellHeight = heatmapHeight / gridColumnCount

            var cellSums: [Float] = Array(repeating: 0, count: gridRowCount * gridColumnCount)

            for gridY in 0..<gridRowCount {
                for gridX in 0..<gridColumnCount {
                    let startX = gridX * cellWidth
                    let startY = gridY * cellHeight
                    
                    for y in startY..<(startY + cellHeight) {
                        for x in startX..<(startX + cellWidth) {
                            if let pixelValue = heatmap[y * heatmapWidth + x] as? Float {
                                cellSums[gridY * gridColumnCount + gridX] += pixelValue
                            }
                        }
                    }
                }
            }
            
            let convertedHeatmap = postprocessor.convertTo2DArray(from: heatmap)
//            
            
//            let sum = flattenedArray.reduce(0, +)    // Calculate the sum of all elements
//            let count = flattenedArray.count          // Count the total number of elements
//            avgOut = Float(sum) / Float(count)
//            print(cellSums)

            DispatchQueue.main.async { [weak self] in
                // update result
                self?.drawingView.heatmap = convertedHeatmap
                self?.drawingView.cellSums = cellSums
                self?.👨‍🔧.🎬🤚()
            }
        } else {
            // end of measure
            self.👨‍🔧.🎬🤚()
        }
    }
}

// MARK: - 📏(Performance Measurement) Delegate
extension LiveImageViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        //print(executionTime, fps)
//        self.inferenceLabel.text = "inference: \(Int(inferenceTime*1000.0)) mm"
//        self.etimeLabel.text = "execution: \(Int(executionTime*1000.0)) mm"
        self.fpsLabel.text = "threshold: \(avgOut)"
        
        let threshold: Float = 2.0 // Change this to your desired threshold
                
        // Change the color of fpsLabel based on the threshold
        if avgOut > threshold {
            // If the avgOut value is greater than the threshold, set the text color to red
            self.fpsLabel.textColor = UIColor.green
        } else {
            // Otherwise, set the text color to green
            self.fpsLabel.textColor = UIColor.red
        }
        
    }
}
