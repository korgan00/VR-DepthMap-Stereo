using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class RenderDisplacedTexture : MonoBehaviour {

    public Vector2Int textureSize = Vector2Int.one * 4096;
    public ComputeShader _shader;
    public Material _materialToShareTexture;
    public string _textureName = "_MainTex";

    public Texture2D depth;
    public Texture2D albedo;
    [Range(-1,1)]
    public float _relativePosition;
    [Range(0, 1)]
    public float _parallaxAmount;


    private RenderTexture _outputRT;
    private RenderTexture _depthRT;
    private int _clearKernel;
    private int _writeDepthKernel;
    private int _displaceKernel;
    private uint _xf, _yf;
    private uint _xd, _yd;


    // Use this for initialization
    void Start () {
        _outputRT = CreateRenderTexture();
        _depthRT = CreateRenderTexture();
        UpdateShaderParameters(_outputRT, _depthRT);
    }
	
	// Update is called once per frame
	void OnPreRender() {
        DispatchBoth();
    }

    [ContextMenu("ComputeOnTexture")]
    public void ComputeOnTexture() {
        RenderTexture t = CreateRenderTexture();
        RenderTexture d = CreateRenderTexture();
        UpdateShaderParameters(t, d);
        DispatchBoth();
    }

    private void DispatchBoth() {
        _shader.SetFloat("RelativePosition", _relativePosition);
        _shader.SetFloat("ParallaxAmount", _parallaxAmount * 40);

        /*
        RenderTexture rt = UnityEngine.RenderTexture.active;
        UnityEngine.RenderTexture.active = myRenderTextureToClear;
        GL.Clear(true, true, Color.clear);
        UnityEngine.RenderTexture.active = rt;
        */

        _shader.Dispatch(_clearKernel, textureSize.x / (int) _xf, textureSize.y / (int) _yf, 1);
        _shader.Dispatch(_writeDepthKernel, textureSize.x / (int) _xd, textureSize.y / (int) _yd, 1);
        //_shader.Dispatch(_writeDepthKernel, textureSize.x / (int) _xd, textureSize.y / (int) _yd, 1);
        _shader.Dispatch(_displaceKernel, textureSize.x / (int) _xd, textureSize.y / (int) _yd, 1);
    }

    private RenderTexture CreateRenderTexture() {
        RenderTexture t = new RenderTexture(textureSize.x, textureSize.y, 1, RenderTextureFormat.ARGBFloat) {
            dimension = UnityEngine.Rendering.TextureDimension.Tex2D,
            enableRandomWrite = true
        };
        t.Create();

        return t;
    }

    private void UpdateShaderParameters(RenderTexture t, RenderTexture d) {
        uint _zf, _zd;
        if (t == null) { t = _outputRT; }

        _materialToShareTexture.SetTexture(_textureName, t);
        _clearKernel = _shader.FindKernel("Clear");
        _writeDepthKernel = _shader.FindKernel("WriteDepth");
        _displaceKernel = _shader.FindKernel("DisplaceAlbedo");
        _shader.SetTexture(_clearKernel, "Result", t);
        _shader.SetTexture(_clearKernel, "Depth", d);
        
        _shader.SetTexture(_writeDepthKernel, "Depth", d);
        _shader.SetTexture(_writeDepthKernel, "DepthTexture", depth);
        _shader.SetTexture(_writeDepthKernel, "Result", t);
        _shader.SetTexture(_writeDepthKernel, "AlbedoTexture", albedo);

        _shader.SetTexture(_displaceKernel, "Result", t);
        _shader.SetTexture(_displaceKernel, "Depth", d);
        _shader.SetTexture(_displaceKernel, "DepthTexture", depth);
        _shader.SetTexture(_displaceKernel, "AlbedoTexture", albedo);

        _shader.GetKernelThreadGroupSizes(_clearKernel, out _xf, out _yf, out _zf);
        _shader.GetKernelThreadGroupSizes(_displaceKernel, out _xd, out _yd, out _zd);
    }
}
