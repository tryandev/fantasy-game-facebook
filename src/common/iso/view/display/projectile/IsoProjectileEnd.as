package common.iso.view.display.projectile
{
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.GlowFilter;

	public class IsoProjectileEnd extends Sprite {
		
		// Class very similar to IsoProjectileStart, but too early to combine!!!! trust me
		
		public static const ANI_FINISH:String = 'aniFinish';
		
		private var _mc:MovieClip;
		
		public function IsoProjectileEnd(inMC:MovieClip, inX:Number, inY:Number) {
			//this.blendMode = BlendMode.ADD;
			//this.filters = [new GlowFilter(0xFF7700,1,24,24,2,3)];
			if (inMC) {
				addChild(inMC);
				_mc = inMC;
				_mc.stop();
				_mc.addFrameScript(_mc.totalFrames-1, onMcFinish) ;
			}else{
				drawDefault();
			}
			x = inX;
			y = inY;
			visible = false;
		}
		
		private function drawDefault():void {
			var g:Graphics = this.graphics;
			g.beginFill(0xFFFF44, 0.75);
			g.drawRect(-60, -60, 120, 120);
			g.drawRect(-50, -50, 100, 100);
			g.endFill();
		}
		
		public function dispose():void {
			this.graphics.clear();
			if (parent) {
				parent.removeChild(this);
			}
			
			if (_mc) {
				_mc.stop();
				removeChild(_mc);
				_mc = null;
			}
		}
		
		public function play():void {
			visible = true;
			_mc && _mc.gotoAndPlay(1);
		}
		
		private function onMcFinish(e:Event = null):void {
			_mc && _mc.stop();
			dispatchEvent(new Event(ANI_FINISH));
			dispose();
		}	
	}
}