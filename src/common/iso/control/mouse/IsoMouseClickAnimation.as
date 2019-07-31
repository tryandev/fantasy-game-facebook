package common.iso.control.mouse
{
	import com.greensock.TweenLite;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	public class IsoMouseClickAnimation extends MovieClip
	{
		private var _asset:IsoMouseClickAnimationView;
		
		public function IsoMouseClickAnimation()
		{
			_asset = new IsoMouseClickAnimationView();
			addChild(_asset);
			
			visible = false;
		}
		
		public function click(stageX:Number, stageY:Number):void
		{
			TweenLite.killTweensOf(this, false);
			
			var pos:Point = parent.globalToLocal(new Point(stageX, stageY));
			x = pos.x;
			y = pos.y;
			
			visible = true;
			scaleX = scaleY = 0;
			alpha = 1;
			
			TweenLite.to(this, 0.3, {scaleX: 1, scaleY: 1, alpha: 0, onComplete: onAnimComplete});
		}
		
		public function dispose():void
		{
			
		}
		
		private function onAnimComplete():void
		{
			visible = false;
		}
	}
}