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
    @State private var currentWords = [String]()
    @State private var currentIndexWord = 0
    @State private var isReadingFromText = false
    
    private let speechRecignizer = SpeechRecognizer()
    
    var words: [String] {
        text.components(separatedBy: .whitespacesAndNewlines).map { component in
            component.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.string
        }.filter { !$0.isEmpty }
    }
    
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
                        
                        if isReadingFromText {
                            
                            let fullText = words.enumerated().reduce(Text("")) { (partialResult, current) in
                                let (index, word) = current
                                let wordText = Text(word + (index < words.count - 1 ? " " : ""))
                                    .font(.title2)
                                    .fontDesign(.rounded)
                                    .bold()
                                    .foregroundColor(index <= currentIndexWord - 1 ? .white : .gray.opacity(0.75))
                                
                                return partialResult + wordText
                            }
                            
                            // Display the concatenated text
                            fullText
                                .padding(.horizontal)
                            
                        } else {
                            
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
                            .padding(.horizontal)
                            
                        }
                        
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
        .overlay(bottomLeadingButtons, alignment: .bottomLeading)
        .sheet(isPresented: $showTextEditor) { editTextView }
        .onAppear {
            
            
        }
    }
    
    func handleWordListening(_ speech: String) {
        guard words.count != 0 && currentIndexWord < words.count else { return }
        if let cleanedSpeech = speech.components(separatedBy: .whitespaces).last {
            let check = words[currentIndexWord]
            if cleanedSpeech.lowercased() == check.lowercased() {
                currentWords.append(cleanedSpeech)
                currentIndexWord += 1
            }
        }
    }
}

extension Sequence where Iterator.Element == Unicode.Scalar {
    var string: String {
        String(String.UnicodeScalarView(self))
    }
}

extension ContentView {
    var bottomLeadingButtons: some View {
        VStack {
            menuButton
            recordingButton
        }
    }
    
    var menuButton: some View {
        Menu {
            Toggle(isOn: $isReadingFromText) {
                Label("Read from text", systemImage: "waveform.circle")
            }
            .onChange(of: isReadingFromText) { _, _ in
                if isReadingFromText {
                    try? speechRecignizer.startListening { result in
                        guard let speech = result else { return }
                        handleWordListening(speech)
                    }
                } else {
                    speechRecignizer.stopListening()
                    currentIndexWord = 0
                }
            }
            
            Button("Edit text") {
                showTextEditor.toggle()
            }
            
        } label: {
            Image(systemName: "gear")
        }
        .padding()
        .frame(width: 60, height: 60)
        .background(.ultraThinMaterial, in: Circle())
        .foregroundStyle(.white)
        .font(.title)
    }
    
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
            
            Button("Empty text 🥶") {
                showTextEditor.toggle()
            }
            .font(.title)
            .bold()
            .fontDesign(.rounded)
            .tint(.white)
            .opacity(text.isEmpty ? 1.0 : 0)
            
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
        .frame(width: 60, height: 60)
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
