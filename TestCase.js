// include "ASCanvas.as"

// the last line in this file is: window.onload = testCase;

var testCase = function() {
	var t = [];

	var canvas = document.createElement('canvas');
	canvas.width='600px';
	canvas.style.height='400px';
	canvas.style.position='absolute'; // default, others not currently supported 
	canvas.style.left='10px';
	canvas.style.top='10px';

	var ctx = canvas.getContext('2d');

t.push(function() {
	ctx.fillStyle='rgba(0,0,255,.5)';
	ctx.save();
	ctx.fillStyle='rgba(0,0,255,1)';
	ctx.restore();
	ctx.fillRect(0,0, 400,400);
});

t.push(function() {
	canvas.onclick = function(e) { throw new Error("Spoon!"+this); };
	canvas.onclick = 'test'; canvas.onclick = function(e) { throw new Error("Test"); };
	var context = ctx;
	var style = canvas.style;
	var t;
	var feh = function(e) {
			if(!t) { var t=new flash.text.TextField(); window.addChild(t);}
			context.fillStyle = 0x00F0F0;
       		t.text='hello'+context.fillStyle+'x'+style.height+': '+style.left+": ";//+canvas.onclick;
			t.x=200;
			t.y=450;       
	};
	canvas.onclick = '';//feh;

	//	canvas.addEventListener('click',feh);
	//feh('');
});

	//	window.addChild(canvas.toSprite());
	//	document.body.appendChild(canvas);
	//	window.graphics.beginFill(0xFF00F0);
	//	window.graphics.drawCircle(200, 40, 40);
	// return

	window.addChild(canvas.toSprite());

	function getcolor(a) { return 0xFF0000; } 
	var hover = function(c,color) { c.save(); c.fillStyle=color; c.fillRect(0,0,c.canvas.width,c.canvas.height); c.restore(); };
	var fn = function(_,fn) { var arg = [],i=2; for(;i<arguments.length;i++) arg.push(arguments[i]);
		return function() { fn.apply(_,arg); }; }; 
	var ctx = canvas.getContext('2d');

	hover(ctx,'rgba(0,0,255,.5)');

	ctx.fillStyle='green';
ctx.scale(1.5,1.5);
ctx.moveTo(10,10);
	ctx.lineTo(100,100);
	ctx.lineTo(10,100);
	
	ctx.lineTo(10,10);
	ctx.closePath();
	ctx.fill();

t.push(function() {
	ctx.fillStyle='blue';
	ctx.font = '16px Arial';
	ctx.fillText("Testing",canvas.style.width-100,canvas.style.height-100);
});

t.push(function() {
	canvas.addEventListener('mousedown', fn(this,hover,ctx,'green'));
	canvas.addEventListener('mouseup', fn(this,hover,ctx,'black'));
	canvas.addEventListener('mouseout', fn(this,hover,ctx,'blue'));
	canvas.addEventListener('mouseover', fn(this,hover,ctx,'red'));
});

}

window.onload = testCase;
