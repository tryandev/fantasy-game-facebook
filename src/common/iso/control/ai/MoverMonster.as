package common.iso.control.ai
{
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	import com.greensock.TweenNano;
	import com.greensock.easing.Linear;
	import com.raka.crimetown.model.game.Enemy;
	import com.raka.crimetown.model.game.EnemyActive;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.IsoController;
	import common.iso.model.FrameAction;
	import common.iso.view.containers.IsoMap;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoCharacter;
	import common.iso.view.display.IsoMonster;
	
	import flash.events.Event;
	import flash.utils.getTimer;

	public class MoverMonster extends MoverCharacter
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
		protected var _allowMovement:Boolean;
		protected var _constrainToBounds:Boolean = true;
		
		public function MoverMonster(inClient:IsoCharacter)
		{
			super(inClient);

			_speed = 1 + Math.random() * 5;

			_moveDistanceMin = 15; // 15
			_moveDistanceMax = 15; // 15

			_moveIdleMin = 1; //1
			_moveIdleMax = 3; //3
			
			_allowMovement = true;
		}
		
		public function setAllowMovement(value:Boolean):void
		{
			_allowMovement = value;
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
			if (!_client.isAlive) return;
			super.start();
			
			_moveDistance = _moveDistanceMin + Math.random() * (_moveDistanceMax - _moveDistanceMin);
			_moveDirection = Math.random() * 8;
			_moveIdle = _moveIdleMin + Math.random() * (_moveIdleMax - _moveIdleMin);
			_flagStopped = false;
			TweenNano.killTweensOf(this);
			nextTile();
			
			if (!_allowMovement) stop();
		}
		
		/*public function startDelayed():void {
			_tweenDelayedStart = TweenNano.delayedCall(1, start);
		}*/
		
		public override function stop():void 
		{
			
			/*super.stop();
			_moveDistance = 0;
			_moveIdle = Infinity;
			_flagStopped = true;
			if (state == STATE_ANI_IDLE)
				dispatchEvent(new Event(ON_ANI_IDLE));*/
			
			if (_client.isAlive) {
				state = STATE_ANI_IDLE;
				_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_IDLE, false);
				TweenNano.killTweensOf(this);
				TweenNano.to(this, Infinity, {onUpdate: updateFrameSkipByTime, onUpdateParams: [1/30 * 1000]});
			}
			
		}
		public override function hitReact(attacker:IsoBase, isDeathBlow:Boolean = false, isDodged:Boolean = false):void
		{
			_dX = (attacker.x < _client.x) ? -1 : 1;
			_dY = -_dX;
			if (_client && _client is IsoMonster && IsoMonster(_client).willDie)
			{
				//state = STATE_ANI_DIE;
				//_moveDistance = 0;
				//super.hit(attacker, true);
				_pendIdle = true;
				_pendAttackComplete = true;
				_pendHitComplete = true;
				die();
			}
			else
			{
				super.hitReact(attacker);				
			}
		}
		
		public function die():void
		{
			if (!_client) return;
			if (state == STATE_ANI_DIE) {
				return;
			}
			_moveDistance = 0;
			state = STATE_ANI_DIE;
			_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_DEATH, false);
			_client.getMC().gotoAndStop(1);
			TweenNano.killTweensOf(this);
			_frameTimeLast = getTimer();
			_pendDieComplete = true;
			TweenNano.to(this, Infinity, {onUpdate: updateFrameSkipByTime, onUpdateParams: [1/30 * 1000]});
			//TweenNano.to(this, Infinity, {onUpdate: updateCheckTimelineComplete});
		}	
		
		private function updateCheckTimelineComplete():void
		{
			if(_client.getMC().currentFrame > _client.getMC().totalFrames - 2)
			{
				TweenNano.killTweensOf(this);
				_client.getMC().gotoAndStop(_client.getMC().totalFrames);
				TweenNano.to(this, 1, {onComplete: dieComplete});
			}
		}	
		
		private function dieComplete():void
		{
			freeze();
			TweenNano.killTweensOf(this);
			dispatchEvent(new Event(ON_ANI_DIE_COMPLETE));
		}	
		

		private function changeDirection():void
		{
			_moveDirection = (_moveDirection + 3 + Math.floor(Math.random()*3)) % 8;
		}
		
		protected function nextTile(coord:Array = null, shouldCollide:Boolean = true):void
		{
			if (!_client) return;
			if (_moveDistance == 0)
			{
				if (_flagStopped || _client.isMouseOverMe) {
					TweenNano.delayedCall(1, idle, null, true);
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
				if (_client.occupy)
				{
					// Monsters never occupy a tile
					/*isoMap.tilesDetach(_client);
					isoMap.tilesAttach(_client, targetIsoX, targetIsoY);*/
				}
				_moveDistance--;
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
		
		public override function updateFrameSkipByDistance():void {
			if (_client.isMouseOverMe) {
				//_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_IDLE);
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
			if (_dead) {
				dieComplete();
				return;
			}
			if (!_client.isMouseOverMe && _state == STATE_ANI_WALK && _mouseOutToWalk) {
				_mouseOutToWalk = false;
				if (_tweenIdleMouse) _tweenIdleMouse.kill();
				_tweenIdleMouse = null;
				_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_WALK);
				state = STATE_ANI_WALK;
				_tweenWalk = new TweenNano(this, _tweenWalkTime - _tweenWalkRatio * _tweenWalkTime, {tweenIsoX:targetIsoX, tweenIsoY:targetIsoY, ease:Linear.easeNone, onUpdate:this.updateFrameSkipByDistance, onComplete:nextTileFinish});
			}
			super.updateFrameSkipByTime(inFrameSpeed);
			
			if (_client == null) return;
			
			super.doFrameLabelHits();
			super.doFrameLabelLaunches();
			super.doFrameLabelShakes();
			super.doFrameLabelSounds();		
		}
		
		protected function nextTileFinish():void
		{
			if (!_client) return;
			
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

		public function idle():void
		{
			if (!_client) return;
			//trace("MoverMonster idle");
			
			var isoMap:IsoMap = IsoController.gi.isoWorld.isoMap;
			
			if (isoMap == null)
			{
				// todo - SNM - resolve how this bug was occuring
				Log.warn(this, "MoverMonster is attempting to move it's client, but the isoMap is null, " + new Error().getStackTrace());
				return;
			}
			
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
				
				case STATE_ANI_DIE:
					aniState = ON_ANI_DIE;
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
