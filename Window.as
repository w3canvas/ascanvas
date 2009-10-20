/*

		Window by Jumis, Inc

	Unless otherwise noted:
	All source code is hereby released into public domain.
	http://creativecommons.org/publicdomain/zero/1.0/
	http://creativecommons.org/licenses/publicdomain/

	Lead development by Charles Pritchard,
	influenced by HTML 5 from WhatWG.org and WebIDL from W3C.org
*/
package com.w3canvas.ascanvas { 

dynamic public class Window extends WebIDL { // [OverrideBuiltins] interface Window {
	import flash.display.Sprite;
	import flash.display.Shape;

/*
	While working on the WindowProxy|Window->Document chain I decided to write in a few
	of the standard attributes. They're not in use, they are only stubs at the moment.

*/
		// // the current browsing context
		private var _window; public function get window() { return _window; }; // readonly attribute WindowProxy window;
		// private var _self; public function get self() { return _self; }; // readonly attribute WindowProxy self;
		public var name = ''; // attribute DOMString name;

		public function get location() { return 'about:blank'; }; // [PutForwards=href] readonly attribute Location location
		public function set location(location) { open(location); }; // ;

		public function get history() { return {}; }; // readonly attribute History history;
		public function get undoManager() { return {}; }; // readonly attribute UndoManager undoManager;
		public function getSelection() { return {}; }; //   Selection getSelection();
		/* BarProp objects: locationbar, menubar, personalbar, scrollbars, statusbar, toolbar */
		
		public function close() { return; };
		public function focus() { return; };
		public function blur() { return; };
		
		// // other browsing contexts
		public var frames; // [Replaceable] readonly attribute WindowProxy frames;
		public var _length = 0; //  [Replaceable] readonly attribute unsigned long length
		public var __length = true; 
		// public function get length() { return length; };
		// public function set length(length) { _length = length; if(__length) __length = false; }; // ;
		private var _top; public function get top() { return _top; }; // readonly attribute WindowProxy top;
		public var opener; // [Replaceable] readonly attribute WindowProxy frames;
		private var _parent; public function get parent() { return _parent; }; // readonly attribute WindowProxy parent;
		private var _frameElement; public function get frameElement() { return _frameElement; }; // readonly attribute Element frameElement;

		public function open(url=null,target='_blank',features=null,replace=false) { // WindowProxy open 
		// (optional in DOMString url, optional in DOMString target, optional in DOMString features, optional in DOMString replace);
			if(!replace) {
				var childSprite = new Sprite();
				var childWindow = new com.w3canvas.ascanvas.Window(sprite,this);
				if(!(target in _childNodesByName)) {
					if(__length) _length ++;
				}
				_childNodes.push(childWindow);
				_childNodesByName [ target ] = childWindow;
			}
		}
		private var _childNodes = []; /* [OverrideBuiltins] */ // getter WindowProxy (in unsigned long index);
  		private var _childNodesByName = {}; /* [OverrideBuiltins] */ // getter WindowProxy (in DOMString name);

		// private var _navigator; public function get navigator() { return _navigator; }; // readonly attribute Navigator navigator;


// from CSS View
		_innerWidth = 800;
		_innerHeight = 600;
		public function get innerWidth() { return _innerWidth; };
		public function get innerHeight() { return _innerHeight; };


// From nothin

		_document = null;
		public function get document() { return _document; };
		public function set document(documentObject) { assign(documentObject); };
		public function get readyState() { return _readyState; };
		private function set readyState(state) { _readyState=state; };

		_readyState = 0;

		public var windowSprite;
		public var parentNode;

		public var _images = 0;
		public function set images(images) {
			if(document) if(images == 0)
			if(typeof(this.onload) == 'function')
			this.onload.apply(this,[]);
			_images = images;
		};
		public function get images() { return _images; };

		private var events;
		public function Window(windowSprite,parentWindow=null) {
			super();
			_readyState = 0;
			this.windowSprite = windowSprite;
        
			_window = this;
			_self = this;
			frames = this;
			events = new CanvasEvent(this,this.windowSprite);
			Implements(events);
			this.onload = function(e) {};
			this.onresize = function(e) {};
			_readyState = 1;
			_parent = window;
			_top = window; 


			// content = this;
		}
		public function resizeTo(width,height) {
			_innerWidth = width;
			_innerHeight = height;
			if(typeof(this.onresize) == 'function') this.onresize();
		}
		public function toString() {
			return 'about:blank'; // window.location
		}
		function addChild(a) {
			windowSprite.addChild(a);
		}
		function addChildAt(a,b) {
			windowSprite.addChildAt(a,b);
		}
		public function assign(documentObject) {
			if('numChildren' in this) while(this.numChildren) this.removeChildAt(0);
			_readyState = 2;
			images++;
			// windowSprite.addChild(documentObject.toSprite());
			// Careful: Multiple windows can use the same document.
			// This is typically why print-preview hides the original window.
			_document = documentObject;
			images--;
			_readyState = 3;
		}

	}
}
