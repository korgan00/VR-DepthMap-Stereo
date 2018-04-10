using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class RenderStereo : MonoBehaviour {

    [Header("Output Texture")]
    public string textureName = "stereoRender";
    public Vector2Int textureSize = new Vector2Int(4096, 4096);

    [Header("DepthMap")]
    public Shader depthShader;
    [SerializeField]
    [Range(0.0001f, 1.0f)]
    public float depthCorrection = 0.5f;
    [SerializeField]
    [Tooltip("operation is: StereoConvergence / Far")]
    public bool autoDepth = true;

    private static string getRouteToTextures() { return Application.dataPath + "/_ProjectFolder/StereoDepthMapGenerator/RenderedTextures/"; }

    /*
    private void Update() {
        Shader.SetGlobalFloat("_MaxDepth", depthCorrection);
    }
    */

    [ContextMenu("RenderStereo_Albedo_Depth")]
    public void RenderStereoBoth() {
        RenderStereoAlbedo();
        RenderStereoDepth();
    }

    [ContextMenu("RenderStereo_Albedo")]
    public void RenderStereoAlbedo() {
        Camera camera = GetComponent<Camera>();

        // Remember camera config parameters
        RenderingPath path = camera.renderingPath;
        
        // Setup camera for albedo stereo rendering
        camera.stereoSeparation = 0.064f;
        camera.SetReplacementShader(null, "RenderType");
        camera.renderingPath = RenderingPath.Forward;

        // Render stero texture
        RenderCubemap(camera, "_albedo");
        
        // Restore camera config parameters
        camera.SetReplacementShader(null, "RenderType");
        camera.renderingPath = RenderingPath.UsePlayerSettings;
    }

    [ContextMenu("RenderStereo_Depth")]
    public void RenderStereoDepth() {
        Camera camera = GetComponent<Camera>();

        // Remember camera config parameters
        CameraClearFlags clrFlgs = camera.clearFlags;
        Color bgColor = camera.backgroundColor;
        RenderingPath path = camera.renderingPath;

        // Setup camera for depth stereo rendering
        camera.stereoSeparation = 0.064f;
        camera.clearFlags = CameraClearFlags.SolidColor;
        camera.backgroundColor = Color.black;
        camera.SetReplacementShader(depthShader, "RenderType");
        if (autoDepth) {
            depthCorrection = camera.stereoConvergence / camera.farClipPlane;
        }
        Shader.SetGlobalFloat("_MaxDepth", depthCorrection);
        camera.renderingPath = RenderingPath.Forward;
        
        // Render stero texture
        RenderCubemap(camera, "_depth");
        
        // Restore camera config parameters
        camera.SetReplacementShader(null, "RenderType");
        camera.renderingPath = path;
        camera.clearFlags = clrFlgs;
        camera.backgroundColor = bgColor;
    }


    private void RenderCubemap(Camera camera, string pngSuffix = "") {
        RenderTexture rt, equirect;
        Texture2D stereoTexture = new Texture2D(textureSize.x, textureSize.y, TextureFormat.ARGB32, false);

        // Reserve Render Texture Data
        PrepareRenderTextures(out rt, out equirect);

        // Render Left Eye
        camera.RenderToCubemap(rt, 63, Camera.MonoOrStereoscopicEye.Left);
        rt.ConvertToEquirect(equirect, Camera.MonoOrStereoscopicEye.Left);
        RenderTexture.active = equirect; //can help avoid errors
        stereoTexture.ReadPixels(new Rect(0, textureSize.y / 2, textureSize.x, textureSize.y / 2), 0, textureSize.y / 2, false);


        // Render Right Eye
        camera.RenderToCubemap(rt, 63, Camera.MonoOrStereoscopicEye.Right);
        rt.ConvertToEquirect(equirect, Camera.MonoOrStereoscopicEye.Right);
        RenderTexture.active = equirect; //can help avoid errors
        stereoTexture.ReadPixels(new Rect(0, 0, textureSize.x, textureSize.y / 2), 0, 0, false);

        stereoTexture.Apply();

        // Save to Texture
        Debug.LogFormat("File saved at {0}", getRouteToTextures() + textureName + pngSuffix + ".png");
        System.IO.File.WriteAllBytes(getRouteToTextures() + textureName + pngSuffix + ".png", stereoTexture.EncodeToPNG());

        // Free data
        FreeRenderTextures(rt, equirect);
    }

    private void PrepareRenderTextures(out RenderTexture rt, out RenderTexture equirect) {
        rt = new RenderTexture(textureSize.x, textureSize.y, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default) {
            enableRandomWrite = true,
            dimension = UnityEngine.Rendering.TextureDimension.Cube
        };
        equirect = new RenderTexture(textureSize.x, textureSize.y, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default) {
            enableRandomWrite = true,
            dimension = UnityEngine.Rendering.TextureDimension.Tex2D
        };
        if (!rt.Create()) {
            Debug.LogError("Cannot create rendertexture");
            return;
        }
        if (!equirect.Create()) {
            Debug.LogError("Cannot create rendertexture");
            return;
        }
    }

    private void FreeRenderTextures(RenderTexture rt, RenderTexture equirect) {
        RenderTexture.active = null; //can help avoid errors
        DestroyImmediate(equirect);
        DestroyImmediate(rt);
    }
}
