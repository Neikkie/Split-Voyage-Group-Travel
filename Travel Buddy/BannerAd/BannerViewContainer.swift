//
//  BannerAdVC.swift
//  Frass History
//
//  Created by Chad on 11/25/21.
//

import Foundation
import UIKit
import GoogleMobileAds
import SwiftUI

// [START create_banner_view]
struct BannerViewContainer: UIViewRepresentable {
	public typealias UIViewType = BannerView
	let bannerAdType: BannerAdType
	
	init(bannerAdType: BannerAdType) {
		self.bannerAdType = bannerAdType
	}
	
	public func makeUIView(context: Context) -> BannerView {
		let adSize = currentOrientationAnchoredAdaptiveBanner(width: 375)
		let banner = BannerView(adSize: adSize)
		
		banner.adUnitID = bannerAdType.rawValue
		banner.load(Request())
		banner.delegate = context.coordinator
		// [END set_delegate]
		return banner
	}
	
	func updateUIView(_ uiView: BannerView, context: Context) {}
	
	func makeCoordinator() -> BannerCoordinator {
		return BannerCoordinator(self)
	}
	
	class BannerCoordinator: NSObject, BannerViewDelegate {
		
		let parent: BannerViewContainer
		
		init(_ parent: BannerViewContainer) {
			self.parent = parent
		}

		
		func bannerViewDidReceiveAd(_ bannerView: BannerView) {
			print("DID RECEIVE AD.")
		}
		
		func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
			print("FAILED TO RECEIVE AD: \(error.localizedDescription)")
		}
	}
}
