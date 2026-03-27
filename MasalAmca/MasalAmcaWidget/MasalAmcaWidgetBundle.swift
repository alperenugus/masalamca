//
//  MasalAmcaWidgetBundle.swift
//  MasalAmcaWidget
//

import SwiftUI
import WidgetKit

@main
struct MasalAmcaWidgetBundle: WidgetBundle {
    var body: some Widget {
        NowPlayingWidget()
        StoryPlaybackLiveActivityWidget()
    }
}
