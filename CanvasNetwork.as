package com.w3canvas.ascanvas {

//      ImageData
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	import com.w3canvas.ascanvas.PNGEnc;
	import com.w3canvas.ascanvas.Base64;

//      Events
    import flash.events.Event;
    import flash.events.StatusEvent;
    import flash.net.LocalConnection;
    import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.display.Loader;

// Based on Actionscript 3 Event Handlers

class CanvasNetwork {

	public var readyState = 0;
	public var onreadystatechange = {};
	public var images = [];
	public var resources= {};
	private var incoming = {};
	private var requests = [];
	private var lcArray:Array=[]; // Local Connections
	private var window;
	private var id;
	private var context;

	public function CanvasNetwork(_canvas) {
		// FIXME: Resources should be shared across all instances.
		window = _canvas.oid; // FIXME: Window is per "window" instance.
		id = _canvas.id;
		context = _canvas.getContext('2d');
	}

	public function _toFlash(con:String,data:String):void {
		incoming[con] += data;
	}

	private function streamImageData(src:String):String {
		var bmp:BitmapData;
		if (src == this.id) {
			bmp = new BitmapData(parent.width,parent.height,true,0x00000000);
			bmp.draw(parent as MovieClip);
		}
		else {
			bmp = images[resources[src]].bitmapData.clone();
		}

		return Base64.encodeByteArray(PNGEnc.encode(bmp));
	}

	public function toFlash(src, callbackID) {
		var callbackLC:LocalConnection = new LocalConnection();

		if(src == this.id || src in resources) {
			// Will break the image data in packets and then send it across;
			var packetSize:int = 39*1024; // Keeping 39K to remain on safer side. Allowed is 40K.
			var retStr:String = this.streamImageData(src);
			var packetCount:int = Math.ceil((retStr.length / packetSize));
			callbackLC.send(callbackID,"setPacketCount",packetCount);
			for (var index:int = 0; index < packetCount; index++) {
				var remainingChar:int = (retStr.length - (index*packetCount));
				remainingChar = (remainingChar > packetSize) ? packetSize : remainingChar; 
				callbackLC.send(callbackID,"callback","Y",
						retStr.substr(index*packetSize, 
								remainingChar), index);
			}
		}
		else {
			callbackLC.send(callbackID,"callback","N",'',0);
		}
	}

	public function fromFlash(src:String) {
		var lc = new LocalConnection();
		lc.connect(src);
		lc.client=this;
		lcArray[src] = lc;
	}

	public function loadImage(image:Object, args:Array):void {
		if (typeof(image) != 'undefined' && ('id' in image) && ('type' in image) &&
			image.id && image.type=="application/x-shockwave-flash") {
			image.src = image.id;
		}
		if(!image.src) return; 
		// this.readyState = 2;
		var fn = args[0];
		var cont:ByteArray;
		var l:Loader = new Loader();
		var isDataImage = false;

		var that=context;
		function p(event):void {
			var bmp:Bitmap = l.getChildAt(0) as Bitmap; l=null;
			resources[image.src] = images.push({bitmapData: bmp.bitmapData, src: image.src}) - 1;
			args[0] = images[resources[image.src]].bitmapData;
			that[fn].apply(this,args);
			if(fn!='_createPattern') 
				if(that.fromArrays.length) that.fromArray(that.fromArrays.shift());
			if(that.readyState == 1) that.readyState = 2;
			if(that.readyState == 2) that.readyState = 3;
			if (!isDataImage) {
				try {
					that.fromFlash(image.src);
				}
				catch(error) {
				}
			}
			// FIXME: Check for other running loaders
		} l.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, p);

		if(image.src && image.src.length > 20 && image.src.substr(0,22)=='data:image/png;base64,') {
			cont = Base64.decodeToByteArray(image.src.substr(22));
			// Don't I wish.
			// image.urn = image.src.substr(22,12);
			// image.src = image.urn;
			isDataImage = true;
			l.loadBytes(cont);
		}
		//  FIXME: Stream data from ExternalInterface?
		//  FIXME: Add hash references :: urn:sha1: magnet:?xt=urn:sha1:
		//  FIXME: Create a real hash :: ex: SHA1.hashBytes(cont);
		else if(image.src) {
			// Create a local connection for sending.
			var lc:LocalConnection = new LocalConnection();
			// Create a local connection for receiving message.
			var rcvngLC:LocalConnection = new LocalConnection();
			rcvngLC.connect(image.src+"_"+this.window+"_"+this.id);
			var dynObject:Object = new Object();
			var packetCount:int = -1;
			var packetsReceived = 0;
			var imageString:Array = [];
			
			dynObject.setPacketCount = function(count:int) {
				packetCount = count;
			}
			dynObject.callback = function(result1:String, imageStr:String, packetIndex:int) {
				if (result1=="Y") {
					packetsReceived++;
					imageString[packetIndex] = imageStr;
					if (packetsReceived == packetCount) {
						l.loadBytes(Base64.decodeToByteArray(imageString.join('')));
					}
				}
				else {
					l.load(new URLRequest(this.imageSrc));
				}
			}
			rcvngLC.client=dynObject;
			
			lc.addEventListener(StatusEvent.STATUS,
				function onStatusEvent(e:StatusEvent):void {
					if(e.level == 'error') {
					rcvngLC.close();
						l.load(new URLRequest(image.src));
					}
			});
		
			lc.send(image.src,'toFlash',image.src, image.src+"_"+this.window+"_"+this.id);
		}
	}

//	Usability (buffered rendering, with timeout)
 	public var fromArrays=[];
 	public function fromArray(input:Array):void {
		this.readyState = 1;
		var ctx = context;
		var x = input.length;
		var a,b; if(x) do {
			b = input.shift();
		a = b.shift();
			if(typeof ctx[a] === 'function') {
				if(!b.length) ctx[a]();
				else ctx[a].apply(ctx,b);
			} else if(a in ctx && ctx[a]!==undefined) ctx[a] = String(b);
			if(this.readyState == 2) break;
		} while(--x);
		this.flush();
		if(this.readyState == 2) {
			var that=this;
			function time() {
				if(that.readyState == 1) return;
				if(that.readyState == 2) { if(t.currentCount == 20); return; }
				if(that.fromArrays.length) that.fromArray(that.fromArrays.shift());
			}
			this.fromArrays.push(input);
			var t = new Timer(100,20);
			t.addEventListener('timer',time);
			t.start();
		} else {
			if(this.fromArrays.length) this.fromArray(this.fromArrays.shift());
			else this.readyState = 3; // FIXME: Check for running loaders
		}
	}
}

}

