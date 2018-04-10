using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class RenderStereo : MonoBehaviour {

    public string textureName = "stereoRender";
    public Vector2Int textureSize = new Vector2Int(4096, 4096);
    public Material depthMaterial;
    [SerializeField]
    [Range(0.0001f, 1.0f)]
    public float depthCorrection = 0.5f;

    private void Update() {
        Shader.SetGlobalFloat("_MaxDepth", depthCorrection);
    }

    [ContextMenu("RenderStereo_Albedo_Depth")]
    public void RenderStereoBoth() {
        RenderStereoAlbedo();
        RenderStereoDepth();
    }

    [ContextMenu("RenderStereo_Albedo")]
    public void RenderStereoAlbedo() {
        RenderTexture albedoRT;
        RenderTexture equirectAlbedo;
        Texture2D stereoTexture = new Texture2D(textureSize.x, textureSize.y, TextureFormat.ARGB32, false);

        Camera camera = GetComponent<Camera>();
        albedoRT = new RenderTexture(textureSize.x, textureSize.y, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default) {
            enableRandomWrite = true,
            dimension = UnityEngine.Rendering.TextureDimension.Cube
        };
        equirectAlbedo = new RenderTexture(textureSize.x, textureSize.y, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default) {
            enableRandomWrite = true,
            dimension = UnityEngine.Rendering.TextureDimension.Tex2D
        };
        if (!albedoRT.Create()) {
            Debug.LogError("Cannot create rendertexture");
            return;
        }
        if (!equirectAlbedo.Create()) {
            Debug.LogError("Cannot create rendertexture");
            return;
        }

        camera.stereoSeparation = 0.064f;
        camera.SetReplacementShader(null, "RenderType");
        camera.renderingPath = RenderingPath.Forward;


        camera.RenderToCubemap(albedoRT, 63, Camera.MonoOrStereoscopicEye.Left);
        albedoRT.ConvertToEquirect(equirectAlbedo, Camera.MonoOrStereoscopicEye.Left);
        RenderTexture.active = equirectAlbedo; //can help avoid errors
        stereoTexture.ReadPixels(new Rect(0, textureSize.y / 2, textureSize.x, textureSize.y / 2), 0, textureSize.y / 2, false);
        

        camera.RenderToCubemap(albedoRT, 63, Camera.MonoOrStereoscopicEye.Right);
        albedoRT.ConvertToEquirect(equirectAlbedo, Camera.MonoOrStereoscopicEye.Right);
        RenderTexture.active = equirectAlbedo; //can help avoid errors
        stereoTexture.ReadPixels(new Rect(0, 0, textureSize.x, textureSize.y / 2), 0, 0, false);


        RenderTexture.active = null; //can help avoid errors
        DestroyImmediate(equirectAlbedo);
        DestroyImmediate(albedoRT);
        stereoTexture.Apply();

        Debug.LogFormat("File saved at {0}", Application.dataPath + "/_ProjectFolder/RenderedTextures/" + textureName + ".png");
        System.IO.File.WriteAllBytes(Application.dataPath + "/_ProjectFolder/RenderedTextures/" + textureName + ".png", stereoTexture.EncodeToPNG());


        camera.SetReplacementShader(null, "RenderType");
        camera.renderingPath = RenderingPath.UsePlayerSettings;
    }

    [ContextMenu("RenderStereo_Depth")]
    public void RenderStereoDepth() {
        RenderTexture depthRT;
        RenderTexture equirectDepth;
        Texture2D stereoTexture = new Texture2D(textureSize.x, textureSize.y, TextureFormat.ARGB32, false);


        Camera camera = GetComponent<Camera>();
        depthRT = new RenderTexture(textureSize.x, textureSize.y, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default) {
            enableRandomWrite = true,
            dimension = UnityEngine.Rendering.TextureDimension.Cube
        };
        equirectDepth = new RenderTexture(textureSize.x, textureSize.y, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default) {
            enableRandomWrite = true,
            dimension = UnityEngine.Rendering.TextureDimension.Tex2D
        };
        if (!depthRT.Create()) {
            Debug.LogError("Cannot create rendertexture");
            return;
        }
        if (!equirectDepth.Create()) {
            Debug.LogError("Cannot create rendertexture");
            return;
        }

        CameraClearFlags clrFlgs = camera.clearFlags;
        Color bgColor = camera.backgroundColor;

        camera.stereoSeparation = 0.064f;
        camera.clearFlags = CameraClearFlags.SolidColor;
        camera.backgroundColor = Color.black;
        camera.SetReplacementShader(depthMaterial.shader, "RenderType");
        Shader.SetGlobalFloat("_MaxDepth", depthCorrection);
        camera.renderingPath = RenderingPath.Forward;

        camera.RenderToCubemap(depthRT, 63, Camera.MonoOrStereoscopicEye.Left);
        depthRT.ConvertToEquirect(equirectDepth, Camera.MonoOrStereoscopicEye.Left);
        RenderTexture.active = equirectDepth; //can help avoid errors
        stereoTexture.ReadPixels(new Rect(0, textureSize.y / 2, textureSize.x, textureSize.y / 2), 0, textureSize.y / 2, false);


        camera.RenderToCubemap(depthRT, 63, Camera.MonoOrStereoscopicEye.Right);
        depthRT.ConvertToEquirect(equirectDepth, Camera.MonoOrStereoscopicEye.Right);
        RenderTexture.active = equirectDepth; //can help avoid errors
        stereoTexture.ReadPixels(new Rect(0, 0, textureSize.x, textureSize.y / 2), 0, 0, false);


        RenderTexture.active = null; //can help avoid errors
        DestroyImmediate(equirectDepth);
        DestroyImmediate(depthRT);
        stereoTexture.Apply();

        Debug.LogFormat("File saved at {0}", Application.dataPath + "/_ProjectFolder/RenderedTextures/" + textureName + "_depth.png");
        System.IO.File.WriteAllBytes(Application.dataPath + "/_ProjectFolder/RenderedTextures/" + textureName + "_depth.png", stereoTexture.EncodeToPNG());


        //camera.SetReplacementShader(null, "RenderType");
        camera.renderingPath = RenderingPath.UsePlayerSettings;
        camera.clearFlags = clrFlgs;
        camera.backgroundColor = bgColor;
    }
}
