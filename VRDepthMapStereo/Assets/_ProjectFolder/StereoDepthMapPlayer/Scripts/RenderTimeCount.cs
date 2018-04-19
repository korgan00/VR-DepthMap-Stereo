using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Camera))]
public class RenderTimeCount : MonoBehaviour {

    private float _timeStart;
    private float _timeEnd;
    private float _accumulatedTime = 0;
    private int _times = 0;
    private bool _started = false;
    public Text _text;

    void Start() {
        StartCoroutine(OnPosRender());
    }

    public void StartCount() {
        if (_started) return;
        _timeStart = Time.realtimeSinceStartup;
        _times++;
        _started = true;
    }
    

    void LateUpdate() {
        StartCount();
    }

    IEnumerator OnPosRender() {
        while (true) {
            yield return new WaitForEndOfFrame();
            _timeEnd = Time.realtimeSinceStartup;
            _accumulatedTime += _timeEnd - _timeStart;
            if (_times == 100) {
                _accumulatedTime = _accumulatedTime * 10.0f;
                _text.text = _accumulatedTime + "ms -> " + (1000.0f / _accumulatedTime) + "FPS";
                _times = 0;
                _accumulatedTime = 0;
            }
            _started = false;
        }
    }
}
