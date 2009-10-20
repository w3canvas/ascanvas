/*
		CanvasPath by Jumis, Inc
      
	Unless otherwise noted:
        All source code is hereby released into public domain and CC0.
        http://creativecommons.org/publicdomain/zero/1.0/
        http://creativecommons.org/licenses/publicdomain/
	
	Lead development by Charles Pritchard, inspired by ASCanvas milestone one, by Colin Lueng
	Bezier Curves from work by Timothee Groleau and Helen Triolo.
	Non Zero Winding Rule inspired by Christopher Clay
	Fast Non Zero Winding Rule inspired by Ken McElvain
	Vector Filters inspired by Kevin Lindsey and the SVG Filter Effects standard
	Primitive constants target flash.display.GraphicsPath from Adobe Flash 10
	Additional function names from the HTML 5 Canvas standard and the WebIDL standard
	Transforms adjusted for the HTML 5 Canvas standard

	Implementation Notes:

	Flash 9: nonZeroWinding and evenOdd rules must be applied
	to calculate clipping properties within a glyph. Flash 9 uses
	the even-odd rule.

	Flex supports paths via text strings: flex.graphics.Path

*/
package com.w3canvas.ascanvas {

//	Vector / Raster
	import flash.display.BitmapData;
	import flash.display.Graphics;
//	Maths
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
//	Metaprogramming
	import flash.utils.Proxy;

public class CanvasPath {

	public var data = [];
	public var commands = [];

	private var canvas;
	private var g;

//	flash.display.*
//		GraphicsPath.winding = 'nonZero';
// 		GraphicsPathWinding.EVEN_ODD = 'evenOdd';
// 		GraphicsPathWinding.NON_ZERO = 'nonZero';

	private var winding = 'nonZero';
	private var points;
	private var points_length;
	private var points_clear = function() { points = []; points_length = 0; };

	public var transformation = new Matrix();
	private var useTransform = false;
	private var useTransformSkew = false;

	public static const BEGIN_PATH = 17;
	public static const CLOSE_PATH = 18;

	private function get cpx() {
		return data.length > 1 ? data[data.length-2] : 0;
	}
	private function get cpy() {
		return data.length > 1 ? data[data.length-1] : 0;
	}
	private function get cpc() {
		if(!commands.length) return BEGIN_PATH;
		var x = commands.length-1;
		do { if(commands[x] != NO_OP) return commands[x]; } while(--x);
	}

	public var public_call = [
		'scale','rotate','translate','transform','setTransform',
		'closePath','moveTo','lineTo',
		'quadraticCurveTo','bezierCurveTo','arcTo','rect','arc',
		'isPointInPath','beginPath'
	];

	public function CanvasPath(element=null,matrix=null,a=null,b=null,c='nonZero') {
		canvas = element;
		if(matrix != null) transformation = matrix;
		if(a != null) data = a;
		else data = [];
		if(b != null) commands = b;
		else commands = []; 
		if(c == 'evenOdd') winding = 'evenOdd';
		g = this;
		points_clear();
	}

//	Flash API

//	Flash 10: flash.display.GraphicsPathCommand
	public static const NO_OP = 0;
	public static const MOVE_TO = 1;
	public static const LINE_TO = 2;
	public static const CURVE_TO = 3;
	public static const WIDE_MOVE_TO = 4;
	public static const WIDE_LINE_TO = 5;

	public function curveTo(cp1x, cp1y, x, y) {
		data.push(cp1x);
		data.push(cp1y);
		data.push(x);
		data.push(y);
		commands.push(CURVE_TO);
	}
	public function wideMoveTo(x, y) {
		data.push(x);
		data.push(y);
		data.push(x);
		data.push(y);
		commands.push(WIDE_MOVE_TO);
	}
	public function wideLineTo(x, y) {
		data.push(x);
		data.push(y);
		data.push(x);
		data.push(y);
		commands.push(WIDE_LINE_TO);
	}


	private function nonZeroWinding_angle() {
		if(points_length < 3) return falst;
		var sum = 0, i = 0;
		var next1, next2, dx1, dy1, dx2, dy2;
		var l1, l2, nx1, nx2, p, p2;
		for(i=0; i<points_length; i++) {
			next2 = (i+2) % points_length;
			next1 = (i+1) % points_length;
			dx1 = points[next1].x-points[i].x;
			dy1 = points[next1].y-points[i].y;
			dx2 = points[next2].x-points[next1].x;
			dy2 = points[next2].y-points[next1].y;
			l1 = Math.sqrt(Math.pow(dx1,2)+Math.pow(dy1,2));
			l2 = Math.sqrt(Math.pow(dx2,2)+Math.pow(dy2,2));
			l1 = l1 > 0 ? l1 : 1;
			l2 = l2 > 0 ? l2 : 1;
			nx1 = dx1/l1;
			ny1 = dy1/l1;
			nx2 = dx2/l2;
			ny2 = dy2/l2;
			p = (-ny1)*nx2 + (nx1)*ny2;
			p2 = nx1*nx2 + ny1*ny2;
			sum += Math.atan2(p, p2); /* teil */
		}
		return (Math.round(sum) >= 0);
	}

	private function nonZeroWinding_quadrant() {
		if(points_length < 3) return false;
		
		var quadrant = function(x,y,startX,startY) {
			if(x < startX) return y < startY ? 2 : 1;
			else return y < startY ? 3 : 0;
		}

		var startX = 0, startY = 0;
		var wind = 0;
		var a,b;

		var lastQuad = quadrant(lastX, lastY, startX, startY);
		for(i=0;i<points_length;i++) {
			nextQuad = quadrant(points[i].x, points[i].y, startX, startY);
			if(lastQuad == nextQuad);
			else if(((lastQuad+1)&3)==nextQuad) wind++;
			else if(((nextQuad+1)&3)==lastQuad) wind--;
			else {
				a = lastY - points[i].y;
				a *= (startX - lastX);
				b = lastX - points[i].x;
				a += lastY * b;
				b *= lastY;
				if(a > b) wind += 2;
				else wind -= 2;
			}
			lastX = points[i].x;
			lastY = points[i].y; 
		}

	}

// http://www.kevlindev.com/blog/?p=45
	private function pointInPoly() {};

// Cross-compatible API
	public function moveTo(x,y) {
		var p = new Point(x,y);
		points_clear(); points.push(p); points_length++;
		if(useTransform) { var p = transformation.transformPoint(p); x=p.x; y=p.y; };
		data.push(x);
		data.push(y);
		points_length = 1;
		commands.push(MOVE_TO);
	}

	public function lineTo(x,y) {
		if(!points_length) return;
		var p = new Point(x,y);
		points.push(p); points_length++;
		if(useTransform) { var p = transformation.transformPoint(new Point(x,y)); x=p.x; y=p.y; };
		data.push(x);
		data.push(y);
		commands.push(LINE_TO);
	}


// Canvas API
	public function beginPath() {
		commands = []; data = [];
		if(points_length) points_clear();
//		commands.push(BEGIN_PATH);
//		data.push(0);
	}
	public function closePath() {
		if(!points_length) return;
//		commands.push(CLOSE_PATH);
//		data.push(0);
		g.moveTo(cpx,cpy);
	}
	public function rect(x,y,width,height) {
		g.moveTo(x,y);
		g.lineTo(x+width,y);
		g.lineTo(x+width,y+height);
		g.lineTo(x,y+height);
		g.lineTo(x,y);
		g.closePath();
		g.beginPath();
		g.moveTo(x,y);
	}

// Transformations
	private function hasSkew(m) {
		return (m.b != m.c);	
	}
	private function hasTransform(m) {
		return (m.a != 1 || m.d != 1 || (m.b+m.c+m.tx+m.ty) != 0);
	}
	public function rotate(angle) {
		var sin = Math.sin( angle );
		var cos = Math.cos( angle );
		var a = transformation.a;
		var c = transformation.c;
		transformation.a = a*cos - transformation.b*sin;
		transformation.b = a*sin + transformation.b*cos;
		transformation.c = c*cos - transformation.d*sin;
		transformation.d = c*sin + transformation.d*cos;
//		transformation.rotate(angle);
		useTransform = hasTransform(transformation);
	}
	public function scale(sx,sy) {
		transformation.a *= sx;
		transformation.d *= sy;
//		transformation.scale(sx,sy);
		useTransform = hasTransform(transformation);
		useTransformSkew = hasSkew(transformation);
	}
	public function translate(x,y):void{
		var p = transformation.deltaTransformPoint(new Point(x,y));
		transformation.tx += p.x;
		transformation.ty += p.y;
//		transformation.translate(x,y);
		useTransform = hasTransform(transformation);
	}
	public function transform(m11,m12,m21,m22,dx,dy) {
		var m = new Matrix(m11,m12,m21,m22,dx,dy);
		transformation.concat(m);
		useTransform = hasTransform(transformation);
		useTransformSkew = hasSkew(transformation);
	}
	public function setTransform(m11,m12,m21,m22,dx,dy) {
		var m = new Matrix(m11,m12,m21,m22,dx,dy);
		transformation.identity();
		transformation.concat(m);
		useTransform = hasTransform(transformation);
		useTransformSkew = hasSkew(transformation);
	}

// Curves
// Interesting Document: http://www.spaceroots.org/documents/ellipse/
// Also Interesting: http://www.bytearray.org/?p=67

	public function quadraticCurveTo(cp1x,cp1y,x,y) {
		if(!points_length) return;
		if(useTransformSkew) {
			// Convert quadratic to cubic bezier -- is this unnecessary?
			var cp0 = new Point(cpx,cpy), cp3 = new Point(x,y);
			var cp1 = new Point(cpx+(2/3*(cp1x-cpx)),cpy+(2/3*(cp1y-cpy)));
			var cp2 = new Point(cp1.x+(1/3*(x-cpx)),cp1.y+(1/3*(y-cpy)));
			g.bezierCurveTo(cp1.x,cp1.y,cp2.x,cp2.y,x,y);
			return;
		}
		if(useTransform) {
			var p:Point;
			p = transformation.transformPoint(new Point(cp1x,cp1y)); cp1x=p.x; cp1y=p.y; 
			p = transformation.transformPoint(new Point(x,y)); x=p.x; y=p.y; 
		};
		data.push(cp1x);
		data.push(cp1y);
		data.push(x);
		data.push(y);
		commands.push(CURVE_TO);
	}
	
	public function bezierCurveTo(cp1x,cp1y,cp2x,cp2y,x,y) {
		var P0:Point, P1:Point, P2:Point, P3:Point;
		P0 = new Point(cpx,cpy);
		P1 = new Point(cp1x,cp1y);
		P2 = new Point(cp2x,cp2y);
		P3 = new Point(x,y);
		if(useTransform) {
			P0 = transformation.transformPoint(P0);
			P1 = transformation.transformPoint(P1);
			P2 = transformation.transformPoint(P2);
			P3 = transformation.transformPoint(P3);
		}
		g.bezierCurveTo_midpoint(P0,P1,P2,P3);
	}

	public function arcTo(x1,y1,x2,y2,radius,x0,y0) {
		if(!points_length) return;
		
		var theta:Number = Math.atan2(y0-y1, x0-x1)-Math.atan2(y2-y1,x2-x1);
		var lengthFromP1ToT1:Number = Math.abs(radius/Math.tan(theta/2));
		var lengthFromP1ToC1:Number = Math.abs(radius/Math.sin(theta/2));

		var xt0:Number = (x0-x1);
		var yt0:Number = (y0-y1);
		var l:Number = Math.sqrt((xt0*xt0)+(yt0*yt0));
		xt0 = xt0*lengthFromP1ToT1/l+x1;
		yt0 = yt0*lengthFromP1ToT1/l+y1;

		var xt2:Number = (x2-x1);
		var yt2:Number = (y2-y1);
		l = Math.sqrt((xt2*xt2)+(yt2*yt2));
		xt2 = xt2*lengthFromP1ToT1/l+x1;
		yt2 = yt2*lengthFromP1ToT1/l+y1;

		var cx:Number = (xt0+xt2)*0.5-x1;
		var cy:Number = (yt0+yt2)*0.5-y1;
		l = Math.sqrt((cx*cx)+(cy*cy));
		cx = cx*lengthFromP1ToC1/l+x1;
		cy = cy*lengthFromP1ToC1/l+y1;

		var startAngle:Number = (Math.atan2(yt0-cy, xt0-cx));
		var endAngle:Number = (Math.atan2(yt2-cy, xt2-cx));
		var dir:Boolean = (startAngle<endAngle)
		if(x1>x2)dir = !dir;

/* FIXME: Direction
    if(orth_p1p2.y < 0) ea = 2 * piDouble - ea;
    if((sa > ea) && ((sa - ea) < piDouble)) anticlockwise = true;
    if((sa < ea) && ((ea - sa) > piDouble)) anticlockwise = true;
*/
		g.moveTo(x0, y0);
		g.lineTo(xt0, yt0);
		arc(cx,cy,radius,startAngle,endAngle,dir);
	}

	public function arc(cx:Number, cy:Number, radius:Number, startAngle:Number, endAngle:Number, clockwise:*,lastX:Number=NaN,lastY:Number=NaN):void{

//	FIXME: Why are these being converted to degrees?
		startAngle = radianToDegree(startAngle);
		endAngle = radianToDegree(endAngle);
//		FIXME: Throw error, per spec
//		if(startAngle<0)startAngle = 360+startAngle;
		if(endAngle<0)endAngle = 360+endAngle;

		var arc:Number;
		if(clockwise==false||clockwise==0){
			arc = endAngle - startAngle;
		}else{
			arc = 360-(endAngle - startAngle);
			if(arc==0&&endAngle!=startAngle)arc=360;
		}
		
		if (Math.abs(arc)>360)arc = 360;

		var segs:Number = Math.ceil(Math.abs(arc)/45);
		var segAngle:Number = arc/segs;

		var theta:Number,angle:Number;
		if(clockwise==false||clockwise==0){
			theta = (segAngle/180)*Math.PI;
			angle = (startAngle/180)*Math.PI;
		}else{
			theta = -(segAngle/180)*Math.PI;
			angle = (startAngle/180)*Math.PI;		
		}

		var sx:Number = cx+Math.cos(angle)*radius;
		var sy:Number = cy+Math.sin(angle)*radius;

		if(isNaN(lastX)){
			g.moveTo(sx,sy);
		}else{
			g.lineTo(sx,sy);
		}

		var angleMid:Number, bx:Number, by:Number, ctlx:Number, ctly:Number;
		for (var i:int = 0; i<segs; i++) {
			angle += theta;
			angleMid = angle-(theta/2);
			bx = cx+Math.cos(angle)*radius;
			by = cy+Math.sin(angle)*radius;
			ctlx = cx+Math.cos(angleMid)*(radius/Math.cos(theta/2));
			ctly = cy+Math.sin(angleMid)*(radius/Math.cos(theta/2));
			if(useTransform) g.quadraticCurveTo(ctlx, ctly, bx, by);
			else  g.curveTo(ctlx, ctly, bx, by);
		}
	}


/*
 * released to public domain by Timothee Groleau based on work from Helen Triolo.
 * more information: http://timotheegroleau.com/Flash/articles/cubic_bezier_in_flash.htm
 */
	
//	Low Quality

	public function drawCubicBezier_spline(P0:Point, P1:Point, P2:Point, P3:Point) : void {
		var midP_x:Number = (P1.x + P2.x) / 2;
		var midP_y:Number = (P1.y + P2.y) / 2;
		graphics.curveTo(P1.x, P1.y, midP_x, midP_y);
		graphics.curveTo(P2.x, P2.y, P3.x, P3.y);
	}

//	Medium Quality

	// simplified version of the midPoint algorithm by Helen Triolo
	public function drawCubicBezier_midpoint(P0:Point, P1:Point, P2:Point, P3:Point):void {
		
		// calculates the useful base points
		var PA:Point = getPointOnSegment(P0, P1, 3/4);
		var PB:Point = getPointOnSegment(P3, P2, 3/4);
			
		// get 1/16 of the [P3, P0] segment
		var dx:Number = (P3.x - P0.x)/16;
		var dy:Number = (P3.y - P0.y)/16;
			
		// calculates control point 1
		var Pc_1:Point = getPointOnSegment(P0, P1, 3/8);
			
		// calculates control point 2
		var Pc_2:Point = getPointOnSegment(PA, PB, 3/8);
		Pc_2.x -= dx;
		Pc_2.y -= dy;
			
		// calculates control point 3
		var Pc_3:Point = getPointOnSegment(PB, PA, 3/8);
		Pc_3.x += dx;
		Pc_3.y += dy;
			
		// calculates control point 4
		var Pc_4:Point = getPointOnSegment(P3, P2, 3/8);
			
		// calculates the 3 anchor points
		var Pa_1:Point = getMiddle(Pc_1, Pc_2);
		var Pa_2:Point = getMiddle(PA, PB);
		var Pa_3:Point = getMiddle(Pc_3, Pc_4);
		
		// draw the four quadratic subsegments
		graphics.curveTo(Pc_1.x, Pc_1.y, Pa_1.x, Pa_1.y);
		graphics.curveTo(Pc_2.x, Pc_2.y, Pa_2.x, Pa_2.y);
		graphics.curveTo(Pc_3.x, Pc_3.y, Pa_3.x, Pa_3.y);
		graphics.curveTo(Pc_4.x, Pc_4.y, P3.x, P3.y);
	}


//	High Quality

	// nSegments denotes how many quadratic bezier segments will be used to
	// approximate the cubic bezier (default is 4);
	public function drawCubicBezier_tangent(P0:Point, P1:Point, P2:Point, P3:Point, nSegment:Number):Number {
		//define the local variables
		var curP:Point; // holds the current Point
		var nextP:Point; // holds the next Point
		var ctrlP:Point; // holds the current control Point
		var curT; // holds the current Tangent object
		var nextT; // holds the next Tangent object
		var total:Number = 0; // holds the number of slices used
			
		// make sure nSegment is within range (also create a default in the process)
		if (nSegment < 2) nSegment = 4;
	
		// get the time Step from nSegment
		var tStep:Number = 1 / nSegment;
			
		// get the first tangent Object
		curT = {p:P0,l:getLine(P0, P1)};
			
		// move to the first point
		// this.moveTo(P0.x, P0.y);
		
		// get tangent Objects for all intermediate segments and draw the segments
		for (var i:int=1; i<=nSegment; i++) {
			// get Tangent Object for next point
			nextT = getCubicTgt(P0, P1, P2, P3, i*tStep);
			// get segment data for the current segment
			total += sliceCubicBezierSegment(P0, P1, P2, P3, (i-1)*tStep, i*tStep, curT, nextT, 0)
			curT = nextT;
		}
		return total;
	}

//	Supporting Functions

	// this function slices down a cubic Bezier segment to avoid parallel tangents
	// the function returns the number of sub segment used to draw the current segment
	private function sliceCubicBezierSegment(P0:Point, P1:Point, P2:Point, P3:Point, u1:Number, u2:Number, Tu1/*:Tangent*/, Tu2/*:Tangent*/, recurs:Number) : Number {
	
		// prevents infinite recursion
		// if 10 levels are reached the latest subsegment is 
		// approximated with a line (no quadratic curve).
		if (recurs > 10) {
			var P:Point = Tu2.p;
			graphics.lineTo(P.x, P.y);
			return 1;
		}
		
		// recursion level is OK, process current segment
		var ctrlPt:Point = getLineCross(Tu1.l, Tu2.l);
		var d:Number = 0;
			
		// A control point is considered misplaced if its distance from one of the anchor is greater 
		// than the distance between the two anchors.
		if (	(ctrlPt == null) || 
				(distance(Tu1.p, ctrlPt) > (d = distance(Tu1.p, Tu2.p))) ||
				(distance(Tu2.p, ctrlPt) > d) ) {
	
			// total for this subsegment starts at 0
			var tot:Number = 0;
		
			// If the Control Point is misplaced, slice the segment more
			var uMid:Number = (u1 + u2) / 2;
			var TuMid = getCubicTgt(P0, P1, P2, P3, uMid);
			tot += sliceCubicBezierSegment(P0, P1, P2, P3, u1, uMid, Tu1, TuMid, recurs+1);
			tot += sliceCubicBezierSegment(P0, P1, P2, P3, uMid, u2, TuMid, Tu2, recurs+1);
				
			// return number of sub segments in this segment
			return tot;
		
		} else {
			// if everything is OK draw curve
			P = Tu2.p;
			graphics.curveTo(ctrlPt.x, ctrlPt.y, P.x, P.y);
			return 1;
		}
	}

	// Return the bezier location at t based on the 4 parameters
	private function getCubicPt(c0:Number, c1:Number, c2:Number, c3:Number, t:Number):Number{
		var ts:Number = t*t;
		var g:Number = 3 * (c1 - c0);
		var b:Number = (3 * (c2 - c1)) - g;
		var a:Number = c3 - c0 - b - g;
		return ( a*ts*t + b*ts + g*t + c0 );
	}
		
	// Return the value of the derivative of the cubic bezier at t
	private function getCubicDerivative(c0:Number, c1:Number, c2:Number, c3:Number, t:Number):Number {
		var g:Number = 3 * (c1 - c0);
		var b:Number = (3 * (c2 - c1)) - g;
		var a:Number = c3 - c0 - b - g;
		return ( 3*a*t*t + 2*b*t + g );
	}
		
	// returns a tangent object of a cubic Bezier curve at t
	private function getCubicTgt(P0:Point, P1:Point, P2:Point, P3:Point, t:Number) {
		// calculates the position of the cubic bezier at t
		var P:Point = new Point();
		P.x = getCubicPt(P0.x, P1.x, P2.x, P3.x, t);
		P.y = getCubicPt(P0.y, P1.y, P2.y, P3.y, t);
		// calculates the tangent values of the cubic bezier at t
		var V:Point = new Point();
		V.x = getCubicDerivative(P0.x, P1.x, P2.x, P3.x, t);
		V.y = getCubicDerivative(P0.y, P1.y, P2.y, P3.y, t);
		// calculates the line equation for the tangent at t
		var l = getLine2(P, V);
		// return the Point/Tangent object 
		// P is a point with two properties x and y
		// l is a line with two properties a and b
		return {p: P, l: l};
	}

	// Gets a line equation as two properties (a,b) such that (y = a*x + b) for any x
	// or a unique c property such that (x = c) for all y
	// The function takes two points as parameter, P0 and P1 containing two properties x and y
	private function getLine(P0:Point, P1:Point) {
		var l = {a: 0, b:0, c:NaN}; // new Line;
		var x0 : Number = P0.x;
		var y0 : Number = P0.y;
		var x1 : Number = P1.x;
		var y1 : Number = P1.y;
			
		if (x0 == x1) {
			if (y0 == y1) {
				// P0 and P1 are same point, return null
				l = null;
			} else {
				// Otherwise, the line is a vertical line
				l.c = x0;
			}
		} else {
			l.a = (y0 - y1) / (x0 - x1);
			l.b = y0 - (l.a * x0);
		}

		// returns the line object
		return l;
	}
			
	// Gets a line equation as two properties (a,b) such that (y = a*x + b) for any x
	// or a unique c property such that (x = c) for all y
	// The function takes two parameters, a point P0 (x,y) through which the line passes
	// and a direction vector v0 (x,y)
	private function getLine2(P0 : Point, v0:Point) {
		var l = {a: 0, b:0, c:NaN}; // new Line;
		var x0:Number = P0.x;
		var vx0:Number = v0.x;
			
		if (vx0 == 0) {
			// the line is vertical
			l.c = x0
		} else {
			l.a = v0.y / vx0;
			l.b = P0.y - (l.a * x0);
		}
		
		// returns the line object
		return l;
	}
			
	// return a point (x,y) that is the intersection of two lines
	// a line is defined either by a and b parameters such that (y = a*x + b) for any x
	// or a single parameter c such that (x = c) for all y
	private function getLineCross(l0, l1):Point {
		// define local variables
		var a0:Number = (l0 == null)?0:l0.a;
		var b0:Number = (l0 == null)?0:l0.b;
		var c0:Number = (l0 == null)?NaN:l0.c;
		var a1:Number = (l1 == null)?0:l1.a;
		var b1:Number = (l1 == null)?0:l1.b;
		var c1:Number = (l1 == null)?NaN:l1.c;
		var u:Number;

		// checks whether both lines are vertical
		if ((isNaN(c0)) && (isNaN(c1))) {
	
			// lines are not verticals but parallel, intersection does not exist
			if (a0 == a1) return null; 
	
			// calculate common x value.
			u = (b1 - b0) / (a0 - a1);		
				
			// return the new Point
			return new Point(u,(a0*u + b0));
	
		} else {
	
			if (isNaN(c0) != true) {
				if (isNaN(c1) != true) {
					// both lines vertical, intersection does not exist
					return null;
				} else {
					// return the point on l1 with x = c0
					return new Point(c0,(a1*c0 + b1));
				}
	
		} else if (isNaN(c1) != true) {
				// no need to test c0 as it was tested above
				// return the point on l0 with x = c1
				return new Point(c1,(a0*c1 + b0));
			}
		}

		return null;
	}
	
	// return the distance between two points
	private function distance(P0:Point, P1:Point):Number{
		var dx:Number = P0.x - P1.x;
		var dy:Number = P0.y - P1.y;
		return Math.sqrt(dx*dx + dy*dy);
	}
	private function getPointOnSegment(P0:Point, P1:Point, ratio:Number):Point {
		return new Point((P0.x + ((P1.x - P0.x) * ratio)),(P0.y + ((P1.y - P0.y) * ratio)));
	}
	private function getMiddle(P0:Point, P1:Point):Point {
		return getPointOnSegment(P0,P1,.5); // Multiplication and addition are faster than division	
		// return new Point(((P0.x + P1.x) / 2),((P0.y + P1.y) / 2));
	}

	public static function degreeToRadian(degree:Number):Number{
		return degree * Math.PI/180;
	}

	public static function radianToDegree(radian:Number):Number{
		return radian * 180/Math.PI;
	}

}

}

