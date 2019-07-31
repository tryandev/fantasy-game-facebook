package common.iso.control.ai
{
	import com.greensock.TweenNano;
	import com.greensock.easing.Cubic;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	import com.greensock.easing.Quart;
	import com.greensock.easing.Sine;
	import com.raka.iso.map.MapConfig;
	import com.raka.media.sound.RakaSoundManager;
	
	import common.iso.control.audio.FrameLabelSound;
	import common.iso.model.FrameAction;
	import common.iso.view.containers.IsoMap;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoCharacter;
	
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.getTimer;

	public class MoverAvatar extends MoverCharacter
	{
		private var _path:Array;
		private var _nodesPending:Array;
		private var _isWalking:Boolean;
		private var _frameLabel:String = null;

		public function MoverAvatar(inClient:IsoCharacter)
		{
			super(inClient);
			speedRatio = 6;
		}
		
		public override function stop():void 
		{
			super.stop();
			
			_nodesPending = null;
			_path = [];
			if (!_isWalking) {
//				trace('MoverAvatar stop() dispatch Mover.ON_ANI_IDLE');
				dispatchEvent(new Event(MoverCharacter.ON_ANI_IDLE));
			}else{
				TweenNano.killTweensOf(this);
				_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_IDLE, false);
				TweenNano.to(this, Infinity, {onUpdate: updateFrameSkipByTime, onUpdateParams: [1/30 * 1000]});
			}
		}
		
		public function walkPath(nodes:Array):void
		{
			_isWalking = true;
			walkNodeGoal(nodes);
		}
		
		public function walkStop():void {
			walkNodeGoal([]);
		}
		
		public function walkNodeGoal(inAStarNodes:Array, keepVelocity:Boolean =  false):void
		{
			var isoMap:IsoMap = _client.parent.parent as IsoMap;

			if (_isWalking)
			{
				_nodesPending = inAStarNodes;
				_path = [];
				//trace('isWalking, set nodePending');
			}
			else
			{
				_path = isoMap.pathFind(new AStarNode(_client.isoX, _client.isoY), inAStarNodes);
				_path.pop();
				if (_path.length)
				{
					_isWalking = true;
					walkNodeNext(true, keepVelocity);
				}
				else
				{
//					trace('no path');
					TweenNano.killTweensOf(this);
					_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_IDLE, false);
					TweenNano.to(this, Infinity, {onUpdate: updateFrameSkipByTime, onUpdateParams: [1/30 * 1000]});
					dispatchEvent(new Event(MoverCharacter.ON_ANI_IDLE));
				}
			}
		}
		
		private function walkNodeFinish():void {
			_client.isoX = tweenIsoX;
			_client.isoY = tweenIsoY;
			super.updateFrameByDistance();
			
			walkNodeNext();
		}
		
		private function walkNodeNext(firstNode:Boolean = false, keepVelocity:Boolean =  false):void
		{
			if (!_path.length)
			{
				_isWalking = false;
				if (_nodesPending && _nodesPending.length)
				{
					//trace('path empty but nodePending');
					walkNodeGoal(_nodesPending, true);
					_nodesPending = null;
				} else {
					TweenNano.killTweensOf(this);
					_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_IDLE, false);
					TweenNano.to(this, Infinity, {onUpdate: updateFrameSkipByTime, onUpdateParams: [1/30 * 1000]});
					//trace('path empty done');
					//trace('MoverAvatar walkNodeNext() dispatch Mover.ON_ANI_IDLE');
					dispatchEvent(new Event(MoverCharacter.ON_ANI_IDLE));
				}
				return;
			}
			var aNode:AStarNode = _path.pop();
			var diagonal:Number = 0;
			diagonal += Math.pow(aNode.isoX - _client.isoX, 2);
			diagonal += Math.pow(aNode.isoY - _client.isoY, 2);
			diagonal = Math.sqrt(diagonal);
			_dX = aNode.isoX - _client.isoX;
			_dY = aNode.isoY - _client.isoY;
			_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_WALK);

			var easingFunc:Function;
			var durMulti:Number = 1;
			
			/*if (firstNode && !_path.length) {
				easingFunc = Sine.easeInOut;
				durMulti = Math.PI / 2;
			} else if (firstNode) {
				easingFunc = Sine.easeIn;
				durMulti = Math.PI / 2;
			} else if (!_path.length) {
				easingFunc = Sine.easeOut;
				durMulti = Math.PI / 2;
			} else {
				easingFunc = Linear.easeNone;
			}*/
			
			if (firstNode && !_path.length) {
				easingFunc = Quad.easeInOut;
				durMulti = 2;
			} else if (firstNode && !keepVelocity) {
				easingFunc = Quad.easeIn;
				durMulti = 2;
			} else if (!_path.length) {
				easingFunc = Quad.easeOut;
				durMulti = 2;
			} else {
				easingFunc = Linear.easeNone;
			}
			
			/*if (firstNode && !_path.length) {
				easingFunc = Cubic.easeInOut;
				durMulti = 3;
			} else if (firstNode) {
				easingFunc = Cubic.easeIn;
				durMulti = 3;
			} else if (!_path.length) {
				easingFunc = Cubic.easeOut;
				durMulti = 3;
			} else {
				easingFunc = Linear.easeNone;
			}*/
			
			//TweenNano.to(this, 1 / _speed * diagonal, {tweenIsoX:targetIsoX, tweenIsoY:targetIsoY, ease:Linear.easeNone, onUpdate:this.updateFrameByDistance, onComplete:nextTileFinish});
			//TweenNano.to(_client, 1 / _speed * diagonal * durMulti, {isoX:aNode.isoX, isoY:aNode.isoY, ease:easingFunc, /*Linear.easeNone,*/ onUpdate:this.updateFrameByDistance, onComplete:walkNodeNext});
			tweenIsoX = _client.isoX;
			tweenIsoY = _client.isoY;
			TweenNano.killTweensOf(this);
			TweenNano.to(this, 1 / _speed * diagonal * durMulti, {tweenIsoX:aNode.isoX, tweenIsoY:aNode.isoY, ease:easingFunc, onUpdate:this.updateFrameSkipByDistance, onComplete:walkNodeFinish});
		}
		
		protected override function attackComplete():void {
			super.attackComplete();
		}
		
		protected override function updateFrameSkipByTime(inFrameSpeed:int = 100, inSkipFrames:Boolean = true):void
		{
			super.updateFrameSkipByTime(inFrameSpeed, inSkipFrames);
			
			if (!_client)
				return;
			
			var _clientMC:MovieClip = _client.getMC();
			
			if (!_clientMC)
				return;
			
			
			super.doFrameLabelHits();	
			super.doFrameLabelLaunches();	
			super.doFrameLabelShakes();			
			super.doFrameLabelSounds();
			//trace('MoverAvatar updateFrameSkipByTime: currentFrameLabel = ' + _frameLabel);
		}
		
		private function set frameLabel(value:String):void {
			
		}
		
		private function get frameLabel():String {
			return _frameLabel;
		}
		
		public function get isWalking():Boolean {
			return _isWalking;
		}
	}
}
