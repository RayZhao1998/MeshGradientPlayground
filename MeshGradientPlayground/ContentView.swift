//
//  ContentView.swift
//  MeshGradientPlayground
//
//  Created by ZiyuanZhao on 2024/6/12.
//

import SwiftData
import SwiftUI

struct MeshGradientPoint: Identifiable, Hashable {
    var x: CGFloat
    var y: CGFloat
    var color: Color

    var id: UUID

    init(x: CGFloat, y: CGFloat, color: Color) {
        self.x = x
        self.y = y
        self.color = color

        self.id = UUID()
    }
}

func stringToCGFloat(_ string: String) -> CGFloat? {
    if let doubleValue = Double(string) {
        return CGFloat(doubleValue)
    } else {
        return nil
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @State var points: [MeshGradientPoint] = [
        MeshGradientPoint(x: 0, y: 0, color: .red),
        MeshGradientPoint(x: 0.5, y: 0, color: .purple),
        MeshGradientPoint(x: 1, y: 0, color: .indigo),
        MeshGradientPoint(x: 0, y: 0.5, color: .orange),
        MeshGradientPoint(x: 0.5, y: 0.5, color: .white),
        MeshGradientPoint(x: 1, y: 0.5, color: .blue),
        MeshGradientPoint(x: 0, y: 1, color: .yellow),
        MeshGradientPoint(x: 0.5, y: 1, color: .green),
        MeshGradientPoint(x: 1, y: 1, color: .mint)
    ]

    @State private var selectedPoint: MeshGradientPoint?

    @State private var showExportPopover: Bool = false
    @State private var exportWidth: String = "1920"
    @State private var exportHeight: String = "1080"

    var body: some View {
        HStack {
            GeometryReader { proxy in
                ZStack {
                    MeshGradient(width: 3, height: 3, points: self.points.map { [Float($0.x), Float($0.y)] }, colors: self.points.map { $0.color })
                    ForEach(self.points) { point in
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(point.color)
                            .overlay(Circle().stroke(point == self.selectedPoint ? Color.accentColor : Color.white, lineWidth: 2))
                            .shadow(radius: 3)
                            .position(x: proxy.size.width * CGFloat(point.x), y: proxy.size.height * CGFloat(point.y))
                            .gesture(DragGesture().onChanged { value in
                                if let draggingPointIndex = points.firstIndex(of: point) {
                                    self.points[draggingPointIndex].x = min(max(0, value.location.x), proxy.size.width) / proxy.size.width
                                    self.points[draggingPointIndex].y = min(max(0, value.location.y), proxy.size.height) / proxy.size.height
                                    self.selectedPoint = self.points[draggingPointIndex]
                                }
                            })
                            .onTapGesture {
                                self.selectedPoint = point
                            }
                    }
                }
            }
            VStack(alignment: .leading) {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        Section("Points info") {
                            ForEach(self.points.indices, id: \.self) { index in
                                HStack(alignment: .center) {
                                    ColorPicker("", selection: $points[index].color)
                                    TextField("X", text: Binding(get: {
                                        return String(format: "%.2f", self.points[index].x)
                                    }, set: { newValue in
                                        if let value = stringToCGFloat(newValue) {
                                            self.points[index].x = value
                                        }
                                    }))
                                    TextField("Y", text: Binding(get: {
                                        return String(format: "%.2f", self.points[index].y)
                                    }, set: { newValue in
                                        if let value = stringToCGFloat(newValue) {
                                            self.points[index].y = value
                                        }
                                    }))
                                    Button {
                                        self.points.remove(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle")
                                    }

                                }
                            }
                            Button {
                                self.points.append(MeshGradientPoint(x: 0, y: 0, color: .white))
                            } label: {
                                Label {
                                    Text("Add new point")
                                } icon: {
                                    Image(systemName: "plus.circle")
                                }
                            }
                        }
                    }
                }
                Spacer()
                Button("Export") { self.showExportPopover.toggle() }
                    .popover(isPresented: $showExportPopover) {
                        VStack {
                            HStack {
                                TextField("Width", text: $exportWidth)
                                TextField("Height", text: $exportHeight)
                            }
                            Button("Export") {
                                exportMeshGradientAsImage()
                            }
                        }
                        .padding()
                    }
            }
            .frame(maxWidth: 200)
        }
        .padding()
    }

    private func exportMeshGradientAsImage() {
        let view = NSHostingView(rootView: MeshGradient(width: 3, height: 3, points: self.points.map { [Float($0.x), Float($0.y)] }, colors: self.points.map { $0.color }))
        let targetSize = CGSize(width: Double(self.exportWidth) ?? 1920, height: Double(self.exportHeight) ?? 1080)
        view.setFrameSize(targetSize)

        let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: bitmapRep)

        let image = NSImage(size: targetSize)
        image.addRepresentation(bitmapRep)

        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:])
        {
            let savePanel = NSSavePanel()
            savePanel.allowedFileTypes = ["png"]
            savePanel.nameFieldStringValue = "ExportedImage.png"
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try pngData.write(to: url)
                        print("图像已保存到 \(url.path)")
                    } catch {
                        print("图像保存失败: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
//        .modelContainer(for: nil, inMemory: true)
}
