package common.iso.view.display.projectile
{
	import flash.display.BlendMode;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;

	public class IsoProjectile extends Sprite 
	{
		
		private var _mc:MovieClip;
		
		public function IsoProjectile(inMC:MovieClip, forceDraw:Boolean = false) {
			//this.blendMode = BlendMode.ADD;
			//this.filters = [new GlowFilter(0xFF7700,1,24,24,2,3)];
			if (inMC) {
				addChild(inMC);
				_mc = inMC;
				_mc.stop();
			}else{
				if (forceDraw) drawDefault();
			}
			visible = false;
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
			_mc && _mc.play();
		}
		
		public function stop():void {
			_mc && _mc.stop();
		}
		
		private function drawDefault():void {
			var g:Graphics = this.graphics;
			var yOffset:Number = 0;
			g.beginFill(0xFFFF44, 0.75);
			g.moveTo( 0, 1	+ yOffset);
			g.lineTo( 0, 5	+ yOffset);
			g.lineTo(20, 0	+ yOffset);
			g.lineTo( 0, -5	+ yOffset);
			
			g.lineTo( 0, -1	+ yOffset);
			g.lineTo(-40,-1	+ yOffset);
			g.lineTo(-50,-6	+ yOffset);
			g.lineTo(-70,-6	+ yOffset);
			g.lineTo(-60, 0 + yOffset);
			g.lineTo(-70, 6	+ yOffset);
			g.lineTo(-50, 6	+ yOffset);
			g.lineTo(-40, 1	+ yOffset);
			g.lineTo(  0, 1 + yOffset);
			
			g.endFill();
		}
		
	}
}