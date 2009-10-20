/*

	WindowProxy with ASCanvas

	Copyright 2009 Jumis, Inc
	United States of America
	http://jumis.com/

	Unless otherwise noted:
	All source code is hereby released into public domain.
	http://creativecommons.org/publicdomain/zero/1.0/
	http://creativecommons.org/licenses/publicdomain/

*/

// Supporting Utilities
include "./Base64.as" // by Steve Webster
include "./PNGEnc.as" // by Patrick Mineault and Tinic Uro

// Scripting Requirements
include "./WebIDL.as"
include "./CSSColor.as"
include "./CSSColors.as"
include "./CSSProperties.as"
include "./AbstractView.as"
include "./EventTarget.as"
include "./HTMLElement.as"
include "./HTMLBodyElement.as"
include "./HTMLDocument.as"
include "./Window.as" 

// Timers
import flash.utils.setTimeout;
import flash.utils.setInterval;
import flash.utils.clearTimeout;
import flash.utils.clearInterval;

// Resource Loaders
include "./XMLHttpRequest.as"
include "./Image.as"

// ASCanvas
include "./HTMLCanvasElement.as"
include "./CanvasGradient.as"
include "./CanvasPattern.as"
include "./CanvasCompositing.as"
include "./CanvasPath.as"
include "./CanvasNetwork.as"
include "./CanvasRenderingContext2D.as"

// WindowProxy
var Window = com.w3canvas.ascanvas.Window;
var Document = com.w3canvas.ascanvas.Document;
var CanvasRenderingContext2D = com.w3canvas.ascanvas.CanvasRenderingContext2D;

import flash.display.Sprite;
var window = new Window(new Sprite());
var document = new Document();
var alert = function(a) { throw new Error(a); };
var navigator = { userAgent: 'ASCanvas', appVersion: 'm1' };

window.document = document;
window.alert = alert;
window.navigator = navigator;
window.CanvasRenderingContext2D = CanvasRenderingContext2D;

include "WindowProxy.as"

/*
  Todo

 __resolve to check the global name space for variables and properties
global properties are accessed from the "window." object
The spec says that document should be doing this; OverrideBuiltins.

Some various things that mostly didn't work:

 Object.prototype.myvar -- Probably the best match.
 _global.myvar
 _level0.myvar
 _root.myvar
 global = Global.getInstance();
 global.myvar

 Working with the window object:

 top, parent, frameElement ( alias of parent.documentElement )
 HTMLDocument is always inherited, so document.createElement should work.
 AbstractView.document getDocument() return document;
 onload should wait for Image.as requests to complete.
 It doesn't, currently.
*/
