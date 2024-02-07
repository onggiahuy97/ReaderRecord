//
//  ContentView.swift
//  RecordReading
//
//  Created by Huy Ong on 2/6/24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var dragOffset = CGSize.zero
    // Add this to keep track of the accumulated offset
    @State private var accumulatedDragOffset = CGSize.zero
    @State private var showTextEditor = false
    @State private var text = textTest
    @State private var sizeRatio = 0.25
    @State private var currentIndex = 0
    @State private var isRecording = false
    @State private var cameraView = CameraView()
    @State private var isCameraOn = true
    
    var textList: [(Int, String)] {
        Array(text.components(separatedBy: "\n").enumerated())
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Update dragOffset based on the current gesture value plus any accumulated offset
                self.dragOffset = CGSize(
                    width: value.translation.width + self.accumulatedDragOffset.width,
                    height: value.translation.height + self.accumulatedDragOffset.height
                )
            }
            .onEnded { value in
                self.accumulatedDragOffset = self.dragOffset
            }
        
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let size = proxy.size
                
                backgroundView
                
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        Spacer()
                            .frame(height: 50)
                        ForEach(textList, id: \.0) { index, line in
                            Text(line)
                                .id(index)
                                .font(.title2)
                                .fontDesign(.rounded)
                                .bold()
                                .foregroundStyle(currentIndex == index ? .white : .gray.opacity(0.75))
                                .onTapGesture {
                                    withAnimation(.spring) {
                                        scrollProxy.scrollTo(index, anchor: .center)
                                        currentIndex = index
                                    }
                                }
                        }
                        .padding()
                        
                        Spacer()
                            .frame(height: size.height * 0.9)
                    }
                }
                .scrollContentBackground(.hidden)
                
                cameraView
                    .overlay(cameraOverlayView)
                    .frame(width: size.width * sizeRatio, height: size.width * sizeRatio + 50)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .offset(dragOffset)
                    .shadow(radius: 2)
                    .gesture(dragGesture)
                    .onTapGesture {
                        guard !isRecording else { return }
                        if isCameraOn {
                            cameraView.stopCamera()
                        } else {
                            cameraView.startCamera()
                        }
                        isCameraOn.toggle()
                    }
                    .onAppear {
                        self.dragOffset.width = size.width - (size.width * sizeRatio + 15)
                        self.dragOffset.height = size.height - (size.height * sizeRatio + 15)
                        self.accumulatedDragOffset = self.dragOffset
                    }
            }
        }
        .ignoresSafeArea()
        .overlay(recordingButton, alignment: .bottomLeading)
        .onTapGesture {
            showTextEditor.toggle()
        }
        .sheet(isPresented: $showTextEditor) { editTextView }
        .onAppear {
            let speech = SpeechRecognizer()
            try? speech.startListening { result in
                guard let speech = result else { return }
                
            }
        }
    }
}

extension ContentView {
    var backgroundView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Semi-transparent overlay with material effect
            Color.black.opacity(0.4)
                .background(Material.ultraThin)
        }
    }
    
    var cameraOverlayView: some View {
        ZStack {
            Color.black
            Image(systemName: "web.camera.fill")
                .foregroundStyle(.white)
                .font(.title)
                .bold()
        }
        .opacity(isCameraOn ? 0 : 1.0)
    }
    
    var recordingButton: some View {
        Button {
            if isRecording {
                cameraView.stopRecording()
            } else {
                cameraView.startRecording()
            }
            isRecording.toggle()
        } label: {
            Image(systemName: isRecording ? "stop.fill" : "video.fill")
        }
        .padding()
        .background(isRecording ? .red : .blue, in: Circle())
        .foregroundStyle(.white)
        .font(.title)
        .padding()
        .opacity(isCameraOn ? 1.0 : 0)
    }
    
    var editTextView: some View {
        NavigationView {
            TextEditor(text: $text)
                .navigationTitle("Edit Content")
                .toolbar {
                    ToolbarItem {
                        Button("Done") {
                            showTextEditor.toggle()
                        }
                    }
                }
                .padding(.horizontal)
        }
    }
}

#Preview {
    ContentView()
}
