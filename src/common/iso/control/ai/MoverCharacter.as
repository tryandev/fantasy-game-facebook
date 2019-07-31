package common.iso.control.ai
{
	import com.greensock.TweenNano;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.audio.FrameLabelSound;
	import common.iso.model.FrameAction;
	import common.iso.view.display.IsoAvatar;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoCharacter;
	import common.iso.view.display.IsoMonster;
	import common.iso.view.display.IsoUnit;
	
	import flash.debugger.enterDebugger;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;

	public class MoverCharacter extends EventDispatcher implements IMover
	{
		public static const ON_ANI_IDLE:String = 'onCharacterIdle';
		public static const ON_ANI_WALK:String = 'onCharacterWalk';
		public static const ON_ANI_ATTACK_HIT:String = 'onCharacterAttackHit';
		public static const ON_ANI_ATTACK_LAUNCH:String = 'onCharacterAttackLaunch';
		public static const ON_ANI_ATTACK_COMPLETE:String = 'onCharacterAttackComplete';
		public static const ON_ANI_HIT_REACT:String = 'onCharacterHitReaction';
		public static const ON_ANI_DIE:String = 'onCharacterDie';
		public static const ON_ANI_DIE_COMPLETE:String = 'onCharacterDieComplete';
		public static const ON_ANI_TIMELINE_COMPLETE:String = 'onCharacterTimelineComplete';
		
		protected static const SKIP_FRAMES:int = 1;
		
		protected var _framesSkipped:int = 0;
		protected var _frameTimeLast:Number = 0;
		protected var _pendIdle:Boolean;
		protected var _pendDieComplete:Boolean;
		protected var _pendAttackComplete:Boolean;
		protected var _pendHitComplete:Boolean;
		protected var _frozen:Boolean;
		protected var _dead:Boolean;
		
		private var _isoLastX:Number;
		private var _isoLastY:Number;
		
		
		protected var _client:IsoCharacter;
		protected var _dX:int;
		protected var _dY:int;
		protected var _speed:Number = 2;
		protected var _speedRatio:Number = 16;
		
		
		public var tweenIsoX:Number;
		public var tweenIsoY:Number;
		
		private var _frameLabel:String = null;

		public function MoverCharacter(inClient:IsoCharacter)
		{
			_client = inClient;
			_isoLastX = _client.isoX;
			_isoLastY = _client.isoY;
			tweenIsoX = _isoLastX;
			tweenIsoY = _isoLastY;
		}

		public function dispose():void
		{
			Log.info(this, "Mover dispose() called");
			TweenNano.killTweensOf(_client);
			TweenNano.killTweensOf(this);
			if (_client)
			{
				_client = null;
			}
		}
		
		public function updateFrameSkipByDistance():void {
			if (_framesSkipped < SKIP_FRAMES) {
				_framesSkipped++;
				return;
			}else {
				_framesSkipped = 0;
				_client.isoX = tweenIsoX;
				_client.isoY = tweenIsoY;
				updateFrameByDistance();
			}
		}
		
		public function updateFrameByDistance():void
		{
			var isoDistMoved:Number = Math.sqrt(Math.pow(_isoLastX - _client.isoX, 2) + Math.pow(_isoLastY - _client.isoY, 2));
			_isoLastX = _client.isoX;
			_isoLastY = _client.isoY;
			_client.updateFrame(isoDistMoved * _speedRatio);
		}
		
		protected function updateFrameSkipByTime(inFrameSpeed:int = 100, inSkipFrames:Boolean = true):void 
		{
			if (_framesSkipped < SKIP_FRAMES && inSkipFrames) {
				_framesSkipped++;
				return;
			} else {
				_framesSkipped = 0;
				var timePassed:Number = (getTimer() - _frameTimeLast) / inFrameSpeed;
				
				if (_client.updateFrame(timePassed)) {
					dispatchEvent(new Event(ON_ANI_TIMELINE_COMPLETE));
					if (_pendDieComplete) {
						_pendDieComplete = false;
						_client.getMC().gotoAndStop(_client.getMC().totalFrames);
						_dead = true;
						if (_pendAttackComplete) {
							attackComplete();
						}
						if (_pendHitComplete) {
							hitReactComplete();
						}
					}else if (_pendIdle) {
						_pendIdle = false;
						_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_IDLE);
						if (_pendAttackComplete) {
							attackComplete();
						}
						if (_pendHitComplete) {
							hitReactComplete();
						}
					}
				}
					
					
				_frameTimeLast = getTimer();
			}
		}
		
		public function attack(target:IsoBase):void {
			
			if (target.x < _client.x) {
				_dX = -1;
				_dY = 1;
			} else {
				_dX = 1;
				_dY = -1;
			} 
			_client.rewindAnimation();
			_frameTimeLast = getTimer();
			_pendAttackComplete = true;
			_pendIdle = true;
			TweenNano.killTweensOf(this);
			_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_ATTACK);
			TweenNano.to(this, Infinity, {onUpdate: updateFrameSkipByTime, onUpdateParams: [1/30 * 1000]});
		}
		
		protected function attackComplete():void {
			_pendAttackComplete = false;
			TweenNano.killTweensOf(this);
			if (!_dead) {
				_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_IDLE);
			}
			TweenNano.to(this, 3, {onUpdate: updateFrameSkipByTime, onUpdateParams: [1/30 * 1000], onComplete: start});				
			dispatchEvent(new Event(ON_ANI_ATTACK_COMPLETE));
		}
		
		public function hitReact(attacker:IsoBase, isDeathBlow:Boolean = false, isDodged:Boolean = false):void {
			var animation:String = IsoCharacter.ANI_ARRAY_HIT;
			_client.rewindAnimation();
			_frameTimeLast = getTimer();
			_pendIdle = true;
			_pendHitComplete = true;
			_pendAttackComplete = true;
			if (isDodged) {
				animation = IsoCharacter.ANI_ARRAY_DODGE;
//				trace(this + " animation: " + animation);
			} else if (isDeathBlow) {
				_pendDieComplete = true;
				animation = IsoCharacter.ANI_ARRAY_DEATH;
			}
			
			_dX = _client.x < attacker.x  ? 1:-1;
			_dY = _client.x < attacker.x  ? -1:1;
			
			_client.changeSprite(_dX, _dY, animation, false);
			TweenNano.killTweensOf(this);
			TweenNano.to(this, Infinity, {onUpdate: updateFrameSkipByTime, onUpdateParams: [1/30 * 1000]});
			
			dispatchEvent(new Event(ON_ANI_HIT_REACT));
		}
		
		protected function hitReactComplete():void {
			_pendHitComplete = false
		}
		
		public function stop():void 
		{
			
		}
		
		public function start():void 
		{
			_frozen = false;
		}
		
		/**
		 *	Stops all animations. Use when off screen or pooling the iso.
		 */	
		public function freeze():void
		{
			_frozen = true;
			TweenNano.killTweensOf(this);
			stop();
		}	
		
		public function get speed():Number
		{
			return _speed;
		}
		
		public function set speed(value:Number):void
		{
			_speed = value;
		}
		
		public function get speedRatio():Number
		{
			return _speedRatio;
		}
		
		public function set speedRatio(value:Number):void
		{
			if (value > 0) {
				_speedRatio = value;
			}
		}
		
		protected function doFrameLabelSounds():Boolean 
		{	
			_client.playerFrameSounds();
			return false;
		}
		
		protected function doFrameLabelHits():Boolean
		{
			for each (var hit:FrameAction in  _client.getHitActions())
			{
				dispatchEvent(new Event(ON_ANI_ATTACK_HIT));
				return true;
			}	
			return false;
		}
		
		protected function doFrameLabelLaunches():Boolean
		{
			
			for each (var launch:FrameAction in  _client.getLaunchActions())
			{
				
				var projectileKey:String;
				if (_client is IsoMonster) 
				{
					var monst:IsoMonster = IsoMonster(_client);
					if (monst && monst.model && monst.model.enemy && monst.model.enemy.projectile_base_cache_key) 
					{
						projectileKey = IsoMonster(_client).model.enemy.projectile_base_cache_key
					}
					
					if (projectileKey && projectileKey.length) 
					{
						dispatchEvent(new Event(ON_ANI_ATTACK_LAUNCH));	
					}
					else
					{
						// found a launch frame label, but monster model has no projectile key, using hit instead;
						dispatchEvent(new Event(ON_ANI_ATTACK_HIT));	
					}
				}
				else
				{
					dispatchEvent(new Event(ON_ANI_ATTACK_LAUNCH));	
				}
				return true;
			}	
			return false;
		}
		
		protected function doFrameLabelShakes():Boolean
		{
			var params:Array;
			for each (var shake:FrameAction in  _client.getShakeActions())
			{
				//trace("00000000000000 \t\t\t  GO ACTION", shake);
				params = (shake && shake.asset) ? shake.asset.split('_') : [];
				if (params.length == 3) 
				{
					!isNaN(params[0]) && !isNaN(params[1]) && !isNaN(params[2]) && (new Shaker(params[0], params[1], params[2]));
					return true;
				}
				else
				{
					new Shaker();					
					return true;
				}
			}	
			return false;
		}
	}
}