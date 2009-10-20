/*
	2009 Jumis, Inc
	Public domain
*/

import flash.display.Sprite;
import flash.display.Stage;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.net.URLRequest;
import flash.events.ProgressEvent;
import flash.events.Event;
import com.w3canvas.ascanvas.HTMLElement;
import com.w3canvas.ascanvas.Base64;

class Image {
	private var bmp = new Bitmap;
	private var _src = '';
	private var _readyState = 0;
	private var l = new Loader();

	public var hash = function() { return image.src.substr(22,12); };
	public var toBitmapData = function() { return bmp.bitmapData; };
	public var getContext = function(c) { return this; };
 
	public var onreadystatechange = function() {};
	public function get readyState () { return this._readyState; };
	public function set readyState (readyState) { this._readyState = readyState; this.onreadystatechange(); };

	public function get width() { return bmp.bitmapData.width; };
	public function get height() { return bmp.bitmapData.height; };

	public function set width(w) { return; var m = new Matrix(); bmp.draw(bmp,m,null,null,true); }
	public function set height(h) { return; var m = new Matrix(); bmp.draw(bmp,m,null,null,true); }

	public function get src () { return this._src; }
	public function set src (src) {
		this._src = src;
		this.readyState=1;
		var _ = this; if(window) window.images++;
		// PNG Decoder could use setPixels, for slow but immediate-mode loading
		if(src && src.length > 21 && src.substr(0,22)=='data:image/png;base64,') 
			l.loadBytes(Base64.decodeToByteArray(src.substr(22)));
		else l.load(new URLRequest(src));
		this.readyState=2;
	}
 	public var onload = function(e) {};
	function Image () {
		var _ = this;
		var p = function(e) { _.bmp = l.getChildAt(0) as Bitmap; _.readyState=4; _.onload(e); if(window) window.images--; };
		var q = function(e) { this.readyState=3; };
		l.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE,p);
		l.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,q);
	};
};

