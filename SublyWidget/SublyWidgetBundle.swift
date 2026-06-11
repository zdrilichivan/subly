//
//  SublyWidgetBundle.swift
//  SublyWidget
//
//  Entry point dell'estensione widget.
//

import WidgetKit
import SwiftUI

@main
struct SublyWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextRenewalWidget()
        RenewalLiveActivity()
    }
}
