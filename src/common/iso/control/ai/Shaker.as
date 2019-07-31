package common.iso.control.ai
{
	import com.greensock.TweenNano;
	
	import common.iso.control.IsoController;
	
	import flash.display.DisplayObject;

	public class Shaker
	{
		public static var _instance:Shaker;
		
		private var _disposed:Boolean;
		private var _shakerTween:TweenNano;
		private var _client:DisplayObject;
		
		private var _amp:Number;
		private var _cyc:Number;
		private var _dur:Number;
		
		private var _xStart:Number;
		private var _yStart:Number;
		
		public function Shaker(inAmplitude:Number = 5, inCycles:Number = 10, inDuration:Number = 0.5)
		{
			if (_instance) {
				_instance.dispose();
			}
			_instance = this;
			_client = IsoController.gi.isoWorld;
			_xStart = _client.x;
			_yStart = _client.y;
			
			_amp = inAmplitude;
			_cyc = inCycles;
			_dur = inDuration;
			_shakerTween = new TweenNano(this, _dur, {onUpdate: shakeFrame, onComplete: handleComplete});
		}
		
		public function dispose():void {
			if (_disposed) return;
			_disposed = true;
			if (_shakerTween) {
				_shakerTween.complete();
				_shakerTween.kill();
				_shakerTween = null;
			}
			if (_client){
				_client.x = _xStart;
				_client.y = _yStart;
				_client = null;
			}
			if (_instance == this) {
				_instance = null;
			}
		}
		
		private function handleComplete():void {
			dispose();
		}
		
		private function shakeFrame():void {
			var tweenRatio:Number = 1 - _shakerTween.ratio;
			_client.x = _xStart + _amp * Math.cos(_cyc * tweenRatio * Math.PI) * tweenRatio;
			_client.y = _yStart + _amp * Math.sin(_cyc * tweenRatio * Math.PI) * tweenRatio;
		}
	}
}