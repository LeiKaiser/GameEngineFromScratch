#pragma once
#include <vector>
#include <memory>
#include "cbuffer.h"
#include "GfxConfiguration.hpp"
#include "FrameStructure.hpp"
#include "IRuntimeModule.hpp"
#include "IShaderManager.hpp"
#include "geommath.hpp"
#include "Image.hpp"
#include "Scene.hpp"
#include "Polyhedron.hpp"
#include "IDrawPass.hpp"
#include "IDispatchPass.hpp"

namespace My {
    class GraphicsManager : implements IRuntimeModule
    {
    public:
        virtual ~GraphicsManager() {}

        virtual int Initialize();
        virtual void Finalize();

        virtual void Tick();

        virtual void Draw();
        virtual void Present();

        virtual void UseShaderProgram(const IShaderManager::ShaderHandler shaderProgram);

        virtual void DrawBatch(const std::vector<std::shared_ptr<DrawBatchContext>>& batches);

        virtual int32_t GenerateCubeShadowMapArray(const uint32_t width, const uint32_t height, const uint32_t count);
        virtual int32_t GenerateShadowMapArray(const uint32_t width, const uint32_t height, const uint32_t count);
        virtual void BeginShadowMap(const Light& light, const int32_t shadowmap, const uint32_t width, const uint32_t height, const uint32_t layer_index);
        virtual void EndShadowMap(const int32_t shadowmap, const uint32_t layer_index);
        virtual void SetShadowMaps(const Frame& frame);
        virtual void DestroyShadowMap(int32_t& shadowmap);

        // skybox
        virtual void SetSkyBox(const DrawFrameContext& context);
        virtual void DrawSkyBox();

        // terrain
        virtual void SetTerrain(const DrawFrameContext& context);
        virtual void DrawTerrain();

        virtual int32_t GenerateTexture(const char* id, const uint32_t width, const uint32_t height);
        virtual void BeginRenderToTexture(int32_t& context, const int32_t texture, const uint32_t width, const uint32_t height);
        virtual void EndRenderToTexture(int32_t& context);

        virtual int32_t GenerateAndBindTextureForWrite(const char* id, const uint32_t width, const uint32_t height);
        virtual void Dispatch(const uint32_t width, const uint32_t height, const uint32_t depth);

        virtual int32_t GetTexture(const char* id);

        virtual void DrawFullScreenQuad();

#ifdef DEBUG
        virtual void DrawPoint(const Point& point, const Vector3f& color);
        virtual void DrawPointSet(const PointSet& point_set, const Vector3f& color);
        virtual void DrawPointSet(const PointSet& point_set, const Matrix4X4f& trans, const Vector3f& color);
        virtual void DrawLine(const Point& from, const Point& to, const Vector3f &color);
        virtual void DrawLine(const PointList& vertices, const Vector3f &color);
        virtual void DrawLine(const PointList& vertices, const Matrix4X4f& trans, const Vector3f &color);
        virtual void DrawTriangle(const PointList& vertices, const Vector3f &color);
        virtual void DrawTriangle(const PointList& vertices, const Matrix4X4f& trans, const Vector3f &color);
        virtual void DrawTriangleStrip(const PointList& vertices, const Vector3f &color);
        virtual void DrawTextureOverlay(const int32_t texture, float vp_left, float vp_top, float vp_width, float vp_height);
        virtual void DrawTextureArrayOverlay(const int32_t texture, uint32_t layer_index, float vp_left, float vp_top, float vp_width, float vp_height);
        virtual void DrawCubeMapOverlay(const int32_t cubemap, float vp_left, float vp_top, float vp_width, float vp_height, float level = 0.0f);
        virtual void DrawCubeMapArrayOverlay(const int32_t cubemap, uint32_t layer_index, float vp_left, float vp_top, float vp_width, float vp_height, float level = 0.0f);
        virtual void ClearDebugBuffers();

        void DrawEdgeList(const EdgeList& edges, const Vector3f& color);
        void DrawPolygon(const Face& face, const Vector3f& color);
        void DrawPolygon(const Face& face, const Matrix4X4f& trans, const Vector3f& color);
        void DrawPolyhydron(const Polyhedron& polyhedron, const Vector3f& color);
        void DrawPolyhydron(const Polyhedron& polyhedron, const Matrix4X4f& trans, const Vector3f& color);
        void DrawBox(const Vector3f& bbMin, const Vector3f& bbMax, const Vector3f& color);
#endif

    protected:
        virtual void BeginScene(const Scene& scene);
        virtual void EndScene();

        virtual void BeginFrame();
        virtual void EndFrame();

        virtual void BeginPass();
        virtual void EndPass();

        virtual void BeginCompute();
        virtual void EndCompute();

#ifdef DEBUG
        virtual void RenderDebugBuffers();
#endif

    private:
        void InitConstants();
        void CalculateCameraMatrix();
        void CalculateLights();

        void UpdateConstants();

        virtual void SetLightInfo(const LightInfo& lightInfo);
        virtual void SetPerFrameConstants(const DrawFrameContext& context);
        virtual void SetPerBatchConstants(const std::vector<std::shared_ptr<DrawBatchContext>>& batches);

    protected:
        uint32_t m_nFrameIndex = 0;

        std::vector<Frame>  m_Frames;
        std::vector<std::shared_ptr<IDispatchPass>> m_InitPasses;
        std::vector<std::shared_ptr<IDrawPass>> m_DrawPasses;
    };

    extern GraphicsManager* g_pGraphicsManager;
}

