using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class FakeRenderDisplacedTextureBuffersRepeatedIfs : MonoBehaviour {

    public Vector2Int textureSize = Vector2Int.one * 4096;
    public ComputeShader _shader;
    public Material _materialToShareTexture;
    public string _textureName = "_MainTex";

    public Texture2D depth;
    public Texture2D albedo;
    [Range(-1, 1)]
    public float _relativePosition;
    [Range(0, 1)]
    public float _parallaxAmount;


    private RenderTexture _outputRT;
    private ComputeBuffer _lock;
 
    //private ComputeBuffer _mutexBuffer;
    private int _clearKernel;
    private int _writeDepthKernel;
    //private int _displaceKernel;
    private uint _xf, _yf;
    private uint _xw, _yw;
    private uint _xd, _yd;
    
    private bool _kernelsLoaded = false;

    private Camera cam { get { return GetComponent<Camera>(); } }

    void Start() {
        _outputRT = CreateRenderTexture();
        _lock = CreateDepthBuffer();
        UpdateShaderParameters(_outputRT, _lock);
    }

    private void OnDestroy() {
        _outputRT.Release();
    }
    
    void OnPreRender() {
        DispatchBoth();
    }

    [ContextMenu("ComputeOnTexture")]
    public void ComputeOnTexture() {
        DispatchBoth();
    }

    private void DispatchBoth() {
        _shader.SetFloat("RelativePosition", _relativePosition);
        _shader.SetFloat("ParallaxAmount", _parallaxAmount * 400);
        
        if (_kernelsLoaded) {
            _shader.Dispatch(_clearKernel, textureSize.x / (int) _xf, textureSize.y / (int) _yf, 1);
            _shader.Dispatch(_writeDepthKernel, textureSize.x / (int)_xw, textureSize.y / (int)_yw, 1);
           // _shader.Dispatch(_writeDepthKernel, textureSize.x / (int)_xw, textureSize.y / (int)_yw, 1);
           // _shader.Dispatch(_writeDepthKernel, textureSize.x / (int)_xw, textureSize.y / (int)_yw, 1);
        }
    }

    private RenderTexture CreateRenderTexture() {
        RenderTexture rt = new RenderTexture(textureSize.x, textureSize.y, 0, RenderTextureFormat.ARGB32) {
            dimension = UnityEngine.Rendering.TextureDimension.Tex2D,
            enableRandomWrite = true
        };
        rt.Create();

        return rt;
    }

    private ComputeBuffer CreateDepthBuffer() {
        ComputeBuffer buffer = new ComputeBuffer(textureSize.x * textureSize.y, 4, ComputeBufferType.Default);
        uint[] data = new uint[textureSize.x * textureSize.y];
        buffer.SetData(data);

        return buffer;
    }


    private void UpdateShaderParameters(RenderTexture t, ComputeBuffer myLock) {
        uint zf, zw;
        if (t == null) { t = _outputRT; }
        
        _kernelsLoaded = _shader.HasKernel("WriteDepth")  && _shader.HasKernel("Clear");
        if (!_kernelsLoaded) {
            Debug.LogError("Shader Kernel compilation error");
            return;
        }

        _materialToShareTexture.SetTexture(_textureName, t);
        _clearKernel = _shader.FindKernel("Clear");
        _writeDepthKernel = _shader.FindKernel("WriteDepth");

        //_shader.SetBuffer(_clearKernel, "Depth", d);       
        _shader.SetTexture(_clearKernel, "Result", t);
        _shader.SetBuffer(_clearKernel, "lock", myLock);

        //_shader.SetBuffer(_writeDepthKernel, "Depth", d);        
        _shader.SetBuffer(_writeDepthKernel, "lock", myLock);
        _shader.SetTexture(_writeDepthKernel, "Result", t);
        _shader.SetTexture(_writeDepthKernel, "DepthTexture", depth);
        _shader.SetTexture(_writeDepthKernel, "AlbedoTexture", albedo);
        


        _shader.GetKernelThreadGroupSizes(_clearKernel, out _xf, out _yf, out zf);
        _shader.GetKernelThreadGroupSizes(_writeDepthKernel, out _xw, out _yw, out zw);
    }
}
