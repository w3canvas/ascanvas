/*

		CanvasEvent by Jumis, Inc
		Updated: 2009-05-18

	Unless otherwise noted:
	All source code is hereby released into public domain.
	http://creativecommons.org/publicdomain/zero/1.0/
	http://creativecommons.org/licenses/publicdomain/

    Lead development by Charles Pritchard with thanks to:
	The World Wide Web Consortium ( http://www.w3.org/TR/DOM-Level-3-Events/idl-definitions.html )
	Wikipedia ( http://en.wikipedia.org/wiki/DOM_Events )
	Some DOM Events target Adobe Flash 9 Event Constants
*/
package com.w3canvas.ascanvas {
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import flash.events.MouseEvent;
//	import flash.events.Event;
//	import flash.events.MouseEvent;
//	import flash.events.KeyboardEvent;
//	import flash.events.EventDispatcher;

	public class EventTarget {
		public var public_vars = [];
		public var public_call = ['addEventListener','removeEventListener','dispatchEvent','handleEvent','createEvent'];
		private var element;

		public function EventTarget(container = null) {
			element = container === null ? this : container;
			for(var i in dom_events) public_vars.push(i);
		}

		// EventTarget
		public function addEventListener(type,fn,bubble=false) {
			return element.addEventListener(getHandle(type),fn,false);
		}; 
		public function removeEventListener(type,fn,bubble=false) {
			return element.removeEventListener(getHandle(type),fn,false);
		}; 
		public function dispatchEvent(e) {
			return element.dispatchEvent(e);
		};

		// EventListener
		public function handleEvent(e) {};

		// DocumentEvent
		public function createEvent(type) {};

		// Actual implementation
		//	FIXME: Flash API useCapture vs DOM API bubble
		private function getHandle(type) {
			if(type in dom_events) type = dom_events[type][0];
			if(type in flash_events) type = flash_events[type];
			return type;
		}

		private const flash_events = {
			'click': flash.events.MouseEvent.CLICK,
			'dblclick': flash.events.MouseEvent.DOUBLE_CLICK,
			'mousedown': flash.events.MouseEvent.MOUSE_DOWN,
			'mouseup': flash.events.MouseEvent.MOUSE_UP,
			'mouseover': flash.events.MouseEvent.MOUSE_OVER,
			'mousemove': flash.events.MouseEvent.MOUSE_MOVE,
			'mouseout': flash.events.MouseEvent.MOUSE_OUT
		}

		// attribute: [ type, bubbles, cancelable ]
		private const dom_events = {
//	Mouse
			'onclick': ['click',true,true],
			'ondblclick': ['dblclick',true,true],
			'onmousedown': ['mousedown',true,true],
			'onmouseup': ['mouseup',true,true],
			'onmouseover': ['mouseover',true,true],
			'onmousemove': ['mousemove',true,false],
			'onmouseout': ['mouseout',true,true],
			'oncontextmenu': ['contextmenu',true,true],
//	Keyboard
			'onkeypress': ['keypress',true,true],
			'onkeydown': ['keydown',true,true],
			'onkeyup': ['keyup',true,true],
//	Object
			'onload': ['load',false,false],
			'onunload': ['unload',false,false],
			'onabort': ['abort',true,false],
			'onerror': ['error',true,false],
			'onreadystatechange': ['readystatechange',false,false],
			'onbeforeunload': ['beforeunload',false,true],
//	Frame
			'onstop':['stop',false,false],
//			'onresize': ['resize',true,false],
			'onmove': ['move',true,false],
			'onscroll': ['scroll',true,false],
			'onbeforeprint': ['beforeprint',false,false],
			'onafterprint': ['afterprint',false,false]
		};
	}

	public class DOMEvent {
		public var CAPTURING_PHASE = 1;
		public var AT_TARGET = 2;
		public var BUBBLING_PHASE = 3;
		public var type;
		public var target;
		public var currentTarget;
		public var eventPhase;
		public var bubbles = false;
		public var cancelable = false;
		public var timeStamp;
		public function stopPropagation() {};
		public function preventDefault() {};
		public function DOMEvent(eventTypeArg,canBubbleArg,cancelableArg) {
			this.type = eventTypeArg;
			this.bubbles = canBubbleArg;
			this.cancelable = cancelableArg;
		}	
	}

	public class UIEvent extends DOMEvent {
		public var view;
		public var detail;
		public function UIEvent(typeArg,canBubbleArg,cancelableArg,viewArg,detailArg) {
			this.view = viewArg;
			this.detail = detailArg;
			super(typeArg,canBubbleArg,cancelableArg);
		} 
	}

	public class MouseEvent extends UIEvent {
 		public var screenX;
		public var screenY;
		public var clientX;
		public var clientY;
		public var ctrlKey = false;
		public var shiftKey = false;
		public var altKey = false;
		public var metaKey = false;
		public var button; // Key
		public var relatedTarget;
		public function MouseEvent(typeArg, 
			 canBubbleArg, 
			 cancelableArg, 
			 viewArg, 
			 detailArg, 
			 screenXArg, 
			 screenYArg, 
			 clientXArg, 
			 clientYArg, 
			 ctrlKeyArg, 
			 altKeyArg, 
			 shiftKeyArg, 
			 metaKeyArg, 
			 buttonArg, 
			 relatedTargetArg) {
			super(typeArg,canBubbleArg,cancelableArg,viewArg,detailArg);
		};
	}


	dynamic public class CanvasEvent extends Expando {
		private var element;
		private var sprite;
		private var handler;
		private var events = {};
	
		public function get public_vars() { return handler.public_vars; };
		public function get public_call() { return handler.public_call; };
		public function CanvasEvent(container, target) {
			handler = new EventTarget(target);
			element = container;
		}
		public function addEventListener(type,fn,bubble=false) {
			return handler.addEventListener(type,fn,false);
		};
		public function removeEventListener(type,fn,bubble=false) {
			if(type in events) if(events[type] == fn) delete events[type];
			return handler.removeEventListener(type,fn,false);
		};

		private function bind(scope,fn) {
			if(typeof(fn) != 'function') return function(...args) { return fn; };
//			if(scope == window.global) return fn;
			return function(...args) { return fn.apply(scope,args); };
		}
		public function setter(type,fn) {
			fn = bind(element,fn);
			var flash_type = type;
			if(type in events) this.removeEventListener(type,events[type]);
			this.addEventListener(type,fn);
			events[type] = fn;
		}
		override flash_proxy function setProperty(name:*, value:*):void {
			if(!(name in trait)) sort.push(name);
			_setProperty(name,value);
			return;
		}
		private function _setProperty(name:*,value:*) {
			setter(name,value);
			return trait[name] = value;
		}
		override flash_proxy function callProperty(name:*, ... args):* {
			if(name in handler) return handler[name].apply(this,args);
		}
	}
}

