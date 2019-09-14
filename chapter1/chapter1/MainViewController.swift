//
//  MainViewController.swift
//  chapter1
//
//  Created by duan on 2019/09/07.
//  Copyright © 2019 monk-studio. All rights reserved.
//

import AppKit
import SnapKit
import MetalKit


class MainViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let device = MTLCreateSystemDefaultDevice()!
        // NOTE: MTKView derived by device
        let mRect = CGRect(x: 0, y: 0, width: 400, height: 400)
        let mView = MTKView(frame: mRect, device: device)
        mView.clearColor = .init(red: 1, green: 1, blue: 0.8, alpha: 1)
        view.addSubview(mView)

        // NOTE: MDLMesh derived by device
        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlMesh = MDLMesh(
            sphereWithExtent: [0.75, 0.75, 0.75],
            segments: [100, 100],
            inwardNormals: false,
            geometryType: .triangles,
            allocator: allocator)
        let mesh = try! MTKMesh(mesh: mdlMesh, device: device)

        // NOTE: MTLCommandQueue derived by device
        let commandQueue = device.makeCommandQueue()!

        let shader = """
            #include <metal_stdlib>
            using namespace metal;
            struct VertexIn {
              float4 position [[ attribute(0) ]];
            };
            vertex float4 vertex_main(const VertexIn vertex_in [[ stage_in ]]) {
              return vertex_in.position;
            }
            fragment float4 fragment_main() {
              return float4(1, 0, 0, 1);
            }
        """

        // NOTE: MTLLibrary derived by device
        let library = try! device.makeLibrary(source: shader, options: nil)

        // NOTE: Init pipeline state
        // By setting up this state, you're telling the GPU that nothing will change until the state changes, and so the GPU can run more efficiently.
        let pipelineDescriptor = MTLRenderPipelineDescriptor().then {
            $0.colorAttachments[0].pixelFormat = .bgra8Unorm
            $0.vertexFunction = library.makeFunction(name: "vertex_main")
            $0.fragmentFunction = library.makeFunction(name: "fragment_main")
            $0.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        }
        let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        // NOTE: Init CommandQueue & CommandQueue's RenderCommandEncoder
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderPassDescriptor = mView.currentRenderPassDescriptor!
        let rcEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        rcEncoder.setRenderPipelineState(pipelineState)
        rcEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer,
                                  offset: 0, index: 0)

        let subMesh = mesh.submeshes.first!
        rcEncoder.drawIndexedPrimitives(type: .triangle,
            indexCount: subMesh.indexCount,
            indexType: subMesh.indexType,
            indexBuffer: subMesh.indexBuffer.buffer,
            indexBufferOffset: 0)

        // End
        rcEncoder.endEncoding()
        let drawable = mView.currentDrawable!
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

}
