package openfl._internal.renderer.opengl.shaders;


import lime.graphics.GLProgram;
import lime.graphics.GLRenderContext;
import lime.graphics.GLUniformLocation;
import openfl._internal.renderer.opengl.utils.Texture;


class DefaultShader extends AbstractShader {
	
	
	public static var defaultVertexSrc = [
		'attribute vec2 aVertexPosition;',
		'attribute vec2 aTextureCoord;',
		'attribute vec2 aColor;',
		
		'uniform vec2 projectionVector;',
		'uniform vec2 offsetVector;',
		
		'varying vec2 vTextureCoord;',
		'varying vec4 vColor;',
		
		'const vec2 center = vec2(-1.0, 1.0);',
		
		'void main(void) {',
		'   gl_Position = vec4( ((aVertexPosition + offsetVector) / projectionVector) + center , 0.0, 1.0);',
		'   vTextureCoord = aTextureCoord;',
		'   vec3 color = mod(vec3(aColor.y/65536.0, aColor.y/256.0, aColor.y), 256.0) / 256.0;',
		'   vColor = vec4(color * aColor.x, aColor.x);',
		'}'
	];
	
	public var aTextureCoord:Int;
	public var aVertexPosition:Int;
	public var colorAttribute:Int;
	public var dimensions:GLUniformLocation;
	public var offsetVector:GLUniformLocation;
	public var projectionVector:GLUniformLocation;
	public var textureCount:Int;
	public var uSampler:GLUniformLocation;
	
	
	public function new (gl:GLRenderContext) {
		
		super (gl);
		
		fragmentSrc = [
			'precision lowp float;',
			'varying vec2 vTextureCoord;',
			'varying vec4 vColor;',
			'uniform sampler2D uSampler;',
			'void main(void) {',
			'   gl_FragColor = texture2D(uSampler, vTextureCoord) * vColor ;',
			'}'
		];
		
		textureCount = 0;
		attributes = [];
		
		init ();
		
	}
	
	
	public override function init ():Void {
		
		if (vertexSrc == null) {
			
			vertexSrc = defaultVertexSrc;
			
		}
		
		super.init ();
		
		var gl = this.gl;
		
		uSampler = gl.getUniformLocation (program, 'uSampler');
		projectionVector = gl.getUniformLocation (program, 'projectionVector');
		offsetVector = gl.getUniformLocation (program, 'offsetVector');
		dimensions = gl.getUniformLocation (program, 'dimensions');
		
		aVertexPosition = gl.getAttribLocation (program, 'aVertexPosition');
		aTextureCoord = gl.getAttribLocation (program, 'aTextureCoord');
		colorAttribute = gl.getAttribLocation (program, 'aColor');
		
		if (colorAttribute == -1) {
			
			colorAttribute = 2;
			
		}
		
		attributes = [ aVertexPosition, aTextureCoord, colorAttribute ];
		
		if (uniforms != null) {
			
			for (key in uniforms.keys ()) {
				
				uniforms.get (key).uniformLocation = gl.getUniformLocation (program, key);
				
			}
			
		}
		
		initUniforms ();
		
	}
	
	
	public function initSampler2D (uniform:Dynamic):Void {
		
		if (uniform.value == null || uniform.value.baseTexture == null || uniform.value.baseTexture.hasLoaded == null) {
			
			return;
			
		}
		
		var gl = this.gl;
		
		gl.activeTexture (Reflect.field (gl, 'TEXTURE' + textureCount));
		gl.bindTexture (gl.TEXTURE_2D, uniform.value.baseTexture._glTextures[GLRenderer.glContextId]);
		
		if (uniform.textureData != null) {
			
			var data = uniform.textureData;
			
			var magFilter = (data.magFilter != null) ? data.magFilter : gl.LINEAR;
			var minFilter = (data.minFilter != null) ? data.minFilter : gl.LINEAR;
			var wrapS = (data.wrapS != null) ? data.wrapS : gl.CLAMP_TO_EDGE;
			var wrapT = (data.wrapT != null) ? data.wrapT : gl.CLAMP_TO_EDGE;
			var format = (data.luminance != null) ? gl.LUMINANCE : gl.RGBA;
			
			if (data.repeat) {
				
				wrapS = gl.REPEAT;
				wrapT = gl.REPEAT;
				
			}
			
			gl.pixelStorei (gl.UNPACK_FLIP_Y_WEBGL, data.flip != null ? data.flip : 0);
			
			if (data.width != null) {
				
				var width = (data.width != null) ? data.width : 512;
				var height = (data.height != null) ? data.height : 2;
				var border = (data.border != null) ? data.border : 0;
				
				gl.texImage2D (gl.TEXTURE_2D, 0, format, width, height, border, format, gl.UNSIGNED_BYTE, null);
				
			} else {
				
				#if js
				gl.texImage2D (gl.TEXTURE_2D, 0, format, gl.RGBA, gl.UNSIGNED_BYTE, uniform.value.baseTexture.source);
				#end
				
			}
			
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, magFilter);
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, minFilter);
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, wrapS);
			gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, wrapT);
			
		}
		
		gl.uniform1i (uniform.uniformLocation, textureCount);
		uniform._init = true;
		textureCount++;
		
	}
	
	
	public function initUniforms ():Void {
		
		textureCount = 1;
		var gl = this.gl;
		var uniform:Dynamic;
		
		if (uniforms == null) return;
		
		for (key in uniforms.keys ()) {
			
			uniform = uniforms.get (key);
			var type = uniform.type;
			
			if (type == 'sampler2D') {
				
				uniform._init = false;
				
				if (uniform.value != null) {
					
					initSampler2D (uniform);
					
				}
				
			} else if (type == 'mat2' || type == 'mat3' || type == 'mat4') {
				
				uniform.glMatrix = true;
				uniform.glValueLength = 1;
				
				if (type == 'mat2') {
					
					uniform.glFunc = gl.uniformMatrix2fv;
					
				} else if (type == 'mat3') {
					
					uniform.glFunc = gl.uniformMatrix3fv;
					
				} else if (type == 'mat4') {
					
					uniform.glFunc = gl.uniformMatrix4fv;
					
				}
				
			} else {
				
				uniform.glFunc = Reflect.field (gl, 'uniform' + type);
				
				if (type == '2f' || type == '2i') {
					
					uniform.glValueLength = 2;
					
				} else if (type == '3f' || type == '3i') {
					
					uniform.glValueLength = 3;
					
				} else if (type == '4f' || type == '4i') {
					
					uniform.glValueLength = 4;
					
				} else {
					
					uniform.glValueLength = 1;
					
				}
				
			}
			
		}
		
	}
	
	
	public function syncUniforms ():Void {
		
		textureCount = 1;
		var uniform:Dynamic;
		var gl = this.gl;
		
		if (uniforms == null) return;
		
		for (key in uniforms.keys ()) {
			
			uniform = uniforms.get (key);
			
			if (uniform.glValueLength == 1) {
				
				if (uniform.glMatrix == true) {
					
					uniform.glFunc.call(gl, uniform.uniformLocation, uniform.transpose, uniform.value);
					
				} else {
					
					uniform.glFunc.call (gl, uniform.uniformLocation, uniform.value);
					
				}
				
			} else if (uniform.glValueLength == 2) {
				
				uniform.glFunc.call (gl, uniform.uniformLocation, uniform.value.x, uniform.value.y);
				
			} else if (uniform.glValueLength == 3) {
				
				uniform.glFunc.call (gl, uniform.uniformLocation, uniform.value.x, uniform.value.y, uniform.value.z);
				
			} else if (uniform.glValueLength == 4) {
				
				uniform.glFunc.call (gl, uniform.uniformLocation, uniform.value.x, uniform.value.y, uniform.value.z, uniform.value.w);
				
			} else if (uniform.type == 'sampler2D') {
				
				if (uniform._init) {
					
					gl.activeTexture (Reflect.field (gl, 'TEXTURE' + textureCount));
					var tex = uniform.value.baseTexture._glTextures[GLRenderer.glContextId];
					if (tex == null) tex = Texture.createWebGLTexture (cast uniform.value.baseTexture, gl);
					gl.bindTexture (gl.TEXTURE_2D, tex);
					gl.uniform1i (uniform.uniformLocation, textureCount);
					textureCount++;
					
				} else {
					
					initSampler2D (uniform);
					
				}
				
			}
			
		}
		
	}
	
	
}