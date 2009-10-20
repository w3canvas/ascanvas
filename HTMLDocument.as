package com.w3canvas.ascanvas { 

	import com.w3canvas.ascanvas.HTMLElement;
	import com.w3canvas.ascanvas.HTMLCanvasElement;
	import com.w3canvas.ascanvas.CanvasRenderingContext2D;
	import com.w3canvas.ascanvas.DocumentView;

	import flash.display.Sprite;
	import flash.display.Stage;


	// HTML 5
	public class History {
		private var history = [];
		private var current = 0;
		public function get length() { return history.length; };
		public function go(delta) { delta += current; };
	}
	public class Location {
		private var context;
		private var _href;
		private const SYNTAX_ERR = new Error("Syntax error");
		public function get href() { return _href; };
		public function set href(href) { assign(href); };
		public function Location(browsingContext) {
			context = browsingContext;
		}
		public function toString() { return _href; }; // stringifier
		public function assign(url) { _href = url; };
		public function replace(url) { _href = url; };
		public function reload() { };
		public function resolveURL(url) { return url; throw SYNTAX_ERR; };
		public function get hostname() { return _hostname };	
		public function set hostname(hostname) { _hostname = hostname; assign(href); };

	}
	dynamic public class HTMLDocument extends WebIDL {
		private var images;
		public var body;

		public function get location() {}; 
		public function HTMLDocument(window) {
			super(window);
		//	OverrideBuiltins(this);
		}
		// public function open(type = null,replace = null) {};
		public function open(url,name,features,replace = false) {};
	}

	dynamic public class Document extends WebIDL { // Deprecated?
		private var _body; public function get body() { return _body; };
		private var _window;
		private var t;
		private var exists = {};
		private var zindex = [];

		public function addEventListener(e,fn,bubble=false) {
                	// var n = new com.w3canvas.ascanvas.EventTarget(window);
			_window.addEventListener(e,fn,bubble);
		};
		public function removeEventListener(e,fn,bubble=false) {};
		public function createElement(e) {
			var Element;
			var tagName = String(e).toUpperCase();
			if(tagName == 'CANVAS') return new HTMLCanvasElement(this);
			if(tagName == 'BODY') return new HTMLBodyElement(this);
			return new HTMLElement(tagName,null,this);
			// both are in com/w3canvas/ascanvas/HTMLCanvasElement.as
			// tag, css attributes, ownerDocument [object that created this element]
			// parentNode would be defined via appendChild
 		}
		public function appendChild(a,parentNode=null) {
			var s = a.toSprite();
			if('id' in a) exists[a.id] = a;
			if(a.style && a.style.display != 'none') {
				var x=0,y=0,z=a.style.zIndex||0;
				zindex.push(z); zindex.sort();
				while((y = zindex.indexOf(z,y)) > 0) { x = y; y+=1; };
				_body.toSprite().addChildAt(s,x);
			}
		}
		public function getElementById(a) {
			if(a in exists) return exists[a];
			return;
			if(!t) {
				t=new flash.text.TextField();
				window.addChild(t);
				t.text='Debug code';
				t.x=200;
				t.y=450;
			}
			return t;
		}
		private function load() {
			var body = this._body.toSprite();
			if(true||false) { // body.bgcolor) {
				body.graphics.beginFill(0xF0F0FF);
				body.graphics.drawRect(0,0,200,200);//window.innerWidth,window.innerHeight);
			} body.width = 200; body.height = 200; body.x=0; body.y=0;
			_window.addChild(body);
		}	

		public function Document(type='about:blank') {
			// super(window);
			var document = this;
			// HTMLDocument [always required]
			documentElement = document.createElement('html');
			_body = document.createElement('body');
			_window = window;
			load();
			if(type == 'about:blank') return;
			type = 'text/html';
			if(type == 'text/svg'); // Mix in the SVGDocument
  			return;
 		}
                public function toString() { return "[object Document]"; }
                public function toSource() { return "Content-Type: text/html\r\n\r\n"; }
                public function toJSON() { return "new Document()"; };
                public function toSprite() { return _body.toSprite; }
	}


/*
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	getQualifiedClassName
	getDefinitionByName
	var desc:XML = flash.utils.describeType(o);
*/
/*
   dynamic public class Navigator extends ExpandoMixin {
		public function Navigator() {
			ImplementedOn(NavigatorID);
			ImplementedOn(NavigatorOnline);
			ImplementedOn(NavigatorAbilities);
		}
	}
	var Navigator = { 'appName': 'Flash' };
*/

	public class NavigatorID {
		public function get appName() { return _appName; };
		public function get appVersion() { return _appVersion; };
		public function get platform() { return _platform; };
		public function get userAgent() { return _userAgent; };
	}

	public class NavigatorOnLine {
		public function get onLine() { return true; };
	};

	public class NavigatorAbilities {
		public function registerProtocolHandler(scheme,url,title) {};
		public function registerContentHandler(mimeType,url,title) {};
		public function getStorageUpdates() {};
	};

}
