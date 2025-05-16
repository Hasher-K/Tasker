//
//  SplashScreenView.swift
//  Tasker
//
//  Created by Hasher Khan on 12/4/24.
//

import Foundation

import SwiftUI

struct SplashScreenView: View {
    @State var isActive : Bool = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View{
        if isActive{
            ContentView()
        } else {
            VStack {
                Spacer()
                Image("1024")
                    .resizable()
                    .frame(width: 375, height: 375)
                    .padding(13)
                Text("Tasker").font(.largeTitle)
                
                Spacer()
              
            }
            .onAppear{
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

