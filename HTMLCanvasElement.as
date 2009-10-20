package com.w3canvas.ascanvas {
//	Metaprogramming
//	import flash.utils.Proxy;

//	HTML/CSS
	import com.w3canvas.ascanvas.HTMLElement;

//	Various
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.text.TextField;

//	ImageData
	import flash.utils.ByteArray;
	import com.w3canvas.ascanvas.PNGEnc;
	import com.w3canvas.ascanvas.Base64;

//	FIXME: autoClosePath - flash will closePath if two points are too close.
//	FIXME: Verify that this is still an issue in Flash 10

//	HTML 5 Canvas Element
	dynamic public class HTMLCanvasElement extends HTMLElement {
		private var context = null;
		private var mode = '2d';
		private var windowId = 'FIXME-FOR-REMOTING';
		private var oid = 'FIXME:Used-for-Local-and-External-Remoting';
		private var t;
		private var originClean = true;
		private var event; // event handler

		public function HTMLCanvasElement(ownerDoc = null) {
			super('canvas', {width: 300, height: 150}, ownerDoc, this);
			// this.oid = 'FIXME:Used-for-Local-and-External-Remoting';
			this.oid = (String(Math.random())).substr(2); // LocalConnection Handle
			this.width = 300;
			this.height = 150;
			context = new com.w3canvas.ascanvas.CanvasRenderingContext2D(this);
			event = new CanvasEvent(this,context.toSprite());
			ImplementedOn(event,event.public_vars);
			ImplementedOn(event,event.public_call);
			// FIXME: Improve WebIDL Implementation
		}
		override public function move() {
			if(context == null) return;
			var c = toSprite();
			c.x = style.left || 0;
			c.y = style.top || 0;
		}
		override public function resize() {
//			if(width>768) throw new Error("Go for:"+width);
			if(context != null) context.clear();
		}
		public function getContext(mode) { return context; }
		public function toDataURL(format:String="image/png") {
			var bmp:BitmapData=new BitmapData(style.width,style.height,true,0x00000000);
			bmp.draw(toSprite());
			if(format == "image/png")
				return 'data:image/png;base64,' +
					Base64.encodeByteArray(PNGEnc.encode(bmp));
			if(format == "text/css") if(this.id)
				return 'data:text/css,url(#'+this.windowId+')';
			return 'data:image/png;base64,' +
					Base64.encodeByteArray(PNGEnc.encode(bmp));
		}
		public function toString() { return "[object HTMLCanvasElement]"; }
		public function toSource() { return "<canvas></canvas>"; }
		public function toJSON() { return "new HTMLCanvasElement()"; };
		public function toSprite() { return context.toSprite(); }
		public function toBitmapData() { return context.toBitmapData(); }
	}
}

