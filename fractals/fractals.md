<script src="http://code.jquery.com/jquery-1.12.0.min.js"></script>
<script src="http://code.jquery.com/jquery-migrate-1.2.1.min.js"></script>
<script type="text/javascript">
//////////////////////////////////////////////////////////////////////////////
//
//  Angel.js
//
//////////////////////////////////////////////////////////////////////////////

//----------------------------------------------------------------------------
//
//  Helper functions
//

function _argumentsToArray( args )
{
    return [].concat.apply( [], Array.prototype.slice.apply(args) );
}

//----------------------------------------------------------------------------

function radians( degrees ) {
    return degrees * Math.PI / 180.0;
}

//----------------------------------------------------------------------------
//
//  Vector Constructors
//

function vec2()
{
    var result = _argumentsToArray( arguments );

    switch ( result.length ) {
    case 0: result.push( 0.0 );
    case 1: result.push( 0.0 );
    }

    return result.splice( 0, 2 );
}

function vec3()
{
    var result = _argumentsToArray( arguments );

    switch ( result.length ) {
    case 0: result.push( 0.0 );
    case 1: result.push( 0.0 );
    case 2: result.push( 0.0 );
    }

    return result.splice( 0, 3 );
}

function vec4()
{
    var result = _argumentsToArray( arguments );

    switch ( result.length ) {
    case 0: result.push( 0.0 );
    case 1: result.push( 0.0 );
    case 2: result.push( 0.0 );
    case 3: result.push( 1.0 );
    }

    return result.splice( 0, 4 );
}

//----------------------------------------------------------------------------
//
//  Matrix Constructors
//

function mat2()
{
    var v = _argumentsToArray( arguments );

    var m = [];
    switch ( v.length ) {
    case 0:
        v[0] = 1;
    case 1:
        m = [
            vec2( v[0],  0.0 ),
            vec2(  0.0, v[0] )
        ];
        break;

    default:
        m.push( vec2(v) );  v.splice( 0, 2 );
        m.push( vec2(v) );
        break;
    }

    m.matrix = true;

    return m;
}

//----------------------------------------------------------------------------

function mat3()
{
    var v = _argumentsToArray( arguments );

    var m = [];
    switch ( v.length ) {
    case 0:
        v[0] = 1;
    case 1:
        m = [
            vec3( v[0],  0.0,  0.0 ),
            vec3(  0.0, v[0],  0.0 ),
            vec3(  0.0,  0.0, v[0] )
        ];
        break;

    default:
        m.push( vec3(v) );  v.splice( 0, 3 );
        m.push( vec3(v) );  v.splice( 0, 3 );
        m.push( vec3(v) );
        break;
    }

    m.matrix = true;

    return m;
}

//----------------------------------------------------------------------------

function mat4()
{
    var v = _argumentsToArray( arguments );

    var m = [];
    switch ( v.length ) {
    case 0:
        v[0] = 1;
    case 1:
        m = [
            vec4( v[0], 0.0,  0.0,   0.0 ),
            vec4( 0.0,  v[0], 0.0,   0.0 ),
            vec4( 0.0,  0.0,  v[0],  0.0 ),
            vec4( 0.0,  0.0,  0.0,  v[0] )
        ];
        break;

    default:
        m.push( vec4(v) );  v.splice( 0, 4 );
        m.push( vec4(v) );  v.splice( 0, 4 );
        m.push( vec4(v) );  v.splice( 0, 4 );
        m.push( vec4(v) );
        break;
    }

    m.matrix = true;

    return m;
}

//----------------------------------------------------------------------------
//
//  Generic Mathematical Operations for Vectors and Matrices
//

function equal( u, v )
{
    if ( u.length != v.length ) { return false; }

    if ( u.matrix && v.matrix ) {
        for ( var i = 0; i < u.length; ++i ) {
            if ( u[i].length != v[i].length ) { return false; }
            for ( var j = 0; j < u[i].length; ++j ) {
                if ( u[i][j] !== v[i][j] ) { return false; }
            }
        }
    }
    else if ( u.matrix && !v.matrix || !u.matrix && v.matrix ) {
        return false;
    }
    else {
        for ( var i = 0; i < u.length; ++i ) {
            if ( u[i] !== v[i] ) { return false; }
        }
    }

    return true;
}

//----------------------------------------------------------------------------

function add( u, v )
{
    var result = [];

    if ( u.matrix && v.matrix ) {
        if ( u.length != v.length ) {
            throw "add(): trying to add matrices of different dimensions";
        }

        for ( var i = 0; i < u.length; ++i ) {
            if ( u[i].length != v[i].length ) {
                throw "add(): trying to add matrices of different dimensions";
            }
            result.push( [] );
            for ( var j = 0; j < u[i].length; ++j ) {
                result[i].push( u[i][j] + v[i][j] );
            }
        }

        result.matrix = true;

        return result;
    }
    else if ( u.matrix && !v.matrix || !u.matrix && v.matrix ) {
        throw "add(): trying to add matrix and non-matrix variables";
    }
    else {
        if ( u.length != v.length ) {
            throw "add(): vectors are not the same dimension";
        }

        for ( var i = 0; i < u.length; ++i ) {
            result.push( u[i] + v[i] );
        }

        return result;
    }
}

//----------------------------------------------------------------------------

function subtract( u, v )
{
    var result = [];

    if ( u.matrix && v.matrix ) {
        if ( u.length != v.length ) {
            throw "subtract(): trying to subtract matrices" +
                " of different dimensions";
        }

        for ( var i = 0; i < u.length; ++i ) {
            if ( u[i].length != v[i].length ) {
                throw "subtract(): trying to subtact matrices" +
                    " of different dimensions";
            }
            result.push( [] );
            for ( var j = 0; j < u[i].length; ++j ) {
                result[i].push( u[i][j] - v[i][j] );
            }
        }

        result.matrix = true;

        return result;
    }
    else if ( u.matrix && !v.matrix || !u.matrix && v.matrix ) {
        throw "subtact(): trying to subtact  matrix and non-matrix variables";
    }
    else {
        if ( u.length != v.length ) {
            throw "subtract(): vectors are not the same length";
        }

        for ( var i = 0; i < u.length; ++i ) {
            result.push( u[i] - v[i] );
        }

        return result;
    }
}

//----------------------------------------------------------------------------

function mult( u, v )
{
    var result = [];

    if ( u.matrix && v.matrix ) {
        if ( u.length != v.length ) {
            throw "mult(): trying to add matrices of different dimensions";
        }

        for ( var i = 0; i < u.length; ++i ) {
            if ( u[i].length != v[i].length ) {
                throw "mult(): trying to add matrices of different dimensions";
            }
        }

        for ( var i = 0; i < u.length; ++i ) {
            result.push( [] );

            for ( var j = 0; j < v.length; ++j ) {
                var sum = 0.0;
                for ( var k = 0; k < u.length; ++k ) {
                    sum += u[i][k] * v[k][j];
                }
                result[i].push( sum );
            }
        }

        result.matrix = true;

        return result;
    }
    else {
        if ( u.length != v.length ) {
            throw "mult(): vectors are not the same dimension";
        }

        for ( var i = 0; i < u.length; ++i ) {
            result.push( u[i] * v[i] );
        }

        return result;
    }
}

//----------------------------------------------------------------------------
//
//  Basic Transformation Matrix Generators
//

function translate( x, y, z )
{
    if ( Array.isArray(x) && x.length == 3 ) {
        z = x[2];
        y = x[1];
        x = x[0];
    }

    var result = mat4();
    result[0][3] = x;
    result[1][3] = y;
    result[2][3] = z;

    return result;
}

//----------------------------------------------------------------------------

function rotate( angle, axis )
{
    if ( !Array.isArray(axis) ) {
        axis = [ arguments[1], arguments[2], arguments[3] ];
    }

    var v = normalize( axis );

    var x = v[0];
    var y = v[1];
    var z = v[2];

    var c = Math.cos( radians(angle) );
    var omc = 1.0 - c;
    var s = Math.sin( radians(angle) );

    var result = mat4(
        vec4( x*x*omc + c,   x*y*omc - z*s, x*z*omc + y*s, 0.0 ),
        vec4( x*y*omc + z*s, y*y*omc + c,   y*z*omc - x*s, 0.0 ),
        vec4( x*z*omc - y*s, y*z*omc + x*s, z*z*omc + c,   0.0 ),
        vec4()
    );

    return result;
}

//----------------------------------------------------------------------------

function scale( x, y, z )
{
    if ( Array.isArray(x) && x.length == 3 ) {
        z = x[2];
        y = x[1];
        x = x[0];
    }

    var result = mat4();
    result[0][0] = x;
    result[1][1] = y;
    result[2][2] = z;

    return result;
}

//----------------------------------------------------------------------------
//
//  ModelView Matrix Generators
//

function lookAt( eye, at, up )
{
    if ( !Array.isArray(eye) || eye.length != 3) {
        throw "lookAt(): first parameter [eye] must be an a vec3";
    }

    if ( !Array.isArray(at) || at.length != 3) {
        throw "lookAt(): first parameter [at] must be an a vec3";
    }

    if ( !Array.isArray(up) || up.length != 3) {
        throw "lookAt(): first parameter [up] must be an a vec3";
    }

    if ( equal(eye, at) ) {
        return mat4();
    }

    var v = normalize( subtract(at, eye) );  // view direction vector
    var n = normalize( cross(v, up) );       // perpendicular vector
    var u = normalize( cross(n, v) );        // "new" up vector

    v = negate( v );

    var result = mat4(
        vec4( n, -dot(n, eye) ),
        vec4( u, -dot(u, eye) ),
        vec4( v, -dot(v, eye) ),
        vec4()
    );

    return result;
}

//----------------------------------------------------------------------------
//
//  Projection Matrix Generators
//

function ortho( left, right, bottom, top, near, far )
{
    if ( left == right ) { throw "ortho(): left and right are equal"; }
    if ( bottom == top ) { throw "ortho(): bottom and top are equal"; }
    if ( near == far )   { throw "ortho(): near and far are equal"; }

    var w = right - left;
    var h = top - bottom;
    var d = far - near;

    var result = mat4();
    result[0][0] = 2.0 / w;
    result[1][1] = 2.0 / h;
    result[2][2] = -2.0 / d;
    result[0][3] = (left + right) / w;
    result[1][3] = (top + bottom) / h;
    result[2][3] = (near + far) / d;

    return result;
}

//----------------------------------------------------------------------------

function perspective( fovy, aspect, near, far )
{
    var f = 1.0 / Math.tan( radians(fovy) / 2 );
    var d = far - near;

    var result = mat4();
    result[0][0] = f / aspect;
    result[1][1] = f;
    result[2][2] = -(near + far) / d;
    result[2][3] = -2 * near * far / d;
    result[3][2] = -1;
    result[3][3] = 0.0;

    return result;
}

//----------------------------------------------------------------------------
//
//  Matrix Functions
//

function transpose( m )
{
    if ( !m.matrix ) {
        return "transpose(): trying to transpose a non-matrix";
    }

    var result = [];
    for ( var i = 0; i < m.length; ++i ) {
        result.push( [] );
        for ( var j = 0; j < m[i].length; ++j ) {
            result[i].push( m[j][i] );
        }
    }

    result.matrix = true;

    return result;
}

//----------------------------------------------------------------------------
//
//  Vector Functions
//

function dot( u, v )
{
    if ( u.length != v.length ) {
        throw "dot(): vectors are not the same dimension";
    }

    var sum = 0.0;
    for ( var i = 0; i < u.length; ++i ) {
        sum += u[i] * v[i];
    }

    return sum;
}

//----------------------------------------------------------------------------

function negate( u )
{
    result = [];
    for ( var i = 0; i < u.length; ++i ) {
        result.push( -u[i] );
    }

    return result;
}

//----------------------------------------------------------------------------

function cross( u, v )
{
    if ( !Array.isArray(u) || u.length < 3 ) {
        throw "cross(): first argument is not a vector of at least 3";
    }

    if ( !Array.isArray(v) || v.length < 3 ) {
        throw "cross(): second argument is not a vector of at least 3";
    }

    var result = [
        u[1]*v[2] - u[2]*v[1],
        u[2]*v[0] - u[0]*v[2],
        u[0]*v[1] - u[1]*v[0]
    ];

    return result;
}

//----------------------------------------------------------------------------

function length( u )
{
    return Math.sqrt( dot(u, u) );
}

//----------------------------------------------------------------------------

function normalize( u, excludeLastComponent )
{
    if ( excludeLastComponent ) {
        var last = u.pop();
    }

    var len = length( u );

    if ( !isFinite(len) ) {
        throw "normalize: vector " + u + " has zero length";
    }

    for ( var i = 0; i < u.length; ++i ) {
        u[i] /= len;
    }

    if ( excludeLastComponent ) {
        u.push( last );
    }

    return u;
}

//----------------------------------------------------------------------------

function mix( u, v, s )
{
    if ( typeof s !== "number" ) {
        throw "mix: the last paramter " + s + " must be a number";
    }

    if ( u.length != v.length ) {
        throw "vector dimension mismatch";
    }

    var result = [];
    for ( var i = 0; i < u.length; ++i ) {
        result.push( s * u[i] + (1.0 - s) * v[i] );
    }

    return result;
}

//----------------------------------------------------------------------------
//
// Vector and Matrix functions
//

function scale( s, u )
{
    if ( !Array.isArray(u) ) {
        throw "scale: second parameter " + u + " is not a vector";
    }

    result = [];
    for ( var i = 0; i < u.length; ++i ) {
        result.push( s * u[i] );
    }

    return result;
}

//----------------------------------------------------------------------------
//
//
//

function flatten( v )
{
    if ( v.matrix === true ) {
        v = transpose( v );
    }

    var n = v.length;
    var elemsAreArrays = false;

    if ( Array.isArray(v[0]) ) {
        elemsAreArrays = true;
        n *= v[0].length;
    }

    var floats = new Float32Array( n );

    if ( elemsAreArrays ) {
        var idx = 0;
        for ( var i = 0; i < v.length; ++i ) {
            for ( var j = 0; j < v[i].length; ++j ) {
                floats[idx++] = v[i][j];
            }
        }
    }
    else {
        for ( var i = 0; i < v.length; ++i ) {
            floats[i] = v[i];
        }
    }

    return floats;
}

//----------------------------------------------------------------------------

var sizeof = {
    'vec2' : new Float32Array( flatten(vec2()) ).byteLength,
    'vec3' : new Float32Array( flatten(vec3()) ).byteLength,
    'vec4' : new Float32Array( flatten(vec4()) ).byteLength,
    'mat2' : new Float32Array( flatten(mat2()) ).byteLength,
    'mat3' : new Float32Array( flatten(mat3()) ).byteLength,
    'mat4' : new Float32Array( flatten(mat4()) ).byteLength
};
//
//  initShaders.js
//

function initShaders( gl, vertexShaderId, fragmentShaderId )
{
    var vertShdr;
    var fragShdr;

    var vertElem = document.getElementById( vertexShaderId );
    if ( !vertElem ) {
        alert( "Unable to load vertex shader " + vertexShaderId );
        return -1;
    }
    else {
        vertShdr = gl.createShader( gl.VERTEX_SHADER );
        gl.shaderSource( vertShdr, vertElem.text );
        gl.compileShader( vertShdr );
        if ( !gl.getShaderParameter(vertShdr, gl.COMPILE_STATUS) ) {
            var msg = "Vertex shader failed to compile.  The error log is:"
          + "<pre>" + gl.getShaderInfoLog( vertShdr ) + "</pre>";
            alert( msg );
            return -1;
        }
    }

    var fragElem = document.getElementById( fragmentShaderId );
    if ( !fragElem ) {
        alert( "Unable to load vertex shader " + fragmentShaderId );
        return -1;
    }
    else {
        fragShdr = gl.createShader( gl.FRAGMENT_SHADER );
        gl.shaderSource( fragShdr, fragElem.text );
        gl.compileShader( fragShdr );
        if ( !gl.getShaderParameter(fragShdr, gl.COMPILE_STATUS) ) {
            var msg = "Fragment shader failed to compile.  The error log is:"
          + "<pre>" + gl.getShaderInfoLog( fragShdr ) + "</pre>";
            alert( msg );
            return -1;
        }
    }

    var program = gl.createProgram();
    gl.attachShader( program, vertShdr );
    gl.attachShader( program, fragShdr );
    gl.linkProgram( program );

    if ( !gl.getProgramParameter(program, gl.LINK_STATUS) ) {
        var msg = "Shader program failed to link.  The error log is:"
            + "<pre>" + gl.getProgramInfoLog( program ) + "</pre>";
        alert( msg );
        return -1;
    }

    return program;
}
/*
 * Copyright 2010, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


/**
 * @fileoverview This file contains functions every webgl program will need
 * a version of one way or another.
 *
 * Instead of setting up a context manually it is recommended to
 * use. This will check for success or failure. On failure it
 * will attempt to present an approriate message to the user.
 *
 *       gl = WebGLUtils.setupWebGL(canvas);
 *
 * For animated WebGL apps use of setTimeout or setInterval are
 * discouraged. It is recommended you structure your rendering
 * loop like this.
 *
 *       function render() {
 *         window.requestAnimFrame(render, canvas);
 *
 *         // do rendering
 *         ...
 *       }
 *       render();
 *
 * This will call your rendering function up to the refresh rate
 * of your display but will stop rendering if your app is not
 * visible.
 */

WebGLUtils = function() {

/**
 * Creates the HTLM for a failure message
 * @param {string} canvasContainerId id of container of th
 *        canvas.
 * @return {string} The html.
 */
var makeFailHTML = function(msg) {
  return '' +
    '<table style="background-color: #8CE; width: 100%; height: 100%;"><tr>' +
    '<td align="center">' +
    '<div style="display: table-cell; vertical-align: middle;">' +
    '<div style="">' + msg + '</div>' +
    '</div>' +
    '</td></tr></table>';
};

/**
 * Mesasge for getting a webgl browser
 * @type {string}
 */
var GET_A_WEBGL_BROWSER = '' +
  'This page requires a browser that supports WebGL.<br/>' +
  '<a href="http://get.webgl.org">Click here to upgrade your browser.</a>';

/**
 * Mesasge for need better hardware
 * @type {string}
 */
var OTHER_PROBLEM = '' +
  "It doesn't appear your computer can support WebGL.<br/>" +
  '<a href="http://get.webgl.org/troubleshooting/">Click here for more information.</a>';

/**
 * Creates a webgl context. If creation fails it will
 * change the contents of the container of the <canvas>
 * tag to an error message with the correct links for WebGL.
 * @param {Element} canvas. The canvas element to create a
 *     context from.
 * @param {WebGLContextCreationAttirbutes} opt_attribs Any
 *     creation attributes you want to pass in.
 * @return {WebGLRenderingContext} The created context.
 */
var setupWebGL = function(canvas, opt_attribs) {
  function showLink(str) {
    var container = canvas.parentNode;
    if (container) {
      container.innerHTML = makeFailHTML(str);
    }
  };

  if (!window.WebGLRenderingContext) {
    showLink(GET_A_WEBGL_BROWSER);
    return null;
  }

  var context = create3DContext(canvas, opt_attribs);
  if (!context) {
    showLink(OTHER_PROBLEM);
  }
  return context;
};

/**
 * Creates a webgl context.
 * @param {!Canvas} canvas The canvas tag to get context
 *     from. If one is not passed in one will be created.
 * @return {!WebGLContext} The created context.
 */
var create3DContext = function(canvas, opt_attribs) {
  var names = ["webgl", "experimental-webgl", "webkit-3d", "moz-webgl"];
  var context = null;
  for (var ii = 0; ii < names.length; ++ii) {
    try {
      context = canvas.getContext(names[ii], opt_attribs);
    } catch(e) {}
    if (context) {
      break;
    }
  }
  return context;
}

return {
  create3DContext: create3DContext,
  setupWebGL: setupWebGL
};
}();

/**
 * Provides requestAnimationFrame in a cross browser way.
 */
window.requestAnimFrame = (function() {
  return window.requestAnimationFrame ||
         window.webkitRequestAnimationFrame ||
         window.mozRequestAnimationFrame ||
         window.oRequestAnimationFrame ||
         window.msRequestAnimationFrame ||
         function(/* function FrameRequestCallback */ callback, /* DOMElement Element */ element) {
           window.setTimeout(callback, 1000/60);
         };
})();
</script>


Fractals and WebGL
==================

Ok, so this is might be a ['rule 10'](https://blog.spawar.navy.mil/tschlosser/2007/06/proposed-rules-for-bloggers.html) post. It's not about programming language features for cybersecurity or anything practical like that. Instead, I decided to write a post on a small subset of the cool stuff you can do with [WebGL](https://en.wikipedia.org/wiki/WebGL)---an in-browser implementation of [OpenGL ES 2.0](https://en.wikipedia.org/wiki/OpenGL_ES).

**Disclaimer:** This is not meant to be an OpenGL tutorial. I'll try to mention just a minimal amount of OpenGL boilerplate stuff to get us all on the same page. If you are interested in learning OpenGL there are many good tutorials online. I think that [this one](http://learningwebgl.com/blog/) is pretty good especially if you are going for the WebGL variant.

I'm not going to be doing any 3d graphics stuff this time around. Instead, I'm going to set up some very minimal scaffolding to send four vertices to the [vertex shader](https://www.opengl.org/wiki/Vertex_Shader) which will define a canvas on which we can use the [fragment shader](https://www.opengl.org/wiki/Fragment_Shader) to draw on.

The fragment shader gives us the ability to specify the color for each pixel on the canvas. So, what are we going to draw? [Fractals](https://en.wikipedia.org/wiki/Fractal) of course!

Why? Well, first of all, they are really cool. Second, they can be pretty computationally expensive so they really show off the massive parallelism you can exploit on the GPU.

On the off chance that someone reading this doesn't know what a [fractal](https://en.wikipedia.org/wiki/Fractal) is, let's just say that a fractal is a self similar structure. How similar? Well, it turns out that there can be a bit of flexibility on that.

####Geometric fractals####

Let's start with a simple "geometric fractal". Below you see a triangle. If you click on the 'increase' button, it will draw another triangle inside of it which makes three more triangles around the corners of the original. Click it again and each of those will get a triangle inside of them and so on. Go ahead and play around with it. (Note: this is not using WebGL. This one is so simple I opted to implement it on a 2d html5 canvas.)

#####Sierpinski's Triangle#####

<canvas class="triangle" width=400 height=410></canvas><br/>
<button class="triangle-up">increase</button>
<button class="triangle-down">decrease</button>
<label  class="triangle-label">iterations = 0</label>

<script>
function rotate(rotate_point, pivot_point, theta) {
  var translated = {x: rotate_point.x - pivot_point.x, y: rotate_point.y - pivot_point.y};

  var result_point = {
    x: translated.x * Math.cos(theta) - translated.y * Math.sin(theta),
    y: translated.x * Math.sin(theta) + translated.y * Math.cos(theta)
  };
  return {x: result_point.x + pivot_point.x, y: result_point.y + pivot_point.y};
}

var fillStyle = '#ecffff';

(function() {
  var canvas        = $("canvas.triangle")[0];
  var ctx           = canvas.getContext('2d');
  var triButtonUp   = $("button.triangle-up");
  var triButtonDown = $("button.triangle-down");
  var triLabel      = $("label.triangle-label")[0];
  var scalar        = window.devicePixelRatio || 1;

  canvas.style.width  = canvas.width  + "px";
  canvas.style.height = canvas.height + "px";
  canvas.width        = canvas.width  * scalar;
  canvas.height       = canvas.height * scalar;

  var triIterations = 0;

  var p1 = {x: canvas.width * 0.1, y: canvas.height * 0.75};
  var p2 = {x: canvas.width * 0.9, y: canvas.height * 0.75};
  var p3 = rotate(p2, p1, -Math.PI / 3);

  var drawTriangle1 = function(p1, p2, p3) {
    ctx.beginPath();
    ctx.moveTo(p1.x, p1.y);
    ctx.lineTo(p2.x, p2.y);
    ctx.lineTo(p3.x, p3.y);
    ctx.lineTo(p1.x, p1.y);
    ctx.stroke();
    ctx.fill();
    ctx.closePath();
  }

  var midpoint = function(p1, p2) {
    return {
      x: p1.x - (p1.x - p2.x)/2,
      y: p1.y - (p1.y - p2.y)/2
    }
  }

  var drawSierpinsky = function(p1, p2, p3, triIterations) {
    if (triIterations <= 0) {
      drawTriangle1(p1, p2, p3);
      return;
    }

    drawSierpinsky(midpoint(p1, p2), p2, midpoint(p2, p3), triIterations - 1);
    drawSierpinsky(p1, midpoint(p1, p2), midpoint(p1, p3), triIterations - 1);
    drawSierpinsky(midpoint(p1, p3), midpoint(p2, p3), p3, triIterations - 1);
  }

  var triRender = function() {
    drawSierpinsky(p1, p2, p3, triIterations);
  }

  ctx.fillStyle = fillStyle;

  triButtonUp.on('click', function() {
    if (triIterations < 8) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ++triIterations;
      triLabel.innerHTML = "iterations = " + triIterations;
      triRender();
    }
  });

  triButtonDown.on('click', function() {
    if (triIterations > 0) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      --triIterations;
      triLabel.innerHTML = "iterations = " + triIterations;
      triRender();
    }
  });

  triRender();
})()
</script>

This is known as the [Sierpinski Triangle](https://en.wikipedia.org/wiki/Sierpinski_triangle). There are a bunch of other geometric fractals we could explore, but lets move on to some more complicated and interesting ones.


#####Koch Snowflake#####

<canvas class="snowflake" width=500 height=500></canvas><br/>
<button class="snowflake-up">increase</button>
<button class="snowflake-down">decrease</button>
<label  class="snowflake-label">iterations = 0</label>

<script>
(function() {
  var canvas = $("canvas.snowflake")[0];
  var ctx = canvas.getContext('2d');
  var snowButtonUp = $("button.snowflake-up");
  var snowButtonDown = $("button.snowflake-down");
  var label = $("label.snowflake-label")[0];
  var scalar = window.devicePixelRatio || 1;

  canvas.style.width  = canvas.width  + "px";
  canvas.style.height = canvas.height + "px";

  canvas.width  = canvas.width  * scalar;
  canvas.height = canvas.height * scalar;

  var iterations = 0;

  var midpoints = function(p1, p2) {
    return [{
      x: p1.x - (p1.x - p2.x)/3,
      y: p1.y - (p1.y - p2.y)/3
    }, {
      x: p1.x - 2*(p1.x - p2.x)/3,
      y: p1.y - 2*(p1.y - p2.y)/3
    }];
  }

  var drawFractal = function(p1, p2, p3, iterations) {
    var drawLineFractal = function(p1, p2, iterations) {
      if (iterations <= 0) {
        ctx.lineTo(p2.x, p2.y);
        return;
      }

      var mps, mp1, mp2, tp;
      mps = midpoints(p1, p2);
      mp1 = mps[0];
      mp2 = mps[1];

      tp = rotate(mp2, mp1, Math.PI / 3);

      drawLineFractal(p1, mp1, iterations - 1);
      drawLineFractal(mp1, tp, iterations - 1);
      drawLineFractal(tp, mp2, iterations - 1);
      drawLineFractal(mp2, p2, iterations - 1);
    }

    drawLineFractal(p1, p2, iterations);
    drawLineFractal(p2, p3, iterations);
    drawLineFractal(p3, p1, iterations);
  }

  var p1 = {x: canvas.width * 0.1, y: canvas.height * 0.75};
  var p2 = {x: canvas.width * 0.9, y: canvas.height * 0.75};

  p3 = rotate(p2, p1, -Math.PI / 3);

  var snowRender = function() {
    ctx.beginPath();
    ctx.moveTo(p1.x, p2.y);
    drawFractal(p1, p2, p3, iterations);
    ctx.stroke();
    ctx.closePath();
    ctx.fill();
  }

  ctx.fillStyle = fillStyle;
  snowRender();

  snowButtonUp.on('click', function() {
    if (iterations < 8) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ++iterations;
      label.innerHTML = "iterations = " + iterations;
      snowRender();

    }
  });

  snowButtonDown.on('click', function() {
    if (iterations > 0) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      --iterations;
      label.innerHTML = "iterations = " + iterations;
      snowRender();
    }
  });
})()
</script>


####Gratuitous Mandelbrot set fractal: ####

Whenever you hear about fractals (at least non-geometric fractals), chances are you hear about the [Mandelbrot set](https://en.wikipedia.org/wiki/Mandelbrot_set).


<canvas id="gl-canvas" class="mandelbrot">
Oops ... your browser doesn't support the HTML5 canvas element
</canvas>

<script type="x-vertex/x-vertex" id="mandelbrot-vertex">
  attribute vec4 vPosition;
  varying vec2 pos;
  void main()
  {
    gl_Position = vPosition;
  }
</script>

<script type="x-shader/x-fragment" id="mandelbrot-fragment">
#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#endif

uniform float cRe;
uniform float cIm;
uniform float minX;
uniform float maxX;
uniform float minY;
uniform float width;
uniform float max;
uniform vec2  power;

// Complex math operations
#define complexMult(a,b)       vec2((a).x*(b).x - (a).y*(b).y, (a).x*(b).y + (a).y*(b).x)
#define complexMag(z)          float(pow(length(z), 2.0))
#define complexReciprocal(z)   vec2((z).x / complexMag(z), -(z).y / complexMag(z))
#define complexDivision(a,b)   complexMult(a, complexReciprocal(b))
#define complexArg(z)          float(atan((z).y, (z).x))
#define complexLog(z)          vec2(log(length(z)), complexArg(z))
#define complexExp(z)          vec2(exp((z).x) * cos((z).y), exp((z).x) * sin((z).y))
#define sinh(x)                float((exp(x) - exp(-x)) / 2.0)
#define cosh(x)                float((exp(x) + exp(-x)) / 2.0)
#define complexSin(z)          vec2(sin((z).x) * cosh((z).y),  cos((z).x) * sinh((z).y))
#define complexCos(z)          vec2(cos((z).x) * cosh((z).y), -sin((z).x) * sinh((z).y))
#define complexTan(z)          vec2(sin(2.0 * (z).x)/(cos(2.0 * (z).x) + cosh(2.0 * (z).y)), sinh(2.0 * (z).y)/(cos(2.0 * (z).x) + cosh(2.0 * (z).y)))
#define complexSinh(z)         vec2(sinh((z).x) * cos((z).y), cosh((z).x) * sin((z).y))
#define complexCosh(z)         vec2(cosh((z).x) * cos((z).y), sinh((z).x) * sin((z).y))
#define complexTanh(z)         vec2(sinh(2.0 * (z).x)/(cosh(2.0 * (z).x) + cos(2.0 * (z).y)), sin(2.0 * (z).y)/(cosh(2.0 * (z).x) + cos(2.0 * (z).y)))
#define polar(r,a)             vec2(cos(a) * r, sin(a) * r)
#define complexPower(z,p)      vec2(polar(pow(length(z), float(p)), float(p) * complexArg(z)))
#define complexPower2(z, p)    vec2(complexExp(complexMult(p, complexLog(z))))

vec3 julia( float x, float y ) {
    float z = 0.0;
    float xtemp;
    vec2  c  = vec2( cRe, cIm );
    vec2  xy = vec2( x, y );
    float thresh = 0.01;
                       // NOTE: this is not the real max. The value of the loop
                       // comparison must be determined at compile time in GLSL ¯\_(ツ)_/¯
    for(float z = 0.0; z < 100000.0; z++)
    {
        // vec2 tmp = xy - complexDivision( (complexPower(xy, 3) + vec2(2, -1.5)), complexMult(vec2(3,0), complexPower(xy, 2)) );


        // vec2 tmp = xy - complexDivision( ((complexPower(xy, 3) + vec2(2, -1.5)) + c * xy), (complexMult(vec2(3,0), complexPower(xy, 2)) + c) );


        vec2 tmp = xy - complexDivision( ((complexPower(xy, 3) + vec2(2, -1.5)) + 3.0 * xy), complexMult(3.0 * complexPower(xy, 2) + 3.0, vec2(1, 1)) );




        // vec2 tmp = xy - complexDivision( (complexPower(xy, 3) + c), complexMult(vec2(3,0), complexPower(xy, 2)) );
        // vec2 tmp = xy - complexDivision( (complexPower(xy, 3) + complexMult(vec2(2,0), xy) + complexPower(c, 10)), complexMult(complexMult(vec2(3,0), complexPower(xy, 2)), vec2(0.5,0.4)) );
        // vec2 tmp = xy - complexDivision(
        //     (complexPower(xy, 3) + complexMult(vec2(2,0), xy) + complexPower(c, 10)),
        //     (complexMult(vec2(0.5,-3), complexPower(xy, 2)) + vec2(2,0))
        // );

        // vec2 tmp = xy - complexDivision( (complexExp(xy) - c), complexExp(xy) );
        // vec2 tmp = xy - complexDivision( (complexSinh(xy) - c), complexCosh(xy) );
        // vec2 tmp = xy - complexMult( c, complexDivision( (complexPower(xy, power.y) - 3.0 * xy),
        //                                  (power.y * complexPower(xy, power.y - 1.0) - 3.0) ) );

        // vec2 tmp = xy - complexDivision( (complexPower2(xy, power) - c),
        //   (complexMult( (power * (power - 0.1)), complexPower(xy, power - 2.0) ) ) );


        // vec2 tmp = xy - complexDivision( (complexPower2(xy, power) - c - complexSin(xy) ),
        //                                  ( (complexMult( power, complexPower(xy, power - 1.0) ) ) - complexCos(xy) ) );
        // vec2 tmp = xy - complexMult( c, complexDivision( (complexPower(xy, power.x) - 1.0),
        //                                  (power.x * complexPower(xy, power.x - 1.0)) ) );
        // z = i;
        if ( abs(complexMag( tmp - xy) ) < thresh || z >= max ) break;
        xy = tmp;
        // if(complexMag(xy) > 4.0 || i >= max) break;
        // z = i;
    }
    return vec3(xy.x, xy.y, z);
}

const float MAX = 100.0;
float mandelbrot(float fx, float fy) {
  float iteration  = 0.0;
  float x          = 0.0;
  float y          = 0.0;
  float xtemp      = 0.0;

  for ( float i = 0.0; i < MAX; ++i  )
  {
    if ( sqrt(x * x + y * y) <= 4.0 ) {
      xtemp = x * x - y * y + fx;
      y = 2.0 * x * y + fy;
      x = xtemp;
      iteration = i;
    }
    else{ break; }
  }
  return iteration;
}

float affine( float i, float x, float I, float o, float O)
{
    return ((x - i) / (I - i)) * (O - o) + o;
}

vec4 hsvToRgb(float h, float s, float v)
{
    float r, g, b;

    float i = floor(h * 6.0);
    float f = h * 6.0 - i;
    float p = v * (1.0 - s);
    float q = v * (1.0 - f * s);
    float t = v * (1.0 - (1.0 - f) * s);
    float j = mod(i, 6.0);

    if ( j == 0.0 ) return vec4( v, t, p, 1.0 );
    if ( j == 1.0 ) return vec4( q, v, p, 1.0 );
    if ( j == 2.0 ) return vec4( p, v, t, 1.0 );
    if ( j == 3.0 ) return vec4( p, q, v, 1.0 );
    if ( j == 4.0 ) return vec4( t, p, v, 1.0 );
    if ( j == 5.0 ) return vec4( v, p, q, 1.0 );

    return vec4( 1.0, 1.0, 1.0, 1.0 );
}

vec4 getcolor(float z)
{
  if (z == max - 1.0) return vec4(0,0,0,1);
  z/=max;
  float r = z + z > 1.0 ? 1.0 / (z + z) : z + z;
  float g = z     > 1.0 ? 1.0 / (z * z) : z;
  float b = z     > 1.0 ? 1.0 / z       : z * z;
  return vec4(r, g, b, 1.0);
}

// vec4 getcolor(vec3 xyz)
// {
//     float z = xyz.z / max;
//     // if ( z < 0.02 ) return vec4( xyz.x, xyz.x, xyz.x, z );
//     vec4 grey = vec4( z, z, z, 1 );
//     // return grey + vec4( xyz.xy/max, (xyz.x + xyz.y)/max, 1 );
//     return grey + hsvToRgb( xyz.y, 0.7, 0.5 );
// }

void main()
{
    float current_scale = (maxX - minX) / width;
    float x       = (gl_FragCoord.x * current_scale) + minX;
    float y       = (gl_FragCoord.y * current_scale) + minY;

    gl_FragColor = getcolor( mandelbrot( x, y ) );
}

</script>

<script type="text/javascript">
(function() {
  var canvas                               ,
      gl                                   ,
      program                              ,
      vBuff                                ,
      vPosition                            ,
      cxPosition                           ,
      cyPosition                           ,
      minXposition                         ,
      maxXposition                         ,
      minYposition                         ,
      WIDTH                                ,
      re_label                             ,
      im_label                             ,
      f2, f3, f4, f5                       ,
      power_label                          ,
      power      = vec2(2, 0)              ,
      x_factor   = 1                       ,
      y_factor   = 1                       ,
      hslMode    = false                   ,
      m_down     = false                   ,
      zoom_step  = 1-1e-1                  ,
      first      = true                    ,
      scale      =  1.9                    ,
      cx         =  0                      ,
      cy         =  0                      ,
      cRe        = -0.7                    ,
      cIm        =  0.27015                ,
      ox         = cx                      ,
      oy         = cy                      ,
      iterations = 100                     ,
      minX       = cx - (x_factor * scale) ,
      maxX       = cx + (x_factor * scale) ,
      minY       = cy - (y_factor * scale) ;

  window.onload      = init;
  window.onresize    = init;
  window.onkeydown   = handle_on_key_down;

  function init()
  {
      if (first) canvas = $("canvas.mandelbrot")[0];
      if (first) power_label = document.getElementById( "power" );
      var maxHeight = window.innerHeight * 0.9;
      var maxWidth  = window.innerWidth * 0.9;
      var dimension = maxHeight < maxWidth ? maxHeight : maxWidth;
      var pixelRatio = window.devicePixelRatio || 1;

      canvas.style.width  = dimension + "px";
      canvas.style.height = dimension + "px";

      canvas.width = canvas.clientWidth * pixelRatio;
      canvas.height = canvas.clientHeight * pixelRatio;
      WIDTH  = canvas.width;

      canvas.onmousedown = handle_mouse_down;
      canvas.onmouseup   = function () { m_down = false; };
      canvas.onmousemove = handle_mouse_move;

      canvas.onmousewheel = handleWheel;
      if (first)
      {

          gl = WebGLUtils.setupWebGL( canvas );
          if ( !gl ) { alert( "WebGL isn't available" ); }

          //  Load shaders and initialize attribute buffers
          program = initShaders( gl, "mandelbrot-vertex", "mandelbrot-fragment" );
          gl.useProgram( program );

          vBuff          = gl.createBuffer();
          vPosition      = gl.getAttribLocation ( program, "vPosition" );
          cxPosition     = gl.getUniformLocation( program, "cRe"       );
          cyPosition     = gl.getUniformLocation( program, "cIm"       );
          minXposition   = gl.getUniformLocation( program, "minX"      );
          maxXposition   = gl.getUniformLocation( program, "maxX"      );
          minYposition   = gl.getUniformLocation( program, "minY"      );
          widthPosition  = gl.getUniformLocation( program, "width"     );
          iterPosition   = gl.getUniformLocation( program, "max"       );
          hslPosition    = gl.getUniformLocation( program, "hslMode"   );
          powerPosition  = gl.getUniformLocation( program, "power"     );
      }
      first = false;

      re_label = document.getElementById( "re_label" );
      im_label = document.getElementById( "im_label" );
      f2       = document.getElementById( "f2" );
      f3       = document.getElementById( "f3" );
      f4       = document.getElementById( "f4" );
      f5       = document.getElementById( "f5" );

      points = [
        vec2( -1,  1 ),
        vec2( -1, -1 ),
        vec2(  1, -1 ),
        vec2(  1,  1 )
      ]

      gl.viewport( 0, 0, canvas.width, canvas.height );
      gl.clearColor( 1, 1, 1, 1.0 );

      gl.bindBuffer( gl.ARRAY_BUFFER, vBuff );
      gl.bufferData( gl.ARRAY_BUFFER, flatten(points), gl.STATIC_DRAW );
      gl.enableVertexAttribArray( vPosition );
      gl.vertexAttribPointer( vPosition, 2, gl.FLOAT, false, 0, 0);
      gl.uniform1f( widthPosition , canvas.width  );
      gl.uniform1f( iterPosition, iterations );
      gl.uniform1i( hslPosition, hslMode );

      render()
  }

  function render ()
  {
    gl.clear     ( gl.COLOR_BUFFER_BIT     );
    gl.uniform1f ( cxPosition      , cRe   );
    gl.uniform1f ( cyPosition      , cIm   );
    gl.uniform1f ( minXposition    , minX  );
    gl.uniform1f ( maxXposition    , maxX  );
    gl.uniform1f ( minYposition    , minY  );
    gl.uniform2fv( powerPosition   , power );
    gl.bindBuffer( gl.ARRAY_BUFFER , vBuff );
    gl.drawArrays( gl.TRIANGLE_FAN , 0, points.length );
  }

  function handleWheel( e )
  {
    var s = e.wheelDelta;
    scale = s > 0 ? scale * 0.95: scale / 0.95;
    setWindow()
    render()
    return false;
  }

  function handle_on_key_down( e )
  {
    var x = document.activeElement;
    switch ( e.keyCode )
    {
      /* up */ case 38: u_pressed  = true; handle_up    ( e ); return false;
      /* dn */ case 40: d_pressed  = true; handle_down  ( e ); return false;
      /* lf */ case 39: r_pressed  = true; handle_right ( e ); return false;
      /* rt */ case 37: l_pressed  = true; handle_left  ( e ); return false;
      /*  1 */ case 49: iterations =  100;  gl.uniform1f( iterPosition, iterations ); render(); break;
      /*  2 */ case 50: iterations =  200;  gl.uniform1f( iterPosition, iterations ); render(); break;
      /*  3 */ case 51: iterations =  500;  gl.uniform1f( iterPosition, iterations ); render(); break;
      /*  4 */ case 52: iterations = 1000;  gl.uniform1f( iterPosition, iterations ); render(); break;
      /*  5 */ case 53: iterations = 2000;  gl.uniform1f( iterPosition, iterations ); render(); break;
      /*  6 */ case 54: iterations = 8000;  gl.uniform1f( iterPosition, iterations ); render(); break;
      /*  - */ case 189: iterations -= 100; gl.uniform1f( iterPosition, iterations ); render(); break;
      /*  + */ case 187: iterations += 100; gl.uniform1f( iterPosition, iterations ); render(); break;
    }
  }

  function handle_up( e )
  {
    if ( e.shiftKey ) scale *= zoom_step;
    else   cy += 0.1 * scale;
    setWindow();
    render();
  }
  function handle_down( e )
  {
    if ( e.shiftKey ) scale /= zoom_step;
    else cy -= 0.1 * scale;
    setWindow();
    render();
  }
  function handle_right( e )
  {
    cx += 0.1 * scale;
    setWindow();
    render();
  }
  function handle_left( e )
  {
    cx -= 0.1 * scale;
    setWindow();
    render();
  }

  function handle_mouse_down ( e ) {
    m_down = true;
    ox = e.hasOwnProperty('offsetX') ? e.offsetX : e.layerX;
    oy = e.hasOwnProperty('offsetY') ? e.offsetY : e.layerY;
  }

  var firstMouseMove = true;
  function handle_mouse_move ( e )
  {
    if ( m_down ) {
      var dx = ox - (e.offsetX==undefined?e.layerX:e.offsetX);
      var dy = (e.offsetY==undefined?e.layerY:e.offsetY) - oy;

      ox = e.offsetX==undefined?e.layerX:e.offsetX;
      oy = e.offsetY==undefined?e.layerY:e.offsetY;
      if ( e.shiftKey ) {
        cRe += dx/100;
        cIm += dy/100;
        re_label.innerHTML = cRe;
        im_label.innerHTML = cIm;
      } else if ( e.altKey ) {
        power[0] += dx/100;
        power[1] += dy/100;
        power_label.innerHTML = power[0] + " + i" + power[1];
      } else {
        cx += 4 * dx / (canvas.width  / scale );
        cy += 4 * dy / (canvas.height / scale );
        setWindow();
      }
      render();
    }
  }

  function setWindow()
  {
    minX  = cx - (x_factor * scale);
    maxX  = cx + (x_factor * scale);
    minY  = cy - (y_factor * scale);
  }

  function changeFunction()
  {
    if (f2.checked) power = vec2(2.0, 0);
    if (f3.checked) power = vec2(3.0, 0);
    if (f4.checked) power = vec2(4.0, 0);
    if (f5.checked) power = vec2(5.0, 0);
    render()
  }

})();
</script>



```c++
const float max = 100.0;
float mandelbrot(float fx, float fy) {
  float iteration  = 0.0;
  float x          = 0.0;
  float y          = 0.0;
  float xtemp      = 0.0;

  for ( float i = 0.0; i < max; ++i  )
  {
    if ( sqrt(x * x + y * y) <= 4.0 ) {
      xtemp = x * x - y * y + fx;
      y = 2.0 * x * y + fy;
      x = xtemp;
      iteration = i;
    }
    else{ break; }
  }
  return iteration;
}
```

#### Julia Set (More interesting): ####

#### Newton Fractals: ####
