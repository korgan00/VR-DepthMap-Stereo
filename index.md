---
layout: default
---


# Parallax Test 3
###### April 19, 2018



<div class="youtube-video" markdown="1">
  [![Test 1](https://img.youtube.com/vi/R2rfZYyaCcE/0.jpg)](https://www.youtube.com/watch?v=R2rfZYyaCcE){:target="_blank"}
</div>

# Parallax Test 2 
###### April 17, 2018

To solve the parallax test 1 errors, the current pixel should look at the neighborhood and calculate wich is 
the best pixel to occupy the current pixel.

That idea make lots of texture fetchs. When observer is displaced, every pixel should move on the same direction 
with diferent displacement amount. Taking that into account, the number of fetchs will be optimized only looking 
through the pixels into the displacement line.

With this algorithm the main problem is that many pixels wont have a good fetch to fill it. At the moment, this
pixels will be pink.

The new fragment code is a bit more complicated:

{% highlight glsl %}
float4 frag (v2f i) : SV_Target {
    // fetch height and initialize variables
    float height = DecodeFloatRGBA(tex2D(_DepthTex, i.uv));
    float maxHeight = 0;
    float2 bestUV = 0;
    float u = 0;
    bool found = false;
    
    // texel size with a sign depending on displacement
    float texelSignedSize = sign(-_RelativePosition) * _DepthTex_TexelSize.x;

    // displacement factor as in test 1
    float displacementFactor = _ParallaxAmount * -_RelativePosition * _DepthTex_TexelSize.x * 40;

    for (int itCount = 0; itCount < 40; itCount++) {
        // fetch each pixel in the selected row
        float2 currUV = i.uv + float2(u, 0);
        float currCellHeight = DecodeFloatRGBA(tex2D(_DepthTex, currUV));
        float currCelluDispl = currCellHeight * displacementFactor;
        // compute where the current fetched texel should be displaced
        float2 newUV = currUV + float2(currCelluDispl, 0);
        
        // if the fetched texel is in the bounds of current pixel
        // is a good candidate
        if (abs(newUV.x - i.uv.x) <= _DepthTex_TexelSize.x) {
            // if is the least deep pixel, is the best candidate until now
            if (currCellHeight >= maxHeight) {
                maxHeight = currCellHeight;
                bestUV = currUV;
                found = true;
            }
        }
        // iteration pass
        u -= texelSignedSize;
    }
    
    // if there is a good candidate paint the pixel from albedo.
    // in other case paint it pink
    return found ? gammaCorrect(tex2D(_MainTex, bestUV)) : float4(1.0, 0.0, 1.0, 1.0);
}
{% endhighlight %}

This aproach is considerably better than last one, here it is the results.

<div class="youtube-video" markdown="1">
  [![Test 1](https://img.youtube.com/vi/wDxo_LH5Wjs/0.jpg)](https://www.youtube.com/watch?v=wDxo_LH5Wjs){:target="_blank"}
</div>


# Parallax Test 1 
###### April 12, 2018

It is need make parallax in a plane image, it is needed to "move" pixels over the rendering surface.
To make this possible the first idea is to use a shader.

Two additional parameters are provided:
 1. Parallax Amount: how much a pixel should move taking in account its depth.
 2. Relative Position: simulated displacement of the camera on the x axis (at view space).

This parameters are choosen to get faster results and check the problems, in the future will be calculated realtime.

The vertex shader is not interesting for what concerns us.
The fragment shader is this: 

{% highlight glsl %}
float4 frag (v2f i) : SV_Target {
    // Getting depth form texture
    float h = DecodeFloatRGBA(tex2D(_DepthTex, i.uv));
    // Calculus of the displacement using decoded depth
    float uDisplacement = h * _ParallaxAmount * _RelativePosition * _DepthTex_TexelSize.x * 40;
    // Getting a pixel in the displaced direction.
    return gammaCorrect(tex2D(_MainTex, i.uv + float2(uDisplacement, 0)));
}
{% endhighlight %}

Obviously this is a bad aproach. The pixel is chosen taking in acount the current pixel height and not the other pixel height.
This is the visual result:

<div class="youtube-video" markdown="1">
  [![Test 1](https://img.youtube.com/vi/F6zIchbR1Rg/0.jpg)](https://www.youtube.com/watch?v=F6zIchbR1Rg){:target="_blank"}
</div>


# Objective of the project
###### April 9, 2018
The main objective is to reach 6 DOF in VR in 360 images using a few images to get it working. Parallax will be the main way to work.

### What is Parallax
If an observer take a picture and then move the camera (without rotation) to the right and take another picture, some objects or a part of 
them that appear in the first picture will be occluded by other objects. Comparing both pictures and taking the first as reference, 
the nearby elements are apparently more displaced in the second picture than the distant ones.
Thats because the human eye and cameras see as a persepective projection.

That phenomenon is called parallax.

[![Octocat](assets/images/parallax-example.gif)](https://imgur.com/gallery/TF1iHpr){:target="_blank"}

Parallax example from [imgur](https://imgur.com/gallery/TF1iHpr){:target="_blank"}

### Source images to work with
The source items to build it will be two images: the albedo and the depth map of the scene. 

In order to get clean tests, the images will be generated by a renderer (getting a perfect depth field image). 
In a late stage, when the parallax is working, the images will be replaced for real images to discover the problems of our method with them.

### The engine
To get faster results, a comercial engine will be used. The choosen one is Unity.
