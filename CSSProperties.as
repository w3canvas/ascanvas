/*
		CanvasDOM by Jumis, Inc
		FIXME: This is just an ".attributes" implementation with sprinkles

	Unless otherwise noted:
	All source code is hereby released into public domain.
	http://creativecommons.org/publicdomain/zero/1.0/
	http://creativecommons.org/licenses/publicdomain/

        Lead development by Charles Pritchard
	Influenced by
	The World Wide Web Consortium ( http://www.w3.org/TR/DOM-Level-3-Events/idl-definitions.html )
	Wikipedia ( http://en.wikipedia.org/wiki/DOM_Events )
*/
package com.w3canvas.ascanvas {

// CSSStyleDeclaration
// These throw DOMException on Error

//  FIXME: ExpandoMutableEvents: DOMAttrModified / propertychange
	dynamic public class CSS2Properties extends Expando {

		private var root = null;
		public function CSS2Properties(attr = null, parent=null) {
			super(attr);
			if(parent) root = parent;
			trait = super.trait;
		}

//	HTMLBlockElement
		private var element;
		public function get width() { return trait.width; };
		public function set width(width:*):void{
			if(isNaN(width=parseInt(width))) return;
			trait.width = width; 
			if(root) root.resize();
		};
		public function get height() { return trait.height; };
		public function set height(height:*):void{
			if(isNaN(height=parseInt(height))) return;
			trait.height = height;
			if(root) root.resize();
		};
		public function get top() { return trait.top; };
		public function set top(top:*):void{
			if(isNaN(top=parseInt(top))) return;
			trait.top = top;
			if(root) root.move();
		};
		public function get left() { return trait.left; };
		public function set left(left:*):void{
			if(isNaN(left=parseInt(left))) { if(left) throw new Error("no: "+left); else return; }
			trait.left = left;
			if(root) root.move();
		};
		public function get zIndex() { return trait.zIndex; };
		public function set zIndex(zIndex:*):void{
			if(isNaN(zIndex=parseInt(zIndex))) return;
			trait.zIndex = zIndex;
			if(root) root.move();
		};

		private const parseCss = new RegExp('([^{])\s*\{\s*([^}])\s*}','g');
		public function set cssText(css) {
			var cssArr = css.split(parseCss);
			var x,i; var y; var k,v; for(i in cssArr) {
				y = cssArr[i];
				while(true) {
				x = y.indexOf(':');
				if(-1<x) {
					k = cssArr[i].substr(0,x);
					v = cssArr[i].substr(x+1);
					x = k.indexOf('-');
					while(-1<x) {
						k = k.substr(0,x)+k.substr(++x,1).toUpperCase()+k.substr(x+1);
						x = k.indexOf('-');
					}
					x = v.indexOf(';');
					if(-1<x) { y = v.substr(x+1); v = v.substr(0,x); }
					while(v.substr(0,1)==' ') 
						v = v.substr(1);
					trait[k]=v;
					if(x<0) break;	
				} }
			}
			// trait = new CSS2Properties(cssArr,root);
		};
		public function get cssText() { return ''; };

		public function toString() {
			var s=''; for(i in trait) if(i != 'cssText') s+=i+': '+trait[i]+';'; return s;
		}
	}


// Doesn't merge-in yet.

	dynamic public class CSSStyleDeclaration extends CSS2Properties {
//		private var root = null;
		public function getPropertyValue(a) { return trait[a]; };
		public function setProperty(a,b,priority='') { trait[a] = b; };
		public function removeProperty(a) { delete trait[a]; }; 
		public function getPropertyPriority(a) { return ''; };
		override public function get length() { return trait.length; };
		public function get parentRule() { return null; };
		public function CSSStyleDeclaration(css = null, parent=null) {
			super(css,parent);
			if(parent != null) root = parent;
			if(css == null) cssText = '';
			if(typeof(css) == 'object') { trait = css; }
			else if (typeof(css) == 'string') cssText = css;
		}
	}

}

