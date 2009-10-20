/*

		Expando by Jumis, Inc

	Unless otherwise noted:
	All source code is hereby released into public domain.
	http://creativecommons.org/publicdomain/zero/1.0/
	http://creativecommons.org/licenses/publicdomain/

	Lead development by Charles Pritchard, influenced by Brendan Eich
	Namespace work-arounds influenced by Sean Chatman and Garrett Woodworth
	Additional utilities influenced by WebIDL: http://dev.w3.org/2006/webapi/WebIDL/

*/
package com.w3canvas.ascanvas {
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import flash.utils.getQualifiedClassName;

//	[PrototypeRoot]
	public dynamic class Expando extends Proxy {		

		private var _trait = {};
		public function set trait(t) { _trait = t; }
		public function get trait() { return _trait; }
		private var _sort = [];
		public function get sort() { return _sort; }
		public function set sort(s) { _sort = s; }

		public function get length() { return sort.length; };
		public function Expando(traits = null, sorts = null) {
//			_trait = new Object();
//			_sort = new Array();
			return;
			if(trait != null) {
				_trait = traits;
				if(sorts == null) {
					sorts = []; var i;
					for(i in trait) sorts.push(i);
				};
			} else _trait = {};
			if(sorts != null) sort = sorts;
			else sort = [];
		};
		override flash_proxy function setProperty(name:*, value:*):void {
			if(!(name in trait)) _sort.push(name);
			_setProperty(name,value);
		}
		private function _setProperty(name:*,value:*) {
			// who is using this class?
//			_trait[name] = value; return;
			if(name in _trait) _trait[name] = value;
			else if(name in this) this[name] = value;
			else _trait[name] = value;
			return;

			if(name in this) this[name] = value;
			else if (_trait == this) this[name] = value; // prevent infinite loop
			else _trait[name] = value;			
		}
		override flash_proxy function getProperty(name:*):* {
			if(name == 'trait') return _trait;
			return _getProperty(name);
		}
		protected function _getProperty(name) {
			return _trait[name];
		}
		override flash_proxy function hasProperty(name:*):Boolean {
			if(name == 'trait') return true;
			return _hasProperty(name);
		}
		protected function _hasProperty(name:*):Boolean {
			return _trait[name] ? true : false;
		}
		override flash_proxy function deleteProperty(name:*):Boolean {
			if(!(name in trait)) return false;
			delete trait[name];
			var i=0; for(i in _sort) if(_sort[i] == name) delete _sort[i]; // FIXME: use sort.splice ?
		}
		override flash_proxy function nextName(i:int):String {
			return sort[i-1];
		}
		override flash_proxy function nextValue(i:int):* {
			return trait[sort[i-1]];
		}
		override flash_proxy function nextNameIndex(i:int):int {
			return i < length ? i : 0;
		}
		override flash_proxy function getDescendants(a) { return null; }
		override flash_proxy function isAttribute(a:*):Boolean { return false; }
		override flash_proxy function callProperty(name:*, ... args):* {
			if(name == 'hasOwnProperty') return (args[0] in trait); 
			if(name in trait) if(typeof(trait[name])=='function') return trait[name].apply(trait,args);
		}
	}

// OverrideBuiltins  ( don't query prototype chain, just return from getter )

//  [ImplementedOn], [Prototype]
	dynamic public class ExpandoMixin extends Expando {
		public function get root() { return _root; };
		public function set root(parent:*) { _root = parent; };
		public function get self() { return _self; };
		public function set self(s:*) { _self = self; };
		private var _root;
		private var _expando;
		private var _self;
	
		override flash_proxy function callProperty(name:*, ... args):* {
			if(name == 'hasOwnProperty') return (args[0] in super.trait);
			return _callProperty(name).apply(this,args);
			return _callProperty(name).apply(root,args);
			// if(name in root) if(typeof(root[name])=='function') return root[name].apply(root,args);
			// if(name in trait) if(typeof(trait[name])=='function') return super.trait[name].apply(root,args);
		}
		protected function _callProperty(name) {
			if(name in _expando) if(typeof(_expando[name]) == 'function') return _expando[name];
			if(name in trait) if(typeof(trait[name][name]) == 'function') return trait[name][name];
			if(name in _root) if(typeof(_root[name])=='function') return _root[name]; // PrototypeRoot
			throw new Error("Function "+name+" not defined");
		}

		override flash_proxy function getProperty(name:*):* {
			if(name == 'trait') return trait;
			if(name == 'root') return root;
			return _getProperty(name);
		}
		
		// When improperly instantiated, this function may overflow (circular reference)
		override protected function _getProperty(name) {
			if ( typeof(trait[name]) != 'undefined' )
				return trait[name][name];
			if(_root == this) return _expando[name]; // throw new Error("Stack Overflow: "+name);
			if ( typeof(_root[name]) != 'undefined' ) 
				return _root[name];
			return _expando[name];
		}

		override flash_proxy function setProperty(name:*, value:*):void {
			_setProperty(name,value);
		}
		private function _setProperty(name:*,value:*) {
			if(name in trait) return trait[name][name] = value;
			else if(name in _root && _root != trait) return _root[name] = value;
			else {
				if(!(name in _expando)) sort.push(name);
				return _expando[name] = value;
			}
		}
		public function ImplementedOn(obj,names) {
			var i; for(i in names) trait[names[i]] = obj;
		}
		public function ExpandoMixin(traits = null, sorts = null, mix = null, parent=null, expando=null, thisself=null) {
			super(traits,sorts);
			root = (parent == null) ? this : parent;
			_expando = expando == null ? {} : expando;
			self = this; // thisself ? thisself : root;
			if(mix == null) return;

			var r = ''; var s = {};
			for(var i in mix) for(var ii in mix[i][1]) {
				r = mix[i][1][ii];
				s = mix[i][0];
				trait[r] = s;
			}
		}
	}


// Prototype Chain Temporarily Disabled
	dynamic public class ExpandoPrototype extends Expando {
		public function ExpandoPrototype(traits = null, sorts = null) {
			super(traits,sorts);
		}
	}

//  Mixin prototype

//	[Prototype]
	dynamic public class ExpandoPrototypeX extends Expando {
		private var proto = {};
		public function ExpandoPrototypeX(traits = null, sorts = null) {
			super(traits,sorts);
		}
		override flash_proxy function getProperty(name) {
			if(name in trait) return trait[name];
			else if(proto && typeof(proto.getProperty)=='function') return proto.getProperty(name);
			else if (proto) return proto[name];
			return null;
		}
		flash_proxy function set __proto__ (p) {
			proto = p;
		}
		flash_proxy function get prototype() {
			return proto;
		}
		flash_proxy function set prototype(p) {
			proto = p;
		}
		override flash_proxy function hasProperty(name:*):Boolean {
			return name in trait || (proto ? proto.hasProperty(name) : false);
		}
		override flash_proxy function nextName(i:int):String {
			if(proto && typeof(proto.nextName)=='function') if(i >= length) return proto.nextName(i-length);
			return sort[i-1];
		}
		override flash_proxy function nextValue(i:int):* {
			if(proto && typeof(proto.nextValue)=='function') if(i >= length) return proto.nextValue(i-length);
			return trait[sort[i-1]];
		}
		override flash_proxy function nextNameIndex(i:int):int {
			return (proto && i >= length && typeof(proto.nextNameIndex) == 'function') ? proto.nextNameIndex(i-length) : i + 1;
		}	
		override flash_proxy function callProperty(name:*, ... args):* {
			if(name == 'hasOwnProperty') return (args[0] in trait); 
			if(name in trait) return trait[name].apply(trait,args);
			if(proto) return proto[name].apply(trait,args);
		}
	}


// Our best object -- just a copy of ExpandoMixin currently

	dynamic public class WebIDL extends Expando {
		public function get root() { return _root; };
		public function set root(parent:*) { _root = parent; };
		public function get self() { return _self; };
		public function set self(s:*) { _self = self; };
		private var _root;
		private var _expando;
		private var _self;
	
		override flash_proxy function callProperty(name:*, ... args):* {
			if(name == 'hasOwnProperty') return (args[0] in super.trait);
			return _callProperty(name).apply(this,args);
			return _callProperty(name).apply(root,args);
			// if(name in root) if(typeof(root[name])=='function') return root[name].apply(root,args);
			// if(name in trait) if(typeof(trait[name])=='function') return super.trait[name].apply(root,args);
		}
		protected function _callProperty(name) {
			if(name in _expando) if(typeof(_expando[name]) == 'function') return _expando[name];
			if(name in trait) if(typeof(trait[name][name]) == 'function') return trait[name][name];
			if(name in _root) if(typeof(_root[name])=='function') return _root[name]; // PrototypeRoot
			throw new Error("Function "+name+" not defined");
		}

		override flash_proxy function getProperty(name:*):* {
			if(name == 'trait') return trait;
			if(name == 'root') return root;
			return _getProperty(name);
		}
		
		// When improperly instantiated, this function may overflow (circular reference)
		override protected function _getProperty(name) {
			if ( typeof(trait[name]) != 'undefined' )
				return trait[name][name];
			if(_root == this) return _expando[name]; // throw new Error("Stack Overflow: "+name);
			if ( typeof(_root[name]) != 'undefined' )
				return _root[name];
			return _expando[name];
		}

		override flash_proxy function setProperty(name:*, value:*):void {
			_setProperty(name,value);
		}
		private function _setProperty(name:*,value:*) {
			if(name in trait) return trait[name][name] = value;
			else if(name in _root && _root != trait) return _root[name] = value;
			else {
				if(!(name in _expando)) sort.push(name);
				return _expando[name] = value;
			}
		}
		public function Implements(obj,names = null) { // [ImplementedOn], [Supplemental]
			if(names === null) {
				if('public_vars' in obj && obj.public_vars !== null) Implements(obj,obj.public_vars)
				if('public_call' in obj && obj.public_call !== null) Implements(obj,obj.public_call)
			}
			var i; for(i in names) trait[names[i]] = obj;
		}
		public function WebIDL(traits = null, sorts = null, mix = null, parent=null, expando=null, thisself=null) {
			super(traits,sorts);
			root = (parent == null) ? this : parent;
			_expando = expando == null ? {} : expando;
			self = this; // thisself ? thisself : root;
			if(mix == null) return;

			var r = ''; var s = {};
			for(var i in mix) for(var ii in mix[i][1]) {
				r = mix[i][1][ii];
				s = mix[i][0];
				trait[r] = s;
			}
		}
	}



// Experimental: Events and CSS

// Bubble function calls to parent nodes
	dynamic public class ExpandoBubble extends Expando {
		var cancelBubble = false;
		private var proto = {};
		override flash_proxy function callProperty(name:*, ... args):* {
			if(name == 'hasOwnProperty') return (args[0] in trait);
			if(name in trait) {
				trait[name].apply(trait,args);
				if(!cancelBubble) if(proto) proto[name].apply(this,args);
				cancelBubble = false;
			}
		}
	}

// Priority flag in prototype chain 
	dynamic public class ExpandoPriority extends Expando {
		private var proto = {};
		override flash_proxy function getProperty(name) {
			if(proto && proto.hasImportantProperty(name)) return proto.getImportantProperty(name);
			if(name in trait) return trait[name];
			else if(proto) return proto.getProperty(name);
			return null;
		}
	}
}

