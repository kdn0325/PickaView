//
//  FullscreenPlayerViewController.swift
//  PickaView
//
//  Created by junil on 6/11/25.
//

import UIKit
import AVKit

/// 전체화면 영상 플레이어 뷰 컨트롤러
class FullscreenPlayerViewController: UIViewController {
    
    let viewModel: PlayerViewModel
    
    init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Properties
    
    /// 영상 출력을 위한 AVPlayerLayer
    private var playerLayer: AVPlayerLayer?

    /// 영상 출력을 위한 AVPlayer
    var player: AVPlayer?

    /// 플레이어 컨트롤 오버레이 뷰 (재생/정지, 시커 등)
    var controlsOverlayView: UIView?

    /// 전체화면 dismiss 시 호출될 델리게이트
    weak var delegate: PlayerViewControllerDelegate?

    /// 중복 dismiss 방지용 플래그
    private var isDismissing = false

    /// (옵션) 전체화면 모드 여부
    private var isFullscreenMode = false

    var exitFullscreenButton: UIButton?
    
    var rateTwoView: UIView?

    // MARK: - Lifecycle

    /// 뷰가 메모리에 올라왔을 때 호출
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        if let player = self.player {
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = view.bounds
            playerLayer.videoGravity = .resizeAspect
            
            view.layer.insertSublayer(playerLayer, at: 0)
            self.playerLayer = playerLayer
        }

        // 오버레이 추가 및 오토레이아웃
        if let controlsOverlayView = controlsOverlayView, let rateTwoView {
            view.addSubview(controlsOverlayView)
            controlsOverlayView.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(rateTwoView)
            view.insertSubview(rateTwoView, belowSubview: controlsOverlayView)
            rateTwoView.layer.cornerRadius = 8
            
            NSLayoutConstraint.activate([
                controlsOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                controlsOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                controlsOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
                controlsOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                
                rateTwoView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
                rateTwoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ])
        }

        exitFullscreenButton?.alpha = 1.0
        exitFullscreenButton?.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)

        // 스와이프 다운 제스처(뷰/오버레이에 모두 등록)
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        controlsOverlayView?.addGestureRecognizer(swipeDown)

        // 기기 회전 감지(세로 전환 시 전체화면 닫기)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deviceOrientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        exitFullscreenButton?.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        exitFullscreenButton?.isHidden = true
    }

    /// 레이아웃이 변경될 때마다 AVPlayerLayer 크기 갱신
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }

    // MARK: - Orientation & Dismiss

    /// 기기 방향 변경 감지 시 호출 (세로면 dismiss)
    @objc
    private func deviceOrientationDidChange() {
        let orientation = UIDevice.current.orientation
        if orientation == .portrait {
            handleDismiss()
        }
    }

    /// 전체화면 뷰 dismiss 처리 및 델리게이트 호출
    @objc
    private func handleDismiss() {
        guard !isDismissing else { return }
        isDismissing = true

        // dismiss 및 delegate 전달
        dismiss(animated: true) { [weak self] in
            self?.delegate?.didDismissFullscreen()
            self?.isDismissing = false
        }
    }

    // MARK: - Status Bar & System Gesture

    /// 상태바 숨김
    override var prefersStatusBarHidden: Bool { true }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
