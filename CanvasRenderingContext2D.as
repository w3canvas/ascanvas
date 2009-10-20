/*

		CanvasRenderingContext2D in ActionScript
	Based on work by Colin Lueng
	Written by Charles Pritchard
	for Jumis, Inc. Last Updated 2009.

	Copyright 2008 Jumis, Inc
	a Nevada Corporation, United States of America
	http://jumis.com/

	Unless otherwise noted:
	All source code is hereby released into public domain.
	http://creativecommons.org/publicdomain/zero/1.0/
	http://creativecommons.org/licenses/publicdomain/

*/
package com.w3canvas.ascanvas {

//	Rendering
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.PixelSnapping;
	import flash.display.JointStyle;
	import flash.display.CapsStyle;
	import flash.display.GradientType;

//	Maths
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

//	Canvas and Path States
	import flash.utils.Proxy;

//	Text
	import flash.text.TextField;
	import flash.text.TextLineMetrics;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.filters.GlowFilter;
	import flash.filters.BitmapFilterQuality;

//	ImageData
	import flash.utils.ByteArray;

//	Canvas
//	paint server
	import com.w3canvas.ascanvas.CSSColor;
	import com.w3canvas.ascanvas.CanvasGradient;
	import com.w3canvas.ascanvas.CanvasPattern;
//	path and compositing
	import com.w3canvas.ascanvas.CanvasCompositing;
	import com.w3canvas.ascanvas.CanvasPath;
//	public interface
	import com.w3canvas.ascanvas.CanvasExpando;

	dynamic public class CanvasRenderingContext2D extends ExpandoMixin {
		private var version='ASCanvas 1.0 (WHATWG Canvas)';
		private var _canvas;
		private function get width () { return _canvas.width; };
		private function get height () { return _canvas.height; };
		private var state; // current state
		private var states; // stack of saved states
		private var path; // path collection and transformation
		private var urls = []; // pattern and gradient references (paint servers)

		private var network; // image loading (via url)
		private var resources; // FIXME: hacky image loading
		private var readyState = 0;

//	HTML Canvas Element
		public function get canvas() { return _canvas; };
		private const CANVAS_STACK_UNDERFLOW = "restore() caused a a buffer underflow: There are no more saved states available to restore.";
		//protected var prototype = {};
		private var attributes = {};

//	Flash Specific
		public var window:String; /* Network Handle, for Flash Communication */
		public function toSprite() { return canvasSprite; }; /* Bitmap Handle, for Display */
		public function toBitmapData() { return canvasData; }; /* Bitmap Handle, for Display */


//		Output image chain
		private var canvasSprite:Sprite; // Unnecessary, canvasBitmap inherits from Sprite
		private var canvasBitmap:Bitmap; // Bitmap Sprite
		private var canvasData:BitmapData; // Bitmap Surface
		private var bufferSprite:Sprite; // Buffered Image
		private var bufferContext:Graphics; // 2D Drawing API

//		Internal image buffers
		private var clipSprite:Sprite;
		private var clipContext:Graphics;

//		Internal variables
		private var renderVector:Boolean;
		private var fontFormat:TextFormat;


/*	Local Methods and Functions */
//		ImageData: createImageData, putImageData, getImageData
//		Shapes (rectangles): clearRect, fillRect, strokeRect
//		Image: drawImage
//		Text: strokeText, fillText

		public function CanvasRenderingContext2D(container:HTMLCanvasElement) {
			super(null,null,null,com.w3canvas.ascanvas.CanvasRenderingContext2D.prototype,attributes,this);
			
			_canvas = container;
			
			states = [];
			state = new CanvasState(_canvas);
			path = new CanvasPath(_canvas);
			path.transformation = state.transformation;

			var locals = [ 'createImageData','putImageData','getImageData',
							'createPattern','createRadialGradient','createLinearGradient',
							'clearRect','fillRect','strokeRect',
							'drawImage',
							'strokeText',// 'fillText',
							'clip','stroke','fill',
							'save','restore'];

//	Style over substance
			ImplementedOn(this,locals);
			ImplementedOn(state,state.public_vars);
			ImplementedOn(path,path.public_call);

//	Network Library
			network = new CanvasNetwork(_canvas);
			resources = network.resources;

//	ActionScript Implementation
			window = container.oid;
			fontFormat = new TextFormat();
			canvasSprite = new Sprite();
			bufferSprite = new Sprite();
			bufferContext = bufferSprite.graphics;
			canvasData = new BitmapData(width,height,true,0x00000000);
			canvasBitmap = new Bitmap(canvasData,PixelSnapping.ALWAYS);
			canvasSprite.addChild(canvasBitmap);
			canvasSprite.tabEnabled = false;
			clipSprite = new Sprite(); // state.clipping;
			clipContext = clipSprite.graphics; // state.clipping.graphics;
//			bufferSprite.mask = clipSprite;
		}

// State
		public function restore() {
			if(!states.length) throw new Error(CANVAS_STACK_UNDERFLOW);
			state.transformation = states.pop();
			for(var i in state.public_vars) state[ state.public_vars[i] ] = states.pop();
			path.transformation = state.transformation;
		}
		public function save() {
			var v = []; for(var i in state.public_vars) v.unshift(state.public_vars[i]);
			for(i in v) states.push(state[v[i]]);
			states.push(state.transformation.clone());
		}

		public function clear() {
			state.reset();
			path.transformation = state.transformation;
			clipContext.clear();
			bufferContext.clear();
//			if there is a memory leak in garbage collection, dispose old bitmap
			canvasData = new BitmapData(width,height,true,0x00000000);
			canvasBitmap.bitmapData = canvasData;
		}

// Buffer
		public function clip():void{
			clipContext.beginFill(0,1);
			drawVector(clipContext,path);
			flush();
			bufferSprite.mask = clipSprite;
		}

		public function fill():void{
			setFillStyle(bufferContext);
//			if(this.readyState == 2) return;
//			throw new Error("Going"+path.commands+"\n"+path.data.join('|'));
			drawVector(bufferContext, path);
			bufferContext.endFill();
			flush();
		}

		public function stroke():void{
			setLineStyle(bufferContext);
//			if(this.readyState == 2) return;
			drawVector(bufferContext, path);
			flush();
		}

//	FIXME: Fork Flash 9
		public function drawVector(g,v) {
			var cmds = Vector.<int>(v.commands); 
			var data = Vector.<Number>(v.data); 
			g.drawPath(cmds,data);
		}

// Simple shapes: rectangles
		public function clearRect(x,y,w,h) {
			var rect = new BitmapData(width,height,true,0x00000000);
			canvasData.draw(rect,state.transformation);
			//	canvasData.fillRect(new Rectangle(x, y, w, h), 0x00000000);
		}

		public function fillRect(x,y,w,h) {
			var rect = new flash.display.Shape(); // BitmapData(width,height,true,0x00000000);
			setFillStyle(rect.graphics);
			rect.graphics.drawRect(x,y,w,h);
			rect.graphics.endFill();
			canvasData.draw(rect,state.transformation,null,null); // ,state.clipping);
		}

		/* public function fillRect(x:Number, y:Number, width:Number, height:Number):void{
			setFillStyle(bufferContext);
			if(this.readyState == 2) return;
			bufferContext.drawRect(x, y, width, height);
			bufferContext.endFill();
			flush();
		} */
		public function strokeRect(x,y,w,h) {
			var rect = new flash.display.Shape(); 
			setLineStyle(rect.graphics);
			rect.graphics.drawRect(x,y,w,h);
			rect.graphics.endFill();
			canvasData.draw(rect,state.transformation,null,null); // ,state.clipping);
//			setLineStyle(bufferContext);
//			if(this.readyState == 2) return;
			flush();
		}

// ImageData
		public function createImageData(w,h) {
			var rect = new BitmapData(width,height,true,0x00000000);
			var rect = rect.getPixels(new Rectangle(0,0,w,h));
			var data = returnCanvasPixelArray(rect);
			return {width: w, height: h, data: data};
		}
		public function getImageData(x,y,w,h) {
			var rect = canvasData.getPixels(new Rectangle(x,y,w,h));
			var data = returnCanvasPixelArray(rect);
			return {width: w, height: h, data: data};
		}
		public function putImageData(ImageData,dx,dy,dirtyX=null,dirtyY=null,dirtyWidth=null,dirtyHeight=null) {
			var source = ImageData.data;
			canvasData.lock();
			for (var i:int = 0; i < canvasData.height ; i++) {
			for (var j:int = 0, k=0; j < canvasData.width; j++) {
				k = (i*canvasData.width*4)+(j*4);
				canvasData.setPixel32(j,i, (source[k+3] << 24 | source[k] << 16 | source[k+1] << 8 | source[k+2]) );
			}
			}
			canvasData.unlock();
		}
		private function returnCanvasPixelArray(rect) {
			/*for(var i=0,j=rect.length,k=0;i<j;i+=4) {
				k = rect[i];
				rect[i] = rect[i]+1;
				rect[i+1] = rect[i]+2;
				rect[i+2] = rect[i]+3;
				rect[i] = k;
			} return rect; */

			var source=0,data =[];// new Array(rect.length);
			for(var i=0,j=rect.length;i<j;i+=4) {
				// source = rect[i];
				data.push(rect[i+1]);
				data.push(rect[i+2]);
				data.push(rect[i+3]);
				data.push(rect[i]);
			}
			// if(data.length>16) throw new Error("OK"+data.slice(0,100).join(','));
			return data;
		}

// Text API

// This is not a real strokeText: it has no directional information,
// it can not implement a gradient stroke. Embedded fonts must be used for an accurate
// strokeText, as Actionscript does not disclose the outline of system fonts.
 
		prototype.strokeText = function(text:String, x:Number = 0, y:Number = 0) {
			var glow = new GlowFilter();
			glow.blurX = 2;
			glow.blurY = 2;
			glow.strength = 100;
			glow.quality = BitmapFilterQuality.HIGH;
			glow.color = 0xFFc0c0;
	
			var filters = new Array();
			filters.push(glow);
			this.fillText(text,x,y,filters);
		}

//		If this were defined in the prototype scope, we'd have better luck cross-compiling

		prototype.fillText = function(text:String, x:Number = 0, y:Number = 0, filters:Array = null) {
//			if(this.readyState == 2) return;
			this.setFontStyle();
			var isSolid = 0 && isFillSafe(); // Nicer anti-aliasing [ use cacheAsBitmap? ];
			var tf = new TextField();
			tf.defaultTextFormat = this.fontFormat;

//	System fonts can not be rotated, skewed or used as masks.
//	None of these help with system fonts
			tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
			tf.type = flash.text.TextFieldType.DYNAMIC;
			tf.autoSize = flash.text.TextFieldAutoSize.NONE;
			tf.gridFitType = flash.text.GridFitType.NONE;

//	It seems that scaling works. Here are old font names:
//	_sans, _serif, typewriter

			if(1||isSolid) tf.textColor = this.getFillColor();
			else tf.textColor = 0x000000;
			// tf.textColor = 0xFFFFFF;
			isSolid = true;

			// if(fontFormat.size < 48) tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
			tf.text = text;

// Very broken for background mask
			var tr = this.state.transformation.transformPoint(new Point(0,0));
			x += tr.x; y += tr.y;
			var tmp = tf.transform.matrix;
			// tmp.scale(1,2);
			var rev = tmp.deltaTransformPoint(new Point(x,y));
			tmp.translate(0, y-rev.y);
			// tmp.rotate(0.01); Breaks everything
			tf.transform.matrix = tmp;

			var extent = tf.getLineMetrics(0);
			extent.height = tmp.deltaTransformPoint(new Point(0,extent.height)).y;
			extent.width = tmp.deltaTransformPoint(new Point(extent.width,0)).x;
			y -= extent.height;
			// Canvas text defaults to baseline, flash defaults to top
			// FIXME: This current default is bottom,
			// use ascent and descent for better values, and implement others


			if(isSolid) { 
				tf.x = x;
				tf.y = y;
				tf.width = extent.width + 4; // 2px gutter
				tf.height = extent.height + 4; // 2px gutter
				this.bufferSprite.addChild(tf);
			} else {
			// Pattern fill compositor

				// Mask rendered text over fill style
				text += extent.height;
				var bg = new Sprite();
 				bg.x+=2; bg.y+=2; // 2px gutter
				this.setFillStyle(bg.graphics);
				bg.graphics.drawRect(0,0,extent.width,extent.height);
				bg.graphics.endFill();
				bg.height = extent.height; bg.width = extent.width;
				tf.height = extent.height+4; tf.width = extent.width+4; // 2px gutter
bg.transform = tf.transform;

				if(filters) tf.filters = filters;

				var container = new Sprite();
				container.blendMode = BlendMode.LAYER;
				tf.blendMode = BlendMode.ALPHA;
				container.addChild(bg);
				container.addChild(tf);
				container.x = x;
				container.y = y;
				this.bufferSprite.addChild(container);
			}

			this.flush();
			delete tf;
			delete container;
			delete bg;
		}

		// public class TextMetrics
		prototype.measureText = function(text) {
			// return new TextMetrics(fontFormat,text);
			var tf = new TextField();
			tf.setTextFormat(this.fontFormat);
			tf.text = text;
			var extent = tf.getLineMetrics(0);
			return { width: extent.width };
		}

// Procedural Fills

		public function createLinearGradient(x0:Number,y0:Number,x1:Number,y1:Number):LinearGradient{
			var gradient = new LinearGradient(x0,y0,x1,y1);
			var idx = this.urls.push(gradient)-1;
			this.urls[idx].url='url(#l'+(idx+1)+')';
			return this.urls[idx];
		}

		public function createRadialGradient(x0:Number, y0:Number, r0:Number, x1:Number, y1:Number, r1:Number):RadialGradient{
			var gradient = new RadialGradient(x0, y0, r0, x1, y1, r1);
			var idx = this.urls.push(gradient)-1;
			this.urls[idx].url='url(#r'+(idx+1)+')';
			return this.urls[idx];
		}

		public function createPattern(image:*,repetition:String='repeat'):*{
			var i,args=[]; for(i in arguments) args.push(arguments[i]);
			if(image is BitmapData) { return _createPattern.apply(this,args); }
			if(image.urn && image.urn in resources) image.src=image.urn;
			if(image.src in resources) {
				args[0]=images[resources[image.src]].bitmapData;
				return _createPattern.apply(this,args);
			}
			this.readyState = 2;
			var url = this.urls.push(new BitmapData(1,1));
			args=['_createPattern',repetition,url-1];
			_loadImage(image,args);
			return 'url(#p'+url+')';
		}

		public function _createPattern(image:BitmapData,repetition:String='repeat',idx=null):CanvasPattern{
			var pattern = new CanvasPattern(image,repetition);
			if(isNaN(idx)) idx=this.urls.push(pattern)-1;
			else this.urls[idx]=pattern;
			this.urls[idx].url='url(#p'+(idx+1)+')';
			return this.urls[idx];
		}

		public function drawImage(image:*, sx:Number, sy:Number, swidth:Number=NaN, sheight:Number=NaN, dx:Number=NaN, dy:Number=NaN, dwidth:Number=NaN, dheight:Number=NaN):*{
			var i,args=[]; for(i in arguments) args.push(arguments[i]);
	try {
			if(image is Bitmap) args[0] = image.bitmapData;
			else if(image is Image) args[0] = image.toBitmapData();
			else if(image is HTMLCanvasElement) args[0] = image.toBitmapData();
			else if(image is TextField) throw new Error("HAH"+image.text);
			else if(0 && 'src' in image && image.src && image.src in resources) 
				args[0]=images[resources[image.src]].bitmapData;
			if(args[0] is BitmapData) if(args[0]) return _drawImage.apply(this,args);
			if(image is BitmapData) throw new Error("ok"+args[0]);// return _drawImage.apply(this,args);
	} catch(e) {
	// Base64 Image.src = 'data:'; // uses async loader in Actionscript.
 	throw new Error("it never hap"+image.toBitmapData().width+'e'+e);
	return;
	var that = this; image.onload = function() { args[0] = image.toBitmapData(); return _drawImage.apply(that,args); };
	return;
	} // this.readyState = 2;
	throw new Error("Image not available / loadable: "+image.src.substr(0,10)+'...');
		//	if(image is Image) if('src' in image) { args[0]='_drawImage'; _loadImage(image,args); }
		}

		public function _drawImage(image:BitmapData, sx:Number, sy:Number, swidth:Number=NaN, sheight:Number=NaN, dx:Number=NaN, dy:Number=NaN, dwidth:Number=NaN, dheight:Number=NaN):void{
			var smx = new Matrix(); image = image.clone();
			// var bit = new Bitmap(image); // FIXME: Use this one
			if(isNaN(swidth)) { swidth = image.width; sheight = image.height; scale = [1,1]; }
			else {
				var scale = [ !isNaN(dwidth) ? (dwidth / image.width) : (swidth / image.width),
					     !isNaN(dheight) ? (dheight / image.height) : (sheight / image.height)];
			}

			smx = state.transformation.clone();
			smx.translate(sx,sy);
			smx.scale(scale[0],scale[1]);
			if(!isNaN(dheight)) 
					canvasData.draw(image,smx,null,null, new Rectangle(dx,dy,dwidth,dheight), true);
			else canvasData.draw(image,smx,null,null,null,true);
			flush();
			return;

			smx = new Matrix();
			bufferContext.beginBitmapFill(image,smx,true,true); // true
            		bufferContext.drawRect(sx, sy, swidth, sheight);
		   	bufferContext.endFill();
			flush();
		}
	
		private function _loadImage(image,args) {
			return network.loadImage(image,args);
		}

//	Fill, stroke and font styles

		public function setFontStyle():void{
			var r = state.font.split(' '); // break down css.font
			var fontSize = r[0], fontFamily = r[1];
			var type = fontSize, n = parseFloat(type);

			if(isNaN(n)) return;
			if(type.length>2) type = type.substr(type.length - 2, 2).toUpperCase();
			if(type == 'PX') n *= 1.3333;
			if(fontFamily == 'sans-serif') fontFamily = 'Arial';
			fontFormat.font = fontFamily;
			fontFormat.size = n;

		}

		private function setLineStyle(bufferContext:Graphics,pixelHinting:Boolean=true) : void {
			var strokeResource;
			var _lineJoin, _lineCap;

			var line = state.lineJoin.toLowerCase();
			if(line == 'round') _lineJoin = JointStyle.ROUND;
			else if(line == 'bevel') _lineJoin = JointStyle.BEVEL;
			else _lineJoin = JointStyle.MITER;

			line = state.lineCap.toLowerCase();
			if(line == 'square') _lineCap = CapsStyle.SQUARE;
			else if(line == 'round') _lineCap = CapsStyle.ROUND;
			else _lineCap = CapsStyle.NONE;

			if(state.strokeStyle is String){
				if(-1<state.strokeStyle.indexOf('url(#')) {
					var url = state.strokeStyle.substring(6,_strokeStyle.length-1);
					strokeResource = urls[url-1];
				}
				else {
					var s1 : CSSColor = new CSSColor(String(state.strokeStyle));
					bufferContext.lineStyle(state.lineWidth, s1.color, s1.alpha, pixelHinting, "normal", _lineCap, _lineJoin, state.miterLimit);
					return;
				}
			} else strokeResource = _strokeStyle;
			
			if(strokeResource is LinearGradient){
				var s2 : * = LinearGradient(strokeResource);
				bufferContext.lineGradientStyle(GradientType.LINEAR, s2.colors, s2.alphas, s2.ratios,
					s2.matrix, s2.spreadMethod, s2.interpolationMethod, s2.focalPointRatio);
			}
			else if(strokeResource is RadialGradient){
				var s3 : * = RadialGradient(strokeResource);
				bufferContext.lineGradientStyle(GradientType.RADIAL, s3.colors, s3.alphas, s3.ratios,
					s3.matrix, s3.spreadMethod, s3.interpolationMethod, s3.focalPointRatio);
			}
			else if(strokeResource is CanvasPattern) {
//				bufferContext.lineBitmapStyle( CanvasPattern(strokeResource), null, true, false); // Flash 10
//				bufferContext.beginBitmapFill(s4.patternFill);
			}

 		}

		// Supporting functions for full opacity color fills
		private function isFillSafe() {
			if(!(state.fillStyle is String)) { if(isNaN(state.fillStyle)) return false; return true; }
			if(state.fillStyle.indexOf('url(#') < 0) {
				var s = new CSSColor(String(state.fillStyle));
				if(s.alpha == 1) return true;
				return false;
			}
		}

		private function getFillColor() {
			if(!isFillSafe()) return 0x000000;
			var s1 = new CSSColor(state.fillStyle);
			return s1.color;
		}

 		private function setFillStyle(bufferContext:Graphics):void{
 			bufferContext.lineStyle(undefined);

			var fillResource;
			if(state.fillStyle is String){
				if(-1<state.fillStyle.indexOf('url(#')) { // url(#[p|l|r][0-9]+)
					var url = state.fillStyle.substring(6,state.fillStyle.length-1);
					fillResource = urls[url-1];
				}
				else {
					var s1 : CSSColor = new CSSColor(String(state.fillStyle));
					bufferContext.beginFill(s1.color, s1.alpha)
					return;
				}
			} else fillResource = state.fillStyle;

			if(fillResource is LinearGradient){
				var s2 = LinearGradient(fillResource);
				bufferContext.beginGradientFill(GradientType.LINEAR, s2.colors, s2.alphas, s2.ratios, s2.matrix, s2.spreadMethod, s2.interpolationMethod, s2.focalPointRatio);
			}
			else if(fillResource is RadialGradient){
				var s3 = RadialGradient(fillResource);
				bufferContext.beginGradientFill(GradientType.RADIAL, s3.colors, s3.alphas, s3.ratios, s3.matrix, s3.spreadMethod, s3.interpolationMethod, s3.focalPointRatio);
			}
			else if(fillResource is CanvasPattern) {
				var s4 = CanvasPattern(fillResource);
				bufferContext.beginBitmapFill(s4.patternFill);
			}
			// else if(fillResource is Shader) {}
			// else if(fillResource is Function) {}
		}

		private function compositeFlush() {
			var b:BitmapData = new BitmapData(canvasData.width, canvasData.height, true,0x00000000);
			b.draw(bufferSprite);
			var compositerFactory  = new CanvasCompositing();
			var compositer:ICompositer = compositerFactory.GetCompositer('flashLogic');
			var output:BitmapData = compositer.CompositeBitmap(state.globalCompositeOperation, canvasData, b);
			canvasData.copyPixels(output,new Rectangle(0,0,canvasData.width,canvasData.height),new Point(0,0));
		}

		private function flush() {
			if(state.globalCompositeOperation == 'source-over') canvasData.draw(bufferSprite);
			else compositeFlush();
			while(bufferSprite.numChildren) bufferSprite.removeChildAt(0);
			bufferContext.clear();
		}

		private function blendPorterDuff(source,destination,mode='source-over',logic='flash'):BitmapData {
//			Rasterize(sprite);
			var b,c;
			if(source is BitmapData) b = source;
			else { var b = new BitmapData(source.width, source.height,true,0x00000000); b.draw(source); }

			if(destionation is BitmapData) b = destination;
			else { var c = new BitmapData(destination.width, destination.height,true,0x00000000); c.draw(destination); };

			var compositerFactory = new CompositerFactory();
			var compositer = compositerFactory.GetCompositer(CompositerFactory.flashLogic);

//			Blend
			var output:BitmapData = compositer.CompositeBitmap(_globalCompositeOperation,source,destination);
			return output;
		}
	}

// Based on Jumis' HTML Canvas Bytecode Proposal
// unused
import flash.utils.Proxy;
public class CanvasTracingContext2D extends Proxy {
	public static const DRAW = 1;
	public static const COORD = 1 << 2;
	public static const STATE = 1 << 3;
	public static const PATH = 1 << 4;
	public static const TEXT = 1 << 5;
	public static const SHAPE = 1 << 6;
	public static const IMAGE = 1 << 7;
	public static const TRANSFORM = 1 << 8;
	public static const STYLE = 1 << 9;
	public static const DEFAULT = DRAW & COORD & STATE & PATH & TEXT & IMAGE & TRANSFORM & STYLE;
	public static const ENUM = {
		'DRAW': DRAW, 'COORD': COORD,
		'STATE': STATE, 'PATH': PATH, 'TEXT': TEXT, 'SHAPE': SHAPE,
		'IMAGE': IMAGE, 'TRANSFORM': TRANSFORM, 'STYLE': STYLE };
	private var _trace;

	public function set trace(a) {
		if(a == null) a = DEFAULT;
		if(isNaN(a)) { if(a in ENUM) _trace = ENUM[a]; }
		_trace = a;	
	}
	public function get trace() {
		return _trace;
	}
	public function toString() {
		var a = []; for(i in ENUM) if(ENUM[i] & _trace) a.push(i);
		return 'CanvasTracingContext2D: '+a.join(',');
	}
	public function CanvasTracingContext2D(canvas = null, attr = null) {
		if(canvas === null) canvas = { 'width': 300, 'height': 150 };
		trace = attr;
	};
};


public class CanvasPixelArray extends Proxy {
	public function CanvasPixelArray() {
		var data = [];
		var i=0,source=0; for(i in rect) {
			source = rect[i]; 
                       	data.push (source >> 16 & 0xFF);
                       	data.push (source >> 8 & 0xFF);
                       	data.push (source & 0xFF);
                       	data.push (source >> 24 & 0xFF);
		}
	}
	// lock() // unlock() // getPixels // setPixels
}


// Based on WHATWG HTML Canvas Specifications

import flash.geom.Matrix;
import flash.utils.ByteArray;
import com.w3canvas.ascanvas.CanvasPath;
public class CanvasState {
	public var transformation:Matrix;
	public var clipping:CanvasPath;
	public var strokeStyle:* = '#000000';
	public var fillStyle:* = '#000000';
	public var globalAlpha = 1.0;
	public var lineWidth = 1.0;
	public var lineCap = 'butt';
	public var lineJoin = 'miter';
	public var miterLimit = 10.0;
	public var shadowOffsetX = 0;
	public var shadowOffsetY = 0;
	public var shadowBlur = 0;
	public var shadowColor = 'rgba(0, 0, 0, 0)';
	public var globalCompositeOperation = 'source-over';
	public var font = '10px sans-serif';
	public var textAlign = 'start';
	public var textBaseline = 'alphabetic';
	private var canvas;

// Silly Reflection Array
	public const public_vars = ['strokeStyle','fillStyle','globalAlpha',
			'lineWidth','lineCap','lineJoin','miterLimit',
			'shadowOffsetX','shadowOffsetY','shadowBlur','shadowColor',
			'globalCompositeOperation',
			'font','textAlign','textBaseline'];

	public function CanvasState(canvas) {
 		this.canvas = canvas;
		transformation = new Matrix();
		clipping = new CanvasPath();
		// clipping.rect(0,0,canvas.width,canvas.height);
	}

	public function copy(that) {
		for(i in that) this[i] = that[i];
		return true;
	}
	public function reset() {
		var n = new CanvasState(canvas); copy(n);
		this.transformation.identity();
		return true;
	}

}

}
