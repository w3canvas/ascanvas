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


package com.w3canvas.ascanvas {
        import com.w3canvas.ascanvas.Document;
        import com.w3canvas.ascanvas.Window;

        import flash.display.Sprite;
	import flash.display.Stage;
        import flash.display.StageAlign;
        import flash.display.StageScaleMode;
        import flash.events.Event;

	// Make a flash sprite look like the root, flash stage.
	public class StageProxy {
		var align = StageAlign.TOP_LEFT;
		var scaleMode = StageScaleMode.NO_SCALE;
		var stageWidth = 0;
		var stageHeight = 0;
		public function StageProxy(sprite = null) {
			if(sprite === null) sprite = new Sprite();
			this.spriteProxy = sprite;
			this.spriteProxy.addEventListener(Event.RESIZE, resize);
		}
		public function resize() {
			this.stageWidth = this.spriteProxy.width;
			this.stageHeight = this.spriteProxy.height;
		}
		public function toSprite() {
			return this.spriteProxy;
		}
	}

	public class WindowProxy extends Sprite {
		var activeDocument;
		var windowProxy;
		var creator;
		var windowStage; // Flash-specific
		public function WindowProxy(windowProxy = null, activeDocument = null, creator = null) {
			super();
			var Window = com.w3canvas.ascanvas.Window; // Ambigious references from the global namespace.
			var Document = com.w3canvas.ascanvas.Document; // Also ambigious.

			this.windowProxy = (windowProxy === null) ? ( (typeof(window) != 'undefined') ? window : new Window(new Sprite()) ) : windowProxy;
			this.activeDocument = (activeDocument === null) ? ( (typeof(document) != 'undefined') ? document : new Document() ) : activeDocument;
			
			if(typeof(stage) == 'undefined') var stage = { stageWidth: 0, stageHeight: 0 };
			if(creator === null) { this.windowStage = stage; }
			else { this.creator = creator; this.windowStage = creator.windowStage; }
			this.windowStage = stage;

			var that = this;
			this.addEventListener(Event.ADDED_TO_STAGE, function(e) {
				// throw new Error("lok"+[that.windowStage.stageWidth,that.windowStage.stageHeight].join(','));
				// that.resize();
				that.windowStage = e.target.stage;
				that.windowStage.align = StageAlign.TOP_LEFT;
				that.windowStage.scaleMode = StageScaleMode.NO_SCALE;
				that.windowStage.addEventListener(Event.RESIZE, that.resize);
				resize();
				that.windowProxy.assign(that.activeDocument);
			});


                        this.windowStage.align = StageAlign.TOP_LEFT;
                        this.windowStage.scaleMode = StageScaleMode.NO_SCALE;
                        this.x = 0;
                        this.y = 0;

			this.addChild(this.windowProxy.windowSprite);
		}
		private function registerStageEvent(e) {
		
		}
		
		private function resize(e = null) {
			this.windowProxy.resizeTo(windowStage.stageWidth || 800, windowStage.stageHeight || 600);
		}
	}
}

