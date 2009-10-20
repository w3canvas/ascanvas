/*
        CanvasPattern by Jumis, Inc

        Unless otherwise noted:
        All source code is hereby released into public domain.
        http://creativecommons.org/publicdomain/zero/1.0/
        http://creativecommons.org/licenses/publicdomain/

        Based on work by Colin Lueng
*/
package com.w3canvas.ascanvas {
import flash.display.BitmapData;

class CanvasPattern {
	internal static var REPEAT:String = "repeat";
	internal static var REPEAT_X:String = "repeat-x";
	internal static var REPEAT_Y:String = "repeat-y";
	internal static var REPEAT_NO:String = "no-repeat";
	public var patternFill : BitmapData;
	public var url=''; public function toString():String { return String(url); }
	public function CanvasPattern(image:BitmapData,repetition:String){ patternFill = image; }
}

}

