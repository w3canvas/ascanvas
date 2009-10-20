/*
// Basic HTML/CSS/XMLHttpRequest/Window/Document Object Model

	Canvas2D : v0.1 : 2008.08.05
	ÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑÑ
	add, remove, loader
	requires: window, document.createElement	
*/

import com.gamemeal.html.HTMLCanvasElement;
import flash.display.Sprite;
import flash.display.Stage;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.net.URLRequest;
import flash.events.ProgressEvent;
import flash.events.Event;
import com.util.Base64;

// Network access

// http://www.w3.org/TR/XMLHttpRequest
class XMLHttpRequest {
	private var _src = '';
	private var _readyState = 0;
	private var l = new Loader();
	private var method = 'GET';
	private var methods = ['CONNECT','DELETE','GET','HEAD','OPTIONS','POST','PUT','TRACE','TRACK'];
	private var insecure = ['CONNECT','TRACE','TRACK'];
	private var async = true;

	// SECURITY_ERR, NETWORK_ERR, ABORT_ERR, INVALID_STATE_ERR
	public const SECURITY_ERR = 18;
	public const NETWORK_ERR = 101;
	public const ABORT_ERR = 102;

	public const UNSENT = 0;
	public const OPENED = 1;
	public const HEADERS_RECEIVED = 2;
	public const LOADING = 3;
	public const DONE = 4;

	public var onreadystatechange = function() {};
	public function get readyState () { return this._readyState; };
	private function set readyState (readyState) { this._readyState = readyState; this.onreadystatechange(); };

	private var _status = 0;
	private var _statusText = '';
	public function get status () { return this._status; };
	private function set status (status) { this._status = status; };
	public function get statusText () { return this._statusText; };
	private function set statusText (statusText) { this._statusText = statusText; };
	public function get responseText () { return l.getChildAt(0) as String; };

	var open = function(method,url,async,user,password) {
		var m = method.toUpper();
		if(m in insecure) return false; // SECURITY_ERR
		if(m in methods) this.method = m;
		else this.method = method;

		if(typeof(async) == 'undefined' || async == false) this.async = false;

		this._src = url;
	};
	var setRequestHeader = function(header,value) { };
	var send = function(message) {
		var p = function(e) { this.readyState=4; };
		var q = function(e) { this.readyState=3; };
		l.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE,p);
		l.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,q);
		l.contentLoaderInfo.addEventListener('readystatechange',this.onreadystatechange);
	};
	var abort = function() { };

	function XMLHTTPRequest () {
	};
}

