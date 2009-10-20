/*
        CanvasGradient by Jumis, Inc

        Unless otherwise noted:
        All source code is hereby released into public domain.
        http://creativecommons.org/publicdomain/zero/1.0/
        http://creativecommons.org/licenses/publicdomain/

        Based on work by Colin Lueng
*/
package com.w3canvas.ascanvas {
	import flash.display.InterpolationMethod;
	import flash.display.SpreadMethod;
	import flash.geom.Matrix;
	import com.gamemeal.html.CSSColor;
	
// Adopted for HTML Canvas by Colin Lueng for Adobe Flash 9 GradientType.RADIAL

public class RadialGradient {
	public var matrix : Matrix;
	public var spreadMethod : String=SpreadMethod.PAD;
	public var interpolationMethod : String=InterpolationMethod.RGB;
	public var focalPointRatio : Number=0;
	public var colorStops:Array=[];
	public var url=''; public function toString():String { return String(url); }

	private var gradientStartFrom:int=0;
	private var minRatio:Number=0;
	private var range:Number = 255;
	private var rot:Number=0;
		
	public function RadialGradient(x0:Number,y0:Number,r0:Number,x1:Number,y1:Number,r1:Number){
		//find which radius is longer, that will be outer ring
		var tx:Number,ty:Number,d:Number;
		if(r0>r1){
			//x0,x1 is center
			//gradientStartFrom 0
			tx = x0-r0;
			ty = y0-r0;
			d = r0*2;
			minRatio = r1/r0*255;
			focalPointRatio = Math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0))/(r0-r1);
			rot = Math.atan2(y1-y0, x1-x0);
		}else{
			tx = x1-r1;
			ty = y1-r1;
			d = r1*2;
			minRatio = r0/r1*255;
			focalPointRatio = Math.sqrt((x0-x1)*(x0-x1)+(y0-y1)*(y0-y1))/(r1-r0);
			rot = Math.atan2(y0-y1, x0-x1);
			gradientStartFrom=1;
		}

		range = 255-minRatio;
		matrix = new Matrix();
		matrix.createGradientBox(d,d,rot,tx,ty);
	}
		
	public function addColorStop(offset:Number, color : String) : void{
		if(gradientStartFrom==0)offset = 1-offset;
		colorStops.push(new ColorStop(offset,color));
		colorStops.sortOn('offset');
	}
	
	public function get alphas():Array{
		var ary:Array = [];
		for(var i:int=0;i<colorStops.length;i++){
			ary[i]= ColorStop(colorStops[i]).alpha;
		}
		return ary;
	}
		
	public function get ratios():Array{
		var ary:Array = [];
		for(var i:int=0;i<colorStops.length;i++){
			ary[i]= Math.round(ColorStop(colorStops[i]).offset*range+minRatio);
		}
		return ary;
	}
	
	public function get colors():Array{
		var ary:Array = [];
		for(var i:int=0;i<colorStops.length;i++){
			ary[i]= ColorStop(colorStops[i]).color;
		}
		return ary;
	}
}

// Adopted for HTML Canvas by Colin Lueng for Adobe Flash 9 GradientType.LINEAR

public class LinearGradient {
	public var matrix : Matrix;
	public var spreadMethod : String=SpreadMethod.PAD;
	public var interpolationMethod : String=InterpolationMethod.RGB;
	public var focalPointRatio : Number=0;
	public var colorStops:Array=[];
	public var url=''; public function toString():String { return String(url); }

	public function LinearGradient(x0:Number,y0:Number,x1:Number,y1:Number){
		var h:Number = (x0+x1)/2;
		var k:Number = (y0+y1)/2;
		var d:Number = Math.sqrt((x1-x0)*(x1-x0)+(y1-y0)*(y1-y0));
		var tx:Number=h-d/2; 
		var ty:Number=k-d/2;
		matrix = new Matrix();
		matrix.createGradientBox(d, d, Math.atan2(y1-y0, x1-x0),tx,ty);
	}
	
	public function addColorStop(offset:Number, color : String) : void{
		colorStops.push(new ColorStop(offset,color));
		colorStops.sortOn('offset');
	}
	
	public function get alphas():Array{
		var ary:Array = [];
		for(var i:int=0;i<colorStops.length;i++){
			ary[i]= ColorStop(colorStops[i]).alpha;
		}
		return ary;
	}
	
	public function get ratios():Array{
		var ary:Array = [];
		for(var i:int=0;i<colorStops.length;i++){
			ary[i]= Math.round(ColorStop(colorStops[i]).offset*255);
		}
		return ary;
	}
		
	public function get colors():Array{
		var ary:Array = [];
		for(var i:int=0;i<colorStops.length;i++){
			ary[i]= ColorStop(colorStops[i]).color;
		}
		return ary;
	}
}

class ColorStop {
	public var offset:Number;
	public var color:Number;
	public var alpha:Number;

	public function ColorStop(offset:Number, color : String){
		var c:CSSColor = new CSSColor(color);
		this.color = c.color;
		this.alpha = c.alpha;
		this.offset = offset;
	}
}

}


