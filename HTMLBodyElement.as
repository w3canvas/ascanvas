package com.w3canvas.ascanvas {
	import com.w3canvas.ascanvas.HTMLElement;
	import flash.display.Sprite;
	dynamic public class HTMLHtmlElement extends HTMLElement {
		private var manifest;
		public function HTMLHtmlElement(ownerDoc = null) {
			super('html',{},ownerDoc,this);
		}
	}
	dynamic public class HTMLHeadElement extends HTMLElement {
		public function HTMLHeadElement(ownerDoc = null) {
			super('head',{},ownerDoc,this);
		}
	}
	dynamic public class HTMLTitleElement extends HTMLElement {
		private var _text;
		private function get text() { return _text; }
		private function set text(text) { _text = text; }
		private function get textContent() { return _text; }
		private function set textContent(text) { _text = text; }
		public function HTMLTitleElement(ownerDoc = null) {
			super('title',{},ownerDoc,this);
		}
	}
	dynamic public class HTMLBodyElement extends HTMLElement {
		private var _background;
		private var document;
		private var bodySprite;

		public function HTMLBodyElement(ownerDoc = null) {
			var width = 0, height = 0;
			super('body', {width: width, height: height}, ownerDoc, this);
			this.document = ownerDoc;
			this.bodySprite = new Sprite();
		}
		override public function move() {
			if(bodySprite === null) return;
			bodySprite.x = style.left || 0;
			bodySprite.y = style.top || 0;
		}
		override public function resize() {
			if(bodySprite === null) return;
			bodySprite.width = style.width;
			bodySprite.height = style.height;
		}
		public function toString() { return "[object HTMLBodyElement]"; }
		public function toSource() { return "<body></body>"; }
		public function toJSON() { return "new HTMLBodyElement()"; };
		public function toSprite() { return bodySprite; }
	}
}
