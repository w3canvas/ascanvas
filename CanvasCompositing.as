/*
		CanvasCompositing by Jumis, Inc

        Unless otherwise noted:
        All source code is hereby released into public domain.
        http://creativecommons.org/publicdomain/zero/1.0/
        http://creativecommons.org/licenses/publicdomain/

        Lead development by Charles Pritchard, with contributions by Mohinder Singh and Michael Deal

*/
package com.w3canvas.ascanvas {
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;

	public class CanvasCompositing {
		public static const pixelCorrection:String = "pixelCorrection";
		public static const flashLogic:String = "flashLogic";
		
		public function CanvasCompositing() {}
		public function GetCompositer(type:String):ICompositer {
			switch (type) {
				case "pixelCorrection":
					return new CompositerUsingPixelCorrection();
					break;
					
				case "flashLogic":
					return new CompositerUsingFlashLogic();
					break;
			}
			return null;
		}
	}

	public interface ICompositer {
		function CompositeBitmap(type:String, image1:BitmapData, image2:BitmapData):BitmapData;
	}

	// Based on work by Mohinder Singh
	public class CompositerUsingFlashLogic implements ICompositer {

		public function CompositerUsingFlashLogic() {}
		public function CompositeBitmap(type:String, image1:BitmapData, image2:BitmapData):BitmapData
		{
			var containerSprite:Sprite = new Sprite();
			containerSprite.blendMode = BlendMode.LAYER;
			var firstBitmap:Bitmap = null;
			var secondBitmap:Bitmap = null;
			var alphaBitmap:Bitmap = null;

			switch (type) {
				case "xor":
				{
					var first:Sprite = new Sprite();
					containerSprite.addChild(first);
					first.blendMode = BlendMode.LAYER;

					firstBitmap = new Bitmap(image1);
					first.addChild(firstBitmap);
		
					secondBitmap = new Bitmap(image2);
					first.addChild(secondBitmap);
					secondBitmap.blendMode = BlendMode.ERASE;

					var second:Sprite = new Sprite();
					containerSprite.addChild(second);
					second.blendMode = BlendMode.LAYER;
					
					var firstBitmap2:Bitmap = new Bitmap(image2);
					second.addChild(firstBitmap2);
		
					secondBitmap = new Bitmap(image1);
					second.addChild(secondBitmap);
					secondBitmap.blendMode = BlendMode.ERASE;
					
					break;
				}
					
				case "source-over":
				{
					firstBitmap = new Bitmap(image1);
					containerSprite.addChild(firstBitmap);
					secondBitmap = new Bitmap(image2);
					containerSprite.addChild(secondBitmap);
					break;
				}

				case "destination-over":
				{
					firstBitmap = new Bitmap(image2);
					containerSprite.addChild(firstBitmap);
					secondBitmap = new Bitmap(image1);
					containerSprite.addChild(secondBitmap);
					break;
				}
				
				case "source-out":
				{
					firstBitmap = new Bitmap(image2);
					containerSprite.addChild(firstBitmap);
		
					secondBitmap = new Bitmap(image1);
					containerSprite.addChild(secondBitmap);
					secondBitmap.blendMode = BlendMode.ERASE;
					break;
				}
				
				case "destination-out":
				{
					firstBitmap = new Bitmap(image1);
					containerSprite.addChild(firstBitmap);
		
					secondBitmap = new Bitmap(image2);
					containerSprite.addChild(secondBitmap);
					secondBitmap.blendMode = BlendMode.ERASE;
					break;
				}
				
				case "copy":
				{
					firstBitmap = new Bitmap(image2);
					containerSprite.addChild(firstBitmap);
					break;
				}
				
				case "source-in":
				{
					firstBitmap = new Bitmap(image2);
					containerSprite.addChild(firstBitmap);
					secondBitmap = new Bitmap(image1);
					containerSprite.addChild(secondBitmap);
					
					secondBitmap.blendMode = BlendMode.ALPHA;
					break;
				}

				case "destination-in":
				{
					firstBitmap = new Bitmap(image1);
					containerSprite.addChild(firstBitmap);
					secondBitmap = new Bitmap(image2);
					containerSprite.addChild(secondBitmap);
					
					secondBitmap.blendMode = BlendMode.ALPHA;
					break;
				}
				
				case "source-atop":
				{
					firstBitmap = new Bitmap(image1);
					containerSprite.addChild(firstBitmap);
					secondBitmap = new Bitmap(image2);
					containerSprite.addChild(secondBitmap);
					alphaBitmap = new Bitmap(image1);
					containerSprite.addChild(alphaBitmap);

					alphaBitmap.blendMode = BlendMode.ALPHA;
					break;
				}
				
				case "destination-atop":
				{
					firstBitmap = new Bitmap(image2);
					containerSprite.addChild(firstBitmap);
					secondBitmap = new Bitmap(image1);
					containerSprite.addChild(secondBitmap);
					alphaBitmap = new Bitmap(image2);
					containerSprite.addChild(alphaBitmap);

					alphaBitmap.blendMode = BlendMode.ALPHA;
					break;
				}
				
				case "lighter":
				{
					firstBitmap = new Bitmap(image1);
					containerSprite.addChild(firstBitmap);
					secondBitmap = new Bitmap(image2);
					containerSprite.addChild(secondBitmap);

					secondBitmap.blendMode = BlendMode.LIGHTEN;
					break;
				}

				case "darker":
				{
					firstBitmap = new Bitmap(image1);
					containerSprite.addChild(firstBitmap);
					secondBitmap = new Bitmap(image2);
					containerSprite.addChild(secondBitmap);

					secondBitmap.blendMode = BlendMode.DARKEN;
					break;
				}
				
				default:
					break;
			}
			
			var b:BitmapData = new BitmapData(image1.width, image1.height, true,0x00000000);
			b.draw(containerSprite);
			return b;
		}
		
	}

	// Based on work by Mohinder Singh and Michael Deal
	public class CompositerUsingPixelCorrection implements ICompositer {

		public function CompositerUsingPixelCorrection(){}
		public function CompositeBitmap(type:String, image1:BitmapData, image2:BitmapData):BitmapData
		{
			var outImage : BitmapData = new BitmapData(image1.width, image1.height);

			for (var x:int = 0; x < image1.width; ++x) {
				for (var y:int = 0; y < image1.height; ++y) {
					var pixelValue1:uint = image1.getPixel32(x, y);
					var pixelValue2:uint = image2.getPixel32(x, y);
					var alphaValue1:uint = pixelValue1 >> 24 & 0xFF;
					var alphaValue2:uint = pixelValue2 >> 24 & 0xFF;
					var transparent1:Boolean = (alphaValue1 == 0); 
					var transparent2:Boolean = (alphaValue2 == 0);

					switch (type) {
						case "xor":
						{
							if (!transparent1 && transparent2)
								outImage.setPixel32(x, y, pixelValue1); 
							else if (transparent1 && !transparent2)
								outImage.setPixel32(x, y, pixelValue2);
							else
								outImage.setPixel32(x, y, 0x00000000); 
							break;
						}
						
						case "source-over":
						{
							outImage.setPixel32(x, y, MixColors(pixelValue1, pixelValue2));
							break;
						}
		
						case "destination-over":
						{
							outImage.setPixel32(x, y, MixColors(pixelValue2, pixelValue1));
							break;
						}
						
						case "source-out":
						{
							if (transparent1)
								outImage.setPixel32(x, y, pixelValue2);
							else
								outImage.setPixel32(x, y, 0x00000000); 
							break;
						}
						
						case "destination-out":
						{
							if (transparent2)
								outImage.setPixel32(x, y, pixelValue1);
							else
								outImage.setPixel32(x, y, 0x00000000); 
							break;
						}
						
						case "copy":
						{
							outImage.setPixel32(x, y, pixelValue2); 
							break;
						}
						
						case "source-in":
						{
							if (!transparent1)
								outImage.setPixel32(x, y, pixelValue2);
							else
								outImage.setPixel32(x, y, 0x00000000);  
							break;
						}
		
						case "destination-in":
						{
							if (!transparent2)
								outImage.setPixel32(x, y, pixelValue1);
							else
								outImage.setPixel32(x, y, 0x00000000);  
							break;
						}
						
						case "source-atop":
						{
							if (!transparent1) 
								outImage.setPixel32(x, y, MixColors(pixelValue1, pixelValue2));
							else
								outImage.setPixel32(x, y, 0x00000000);
							break;
						}
						
						case "destination-atop":
						{
							if (!transparent2) 
								outImage.setPixel32(x, y, MixColors(pixelValue2, pixelValue1));
							else
								outImage.setPixel32(x, y, 0x00000000);
							break;
						}
						
						case "lighter":
						{
							if (!transparent1 && !transparent2)
								outImage.setPixel32(x, y, Lighten(pixelValue1, pixelValue2)); 
							else if (transparent1 && !transparent2)
								outImage.setPixel32(x, y, pixelValue2);
							else if (!transparent1 && transparent2)
								outImage.setPixel32(x, y, pixelValue1);
							else
								outImage.setPixel32(x, y, 0x00000000); 
							break;
						}
		
						case "darker":
						{
							if (!transparent1 && !transparent2)
								outImage.setPixel32(x, y, Darken(pixelValue1, pixelValue2)); 
							else if (transparent1 && !transparent2)
								outImage.setPixel32(x, y, pixelValue2);
							else if (!transparent1 && transparent2)
								outImage.setPixel32(x, y, pixelValue1);
							else
								outImage.setPixel32(x, y, 0x00000000); 
							break;
						}

						default:
							break;
					}
				}
			}
			return outImage;
		}
		
		private function MixColors(source:uint, dest:uint):uint {
			var outColor:uint = 0;
			
			var aS:Number = (source >> 24 & 0xFF)/255.0;
			var rS:Number = (source >> 16 & 0xFF)/255.0;
			var gS:Number = (source >> 8 & 0xFF)/255.0;
			var bS:Number = (source & 0xFF)/255.0;
			
			var aD:Number = (dest >> 24 & 0xFF)/255.0;
			var rD:Number = (dest >> 16 & 0xFF)/255.0;
			var gD:Number = (dest >> 8 & 0xFF)/255.0;
			var bD:Number = (dest & 0xFF)/255.0;

			var aO:Number = aD + aS*(1 - aD);
			var rO:Number = ( (rD*aD + rS*aS*(1 - aD)) *255.0 ) / aO;
			var gO:Number = ( (gD*aD + gS*aS*(1 - aD)) *255.0 ) / aO;
			var bO:Number = ( (bD*aD + bS*aS*(1 - aD)) *255.0 ) / aO;

			outColor = ((uint(aO * 255.0) << 24) | (uint(rO) << 16) | (uint(gO) << 8) | (uint(bO))); 
			return outColor;
		}
		
		private function Lighten(source:uint, dest:uint):uint {
			var outColor:uint = 0;
			
			var aS:Number = (source >> 24 & 0xFF)/255.0;
			var rS:Number = (source >> 16 & 0xFF);
			var gS:Number = (source >> 8 & 0xFF);
			var bS:Number = (source & 0xFF);
			
			var aD:Number = (dest >> 24 & 0xFF)/255.0;
			var rD:Number = (dest >> 16 & 0xFF);
			var gD:Number = (dest >> 8 & 0xFF);
			var bD:Number = (dest & 0xFF);

			var aO:Number = (aD + aS*(1 - aD))*255.0;
			var rO:Number = Math.max(rS, rD);
			var gO:Number = Math.max(gS, gD);
			var bO:Number = Math.max(bS, bD);

			outColor = ((uint(aO) << 24) | (uint(rO) << 16) | (uint(gO) << 8) | (uint(bO))); 
			return outColor;
		}
		
		private function Darken(source:uint, dest:uint):uint {
			var outColor:uint = 0;
			
			var aS:Number = (source >> 24 & 0xFF)/255.0;
			var rS:Number = (source >> 16 & 0xFF);
			var gS:Number = (source >> 8 & 0xFF);
			var bS:Number = (source & 0xFF);
			
			var aD:Number = (dest >> 24 & 0xFF)/255.0;
			var rD:Number = (dest >> 16 & 0xFF);
			var gD:Number = (dest >> 8 & 0xFF);
			var bD:Number = (dest & 0xFF);

			var aO:Number = (aD + aS*(1 - aD))*255.0;
			var rO:Number = Math.min(rS, rD);
			var gO:Number = Math.min(gS, gD);
			var bO:Number = Math.min(bS, bD);

			outColor = ((uint(aO) << 24) | (uint(rO) << 16) | (uint(gO) << 8) | (uint(bO))); 
			return outColor;
		}
	}

}


