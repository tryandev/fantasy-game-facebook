package common.iso.control.ai
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.greensock.TweenNano;
	import com.greensock.easing.Linear;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.IsoController;
	import common.iso.model.FrameAction;
	import common.iso.view.containers.IsoMap;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoCharacter;
	import common.iso.view.display.IsoMonster;
	
	import flash.events.Event;
	import flash.utils.getTimer;

	public class MoverHomeAndFriendTownNPC extends MoverCharacter
	{
		public static const STATE_ANI_IDLE:int = 0;
		public static const STATE_ANI_WALK:int = 1;
		public static const STATE_ANI_DIE:int = 2;
		
		protected var _moveDistanceMin:Number;
		protected var _moveDistanceMax:Number;
		protected var _moveIdleMin:Number;
		protected var _moveIdleMax:Number;
		protected var _moveDirection:int;
		protected var _moveDistance:int;
		protected var _moveIdle:Number;
		protected var _turnDirection:int = (Math.random() > 0.5) ? 1 : -1;
		protected var _mouseOutToWalk:Boolean = true;
		
		protected var _flagStopped:Boolean;
		
		private var _state:int;
		public var targetIsoX:int;
		public var targetIsoY:int;
		
		private var _tweenWalk:TweenNano;
		private var _tweenWalkRatio:Number;
		private var _tweenWalkTime:Number;
		private var _tweenIdleMouse:TweenNano;
		private var _tweenDelayedStart:TweenNano;
		protected var _constrainToBounds:Boolean = true;
		
		private var _paused:Boolean = false;		
		
		public function MoverHomeAndFriendTownNPC(inClient:IsoCharacter)
		{
			super(inClient);

			_speed = 1 + Math.random() * 5;

			_moveDistanceMin = 15; // 15
			_moveDistanceMax = 15; // 15

			_moveIdleMin = 1; //1
			_moveIdleMax = 3; //3
		}
		
		public override function dispose():void
		{
			//trace("MoverMonster dispose");
			TweenNano.killTweensOf(this);
			if (_tweenDelayedStart){
				_tweenDelayedStart.kill();
				_tweenDelayedStart = null;
			}
			if (_tweenIdleMouse){
				_tweenIdleMouse.kill();
				_tweenIdleMouse = null;
			}
			if (_tweenWalk){
				_tweenWalk.kill();
				_tweenWalk = null;
			}
			super.dispose();
		}
		
		public override function start():void
		{
			//trace('MoverMonster start');
			
			super.start();
			
			_moveDistance = _moveDistanceMin + Math.random() * (_moveDistanceMax - _moveDistanceMin);
			_moveDirection = Math.random() * 8;
			_moveIdle = _moveIdleMin + Math.random() * (_moveIdleMax - _moveIdleMin);
			_flagStopped = false;
			TweenNano.killTweensOf(this);
			nextTile();
		}
		
		public override function stop():void 
		{
			
			if (_client.isAlive) {
				state = STATE_ANI_IDLE;
				_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_IDLE, false);
				TweenNano.killTweensOf(this);
				TweenNano.to(this, Infinity, {onUpdate: updateFrameSkipByTime, onUpdateParams: [1/30 * 1000]});
			}
		}
		
		private function changeDirection():void
		{
			_moveDirection = (_moveDirection + 3 + Math.floor(Math.random()*3)) % 8;
		}
		
		protected function nextTile(coord:Array = null, shouldCollide:Boolean = true):void
		{
			// trace('nextTile');
			if (_moveDistance == 0)
			{
				if (_flagStopped || _client.isMouseOverMe) {
					idle();
				} else {
					start();					
				}
				return;
			}

			var isoMap:IsoMap = IsoController.gi.isoWorld.isoMap;

			if (coord == null)
			{
				if (_moveDirection == 0)
				{
					coord = [1, 1];
				}
				else if (_moveDirection == 1)
				{
					coord = [1, 0];
				}
				else if (_moveDirection == 2)
				{
					coord = [1, -1];
				}
				else if (_moveDirection == 3)
				{
					coord = [0, -1];
				}
				else if (_moveDirection == 4)
				{
					coord = [-1, -1];
				}
				else if (_moveDirection == 5)
				{
					coord = [-1, 0];
				}
				else if (_moveDirection == 6)
				{
					coord = [-1, 1];
				}
				else if (_moveDirection == 7)
				{
					coord = [0, 1];
				}
			}

			targetIsoX = _client.isoX + coord[0];
			targetIsoY = _client.isoY + coord[1];

			_dX = coord[0];
			_dY = coord[1];

			if (isoMap.getIsoTileFree(targetIsoX, targetIsoY) /*isoMap.addChildObjTest(targetIsoX, targetIsoY, _client)*/ || !shouldCollide || !_constrainToBounds)
			{
				if(isoMap.isIsoTileOccupied(targetIsoX, targetIsoY))
				{
					var allDirectionsOccupied:Boolean = areAllDirectionsOccupied();
					
					if(allDirectionsOccupied == false)
					{
						changeDirection();
						TweenNano.killTweensOf(this);
						TweenNano.to(this, 0.01, {onComplete:nextTile});
						return;
					}
					
					_moveDistance--;
				}
				else
				{
					if (_client.occupy)
					{
						// Monsters never occupy a tile
					}
					_moveDistance--;
				}
				
			}
			else  
			{
				changeDirection();
				TweenNano.killTweensOf(this);
				TweenNano.to(this, 0.01, {onComplete:nextTile});
				return;
			}

			state = STATE_ANI_WALK;
			_client.changeSprite(coord[0], coord[1], IsoCharacter.ANI_ARRAY_WALK);
			var diagonal:Number = Math.sqrt(coord[0] * coord[0] + coord[1] * coord[1]);
			tweenIsoX = _client.isoX;
			tweenIsoY = _client.isoY;
			TweenNano.killTweensOf(this);
			_tweenWalkTime = 1 / _speed * diagonal;
			_client.mouseActive = true;
			_tweenWalk = new TweenNano(this, _tweenWalkTime, {tweenIsoX:targetIsoX, tweenIsoY:targetIsoY, ease:Linear.easeNone, onUpdate:this.updateFrameSkipByDistance, onComplete:nextTileFinish});
		}

		
		private function areAllDirectionsOccupied():Boolean
		{
			var isoMap:IsoMap = IsoController.gi.isoWorld.isoMap;
			if(isoMap.isIsoTileOccupied(_client.isoX-1, _client.isoY-1) == false && isoMap.getIsoTileFree(targetIsoX, targetIsoY)) return false;
			if(isoMap.isIsoTileOccupied(_client.isoX, _client.isoY-1) == false && isoMap.getIsoTileFree(targetIsoX, targetIsoY)) return false;
			if(isoMap.isIsoTileOccupied(_client.isoX+1, _client.isoY-1) == false && isoMap.getIsoTileFree(targetIsoX, targetIsoY)) return false;
			if(isoMap.isIsoTileOccupied(_client.isoX-1, _client.isoY) == false && isoMap.getIsoTileFree(targetIsoX, targetIsoY)) return false;
			if(isoMap.isIsoTileOccupied(_client.isoX, _client.isoY) == false && isoMap.getIsoTileFree(targetIsoX, targetIsoY)) return false;
			if(isoMap.isIsoTileOccupied(_client.isoX+1, _client.isoY) == false && isoMap.getIsoTileFree(targetIsoX, targetIsoY)) return false;
			if(isoMap.isIsoTileOccupied(_client.isoX-1, _client.isoY+1) == false && isoMap.getIsoTileFree(targetIsoX, targetIsoY)) return false;
			if(isoMap.isIsoTileOccupied(_client.isoX, _client.isoY+1) == false && isoMap.getIsoTileFree(targetIsoX, targetIsoY)) return false;
			if(isoMap.isIsoTileOccupied(_client.isoX+1, _client.isoY+1) == false && isoMap.getIsoTileFree(targetIsoX, targetIsoY)) return false;
			return true;
		}
		
		private function moveToNearestWalkableTile():void
		{
			// circular algorithm to find the closest spot
			var startX:int = _client.isoX - 1;
			var startY:int = _client.isoY - 1;
			
			var layer:int; // TODO - aray - wtf?
			while(true)
			{
				break;
			}
		}
		
		public override function updateFrameSkipByDistance():void {
			if (_client.isMouseOverMe) {
				if(_state == STATE_ANI_WALK) {
					_tweenWalkRatio = _tweenWalk.ratio;
					_tweenWalk.kill();
					_tweenWalk = null;
					_tweenIdleMouse = new TweenNano(this, Infinity, {onUpdate: updateFrameSkipByTime, onUpdateParams: [int.MAX_VALUE]});
					_mouseOutToWalk = true;
				}
			}else {
				super.updateFrameSkipByDistance();
			}
		}
		
		protected override function updateFrameSkipByTime(inFrameSpeed:int = 100, inSkipFrames:Boolean = true):void {
			if (!_client.isMouseOverMe && _state == STATE_ANI_WALK && _mouseOutToWalk) {
				_mouseOutToWalk = false;
				if (_tweenIdleMouse) _tweenIdleMouse.kill();
				_tweenIdleMouse = null;
				_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_WALK);
				state = STATE_ANI_WALK;
				_tweenWalk = new TweenNano(this, _tweenWalkTime - _tweenWalkRatio * _tweenWalkTime, {tweenIsoX:targetIsoX, tweenIsoY:targetIsoY, ease:Linear.easeNone, onUpdate:this.updateFrameSkipByDistance, onComplete:nextTileFinish});
			}
			super.updateFrameSkipByTime(inFrameSpeed);
		}
		
		protected function nextTileFinish():void
		{
			_client.isoX = tweenIsoX;
			_client.isoY = tweenIsoY;
			super.updateFrameByDistance();
			
			if (_moveDistance && !_flagStopped)
			{
				nextTile();
			}
			else
			{
				idle();
			}
		}
		
		public function togglePause(pause:Boolean):void
		{
			_paused = pause;
			if(_paused) 
			{
				nextTile();
			}
			else
			{
				TweenNano.killTweensOf(this);
			}
		}

		protected function idle():void
		{
			
			var isoMap:IsoMap = IsoController.gi.isoWorld.isoMap;
			if (isoMap.addChildObjTest(_client.isoX, _client.isoY, _client) || !_constrainToBounds)
			{
				_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_IDLE, false);
				TweenNano.killTweensOf(this);
				TweenNano.to(this, _moveIdle, {onUpdate: updateFrameSkipByTime, onComplete:nextTile});
				state = STATE_ANI_IDLE;
			}
			else
			{
				nextTile();
			}
		}
		
		public function get state():int {
			return _state;
		}
		
		public function set state(value:int):void
		{
			if (_state == value)
			{
				return;
			}
			
			_state = value; 
			
			var aniState:String;
			
			switch (value)
			{
				case STATE_ANI_IDLE:
					aniState = ON_ANI_IDLE;
					break;
				
				case STATE_ANI_WALK:
					aniState = ON_ANI_WALK;
					break;
				
				default:
					Log.error(this, "Unrecongized animation state = " + value + " for " + this);
					aniState = ON_ANI_IDLE;
					break;
			}
			
			dispatchEvent(new Event(aniState));
		}
	}
}
