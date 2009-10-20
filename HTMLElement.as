package com.w3canvas.ascanvas {
	import com.w3canvas.ascanvas.ExpandoMixin;
	dynamic public class HTMLElement extends ExpandoMixin {
		private var tagName = '';
		private var _parent = {};
		private function get parent() { return _parent; };
		private function set parent(p) { _parent = p; };

		private var ownerDocument = null;
		private var attributes = {};

		private var _style; // ElementCSSInlineStyle
		public function get style() { return _style; };
		public function set style(css) { _style.cssText = css; };

		public function HTMLElement(tag, css, ownerDoc, parent_object = null) {
			if(tag == null) tag = ''; 
			this.tagName = tag.toUpperCase();
			this.ownerDocument = ownerDoc;
			if(css == null) css = {};// id: '', width: null, height: null };
			parent = parent_object == null ? this : parent_object;
			css.tagName = this.tagName;
			_style = new CSS2Properties(css,parent) ;//this);
			// _style = new CSSStyleDeclaration(css,this);
			super(null,null,null,attributes,attributes);
			ImplementedOn(this, ['id','width','height','move','resize']);
		}

//	HTMLElement - Convenience
		public function get id() { return _style.id; };
		public function set id(id) { _style.id = id; };
		// title, lang, dir, className

//	any display element
		public function move() { } 
//	HTMLBlockElement - CSS Hooks
		public function resize() { };
		public function get width() { return _style.width; };
		public function set width(width) { _style.width = width; };
		public function get height() { return _style.height; };
		public function set height(height) { _style.height = height; };

	}
}
