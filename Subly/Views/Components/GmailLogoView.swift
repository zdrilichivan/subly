//
//  GoogleSignInButton.swift
//  Subly
//
//  Pulsante ufficiale "Accedi con Google"
//

import SwiftUI

// MARK: - Google "G" Logo

struct GoogleLogoView: View {
    var size: CGFloat = 18

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 18.0

            // Google G colors
            let blue = Color(red: 66/255, green: 133/255, blue: 244/255)
            let green = Color(red: 52/255, green: 168/255, blue: 83/255)
            let yellow = Color(red: 251/255, green: 188/255, blue: 5/255)
            let red = Color(red: 234/255, green: 67/255, blue: 53/255)

            // Blue part (right arc)
            var bluePath = Path()
            bluePath.addArc(center: CGPoint(x: 9 * scale, y: 9 * scale),
                           radius: 8 * scale,
                           startAngle: .degrees(-45),
                           endAngle: .degrees(45),
                           clockwise: false)
            bluePath.addLine(to: CGPoint(x: 9 * scale, y: 9 * scale))
            bluePath.closeSubpath()
            context.fill(bluePath, with: .color(blue))

            // Green part (bottom arc)
            var greenPath = Path()
            greenPath.addArc(center: CGPoint(x: 9 * scale, y: 9 * scale),
                            radius: 8 * scale,
                            startAngle: .degrees(45),
                            endAngle: .degrees(135),
                            clockwise: false)
            greenPath.addLine(to: CGPoint(x: 9 * scale, y: 9 * scale))
            greenPath.closeSubpath()
            context.fill(greenPath, with: .color(green))

            // Yellow part (left-bottom arc)
            var yellowPath = Path()
            yellowPath.addArc(center: CGPoint(x: 9 * scale, y: 9 * scale),
                             radius: 8 * scale,
                             startAngle: .degrees(135),
                             endAngle: .degrees(225),
                             clockwise: false)
            yellowPath.addLine(to: CGPoint(x: 9 * scale, y: 9 * scale))
            yellowPath.closeSubpath()
            context.fill(yellowPath, with: .color(yellow))

            // Red part (top-left arc)
            var redPath = Path()
            redPath.addArc(center: CGPoint(x: 9 * scale, y: 9 * scale),
                          radius: 8 * scale,
                          startAngle: .degrees(225),
                          endAngle: .degrees(315),
                          clockwise: false)
            redPath.addLine(to: CGPoint(x: 9 * scale, y: 9 * scale))
            redPath.closeSubpath()
            context.fill(redPath, with: .color(red))

            // White center circle
            var whitePath = Path()
            whitePath.addEllipse(in: CGRect(x: 4.5 * scale, y: 4.5 * scale,
                                           width: 9 * scale, height: 9 * scale))
            context.fill(whitePath, with: .color(.white))

            // Blue bar (the horizontal part of G)
            var barPath = Path()
            barPath.addRect(CGRect(x: 9 * scale, y: 7.5 * scale,
                                  width: 8 * scale, height: 3 * scale))
            context.fill(barPath, with: .color(blue))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Google Sign-In Button (Official Style)

struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Google G logo in white circle
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)

                    GoogleLogoView(size: 20)
                }

                Text(String(localized: "Accedi con Google"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(white: 0.3))

                Spacer()
            }
            .padding(.leading, 8)
            .padding(.trailing, 16)
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Gmail Logo (for reference/other uses)

struct GmailLogoView: View {
    var size: CGFloat = 24

    private let gmailRed = Color(red: 234/255, green: 67/255, blue: 53/255)

    var body: some View {
        ZStack {
            // Envelope background
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(Color.white)
                .frame(width: size, height: size * 0.75)

            // Red M shape
            GmailMShape()
                .fill(gmailRed)
                .frame(width: size * 0.8, height: size * 0.5)
        }
        .frame(width: size, height: size)
    }
}

struct GmailMShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w / 2, y: h * 0.6))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h * 0.2))
        path.addLine(to: CGPoint(x: w / 2, y: h * 0.8))
        path.addLine(to: CGPoint(x: 0, y: h * 0.2))
        path.closeSubpath()

        return path
    }
}

#Preview {
    VStack(spacing: 24) {
        // Google Sign-In Button
        GoogleSignInButton {
            print("Sign in tapped")
        }
        .padding(.horizontal)

        // Google Logo standalone
        HStack(spacing: 20) {
            GoogleLogoView(size: 24)
            GoogleLogoView(size: 32)
            GoogleLogoView(size: 48)
        }

        // Gmail Logo
        HStack(spacing: 20) {
            GmailLogoView(size: 24)
            GmailLogoView(size: 32)
            GmailLogoView(size: 48)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
