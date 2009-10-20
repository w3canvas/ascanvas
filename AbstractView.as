/*

		AbstractView by Jumis, Inc

	Unless otherwise noted:
	All source code is hereby released into public domain.
	http://creativecommons.org/publicdomain/zero/1.0/
	http://creativecommons.org/licenses/publicdomain/

	Lead development by Charles Pritchard,
	influenced by HTML 5 from WhatWG.org and WebIDL from W3C.org
	See: http://dev.w3.org/csswg/cssom-view/
*/
package com.w3canvas.ascanvas { 
	/* the CSSOM-View for Screen is out of sync with html 5 */
	public class Screen { // interface Screen {
		public var availWidth = 0; // readonly attribute unsigned long availWidth;
		public var availHeight = 0;
		public var width = 0;
		public var height = 0;
		public var colorDepth = 32;
		public var pixelDepth = 32;
		public var availLeft = 0;
		public var availTop = 0;
		public var left = 0;
		public var top = 0;
	}
	public class Media { // interface Media {
		private var _type; // readonly attribute DOMString
		public function get type() { return _type; }; // type;
		public function matchMedium(mediaquery) { return false; }; //  boolean matchMedium(DOMString mediaquery);
	}
	class AbstractView { // [NoInterfaceObject] interface AbstractView {
		private var _document = null; // readonly attribute DocumentView
		public function get document() { return _document; }; // document;
		public function AbstractView(document) {
			_document = document;
		}
		private var _media; // readonly attribute Media
		public function get media() { return _media; }; // media;
	}
	class ScreenView extends AbstractView { // interface ScreenView : AbstractView {
		// // viewport
		private var _innerWidth = 0; // readonly attribute long
		public function get innerWidth() { return _innerWidth; }; // innerWidth;
		private var _innerHeight = 0; // readonly attribute long
		public function get innerHeight() { return _innerHeight; }; // innerHeight;
 		private var _pageXOffset = 0; // readonly attribute long
 		public function get pageXOffset() { return _pageXOffset; }; // pageXOffset;
		private var _pageYOffset = 0; // readonly attribute long
		public function get pageYOffset() { return _pageYOffset; }; // pageYOffset;

		public function scroll(x,y) {}; // void scroll(long x, long y);
		public function scrollTo(x,y) {}; // void scrollTo(long x, long y);
		public function scrollBy(x,y) {}; // void scrollBy(long x, long y);

  		// // client
		private var _screenX = 0; // readonly attribute long
		public function get screenX() { return _screenX; }; // screenX;
		private var _screenY = 0; // readonly attribute long
		public function get screenY() { return _screenY; }; // screenY;
		private var _outerWidth = 0; // readonly attribute long
		public function get outerWidth() { return _outerWidth; }; // outerWidth;
		private var _outerHeight = 0; // readonly attribute long
		public function get outerHeight() { return _outerHeight; }; // outerHeight;

		// // output device
  		private var _screen; // readonly attribute Screen
  		public function get screen() { return _screen; }; // screen;	
  		public function ScreenView(document,screen) {
  			super(document);
  			_screen = screen;
  		}	
	}
	class DocumentView extends WebIDL { // [NoInterfaceObject] interface DocumentView {
		private var _defaultView = null; // readonly attribute AbstractView
		public function get defaultView() { return _defaultView; }; // defaultView;
		private var visualMedia;
		public function DocumentView(defaultView = null) {
			super(this);
			if(defaultView) {
				visualMedia = new ScreenView(defaultView);
				Implements(visualMedia);
			}
			_defaultView = defaultView;
		}
		public function elementFromPoint(x,y) { // Element elementFromPoint(float x, float y);
		}
		public function caretRangeFromPoint(x,y) { // Range caretRangeFromPoint(float x, float y);
		}
	}

}