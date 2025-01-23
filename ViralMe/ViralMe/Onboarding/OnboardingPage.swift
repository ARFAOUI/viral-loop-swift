//
//  Untitled.swift
//  ViralMe
//
//  Created by Bechir Arfaoui on 16.01.25.
//
import SwiftUI

struct OnboardingPage: View {
    var title: String
    var description: String?
    var content: AnyView?
    var buttonTitle: String
    var action: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
                .padding()

            if let description = description {
                Text(description)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let content = content {
                content
            }

            Spacer()

            Button(action: action) {
                Text(buttonTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
        }
    }
}
