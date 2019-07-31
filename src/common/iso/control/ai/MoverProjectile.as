package common.iso.control.ai {
	
	import com.greensock.TweenNano;
	import com.greensock.easing.Cubic;
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	import com.raka.media.sound.IRakaSoundItem;
	import com.raka.media.sound.IRakaStreamingSoundItem;
	import com.raka.media.sound.RakaEmbeddedSound;
	import com.raka.media.sound.RakaSoundManager;
	import com.raka.media.sound.RakaStreamingSound;
	
	import common.iso.control.IsoController;
	import common.iso.model.IsoModel;
	import common.iso.model.projectile.Projectile;
	import common.iso.view.display.IsoAvatar;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoBuilding;
	import common.iso.view.display.IsoCharacter;
	import common.iso.view.display.projectile.IsoProjectile;
	import common.iso.view.display.projectile.IsoProjectileEnd;
	import common.iso.view.display.projectile.IsoProjectileStart;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.SoundChannel;
	
	public class MoverProjectile extends EventDispatcher implements IMover {

		public static const MOTIONSTYLE_CURVE:int = 0;
		public static const MOTIONSTYLE_STRAIGHT:int = 1;
		public static const MOTIONSTYLE_DROP:int = 2;
		
		public static const ON_PROJECTILE_HIT:String = 'onProjectileHit';
		public static const ON_PROJECTILE_COMPLETE:String = 'onProjectileComplete';
		
		private var _effectStart:IsoProjectileStart;
		private var _effectMiddle:IsoProjectile;
		private var _effectEnd:IsoProjectileEnd;
		
		private var _src:IsoBase;
		private var _goal:IsoBase;
		private var _speed:Number = 1;
		private var _xStart:Number;
		private var _yStart:Number;
		
		private var _xGoal:Number;
		private var _yGoal:Number;
		
		private var _xDiff:Number;
		private var _yDiff:Number;
		
		private var _xOffset:Number;
		private var _yOffset:Number;
		
		private var _distance:Number;
		private var _motionStyle:int;
		
		private var _projectile:Projectile;
		private var _soundFly:IRakaSoundItem;
		private var _soundFlyChannel:SoundChannel;
		
		
		public var tweenRatio:Number; // will be tweened from 0.0 to 1.0
		
		
		public function MoverProjectile(inSource:IsoBase, inGoal:IsoBase, inProjectile:Projectile) {
			//inMotionSyle:int = MOTIONSTYLE_CURVE, inOffsetX:Number = -300, inOffsetY:Number = -600;
			
			_src = inSource;
			_goal = inGoal;
			
			_projectile = inProjectile;
			
			_motionStyle = _projectile.motion;
			_xOffset = _projectile.offsetX;
			_yOffset = _projectile.offsetY;
			_speed = _projectile.speed;
		}
		
		public function dispose():void {
			
			if (_effectStart) {
				_effectStart.dispose();
				_effectStart = null;
			}
			
			if (_effectMiddle) {
				_effectMiddle.dispose();
				_effectMiddle = null;
			}
			
			if (_effectEnd) {
				_effectEnd.removeEventListener(IsoProjectileEnd.ANI_FINISH, onAniFinishEnd);
				_effectEnd.dispose();
				_effectEnd = null;
			}
			
			if (_projectile) {
				_projectile.dispose();
				_projectile = null;
			}
			
			if(_soundFly) {
				_soundFly = null;
			}
			
			if(_soundFlyChannel) {				
				_soundFlyChannel.stop()
				_soundFlyChannel = null;
			}
			
			_src = null;
			_goal = null;
			TweenNano.killTweensOf(this);
		}
		
		public function start():void {
			
			var yWeight:int = 2; // projectile has to travel 1/2 speed in Y because of the IsoCamera angle
			
			tweenRatio = 0;			
			
			_xGoal = _goal.x ;
			_yGoal = _goal.y + _goal.isoSize * IsoBase.GRID_PIXEL_SIZE / 2 ;
			
			if (_motionStyle == MOTIONSTYLE_DROP) {
				_xStart = _xGoal + _xOffset;
				_yStart = _yGoal + _yOffset;
				yWeight = 1;	// remove yWeight because it is now coming from Z
			}else{
				_xStart = _src.x;
				_yStart = _src.y;				
			}

			_xDiff = _xGoal - _xStart;
			_yDiff = _yGoal - _yStart;
			
			_distance = Math.sqrt(_xDiff * _xDiff + (_yDiff * yWeight) * (_yDiff * yWeight));
			
			// re-adjust start and end positions based on launch mc and hit mc in attack and receive
			// ------------------------------------------------------------------------------------------
			var character:MovieClip;
			var sourceScale:Number = 1;
			if (_src is IsoCharacter) {
				var launcher:DisplayObject;
				character = IsoCharacter(_src).getMC();
				sourceScale = character.scaleX;
				if (_motionStyle != MOTIONSTYLE_DROP && character) {
					launcher = character.getChildByName('launcher');
					if (launcher) {
						_xStart += launcher.x * character.scaleX;
						_yStart += launcher.y;
					}else{
						_yStart -= (_src.y - _src.getBounds(_src.parent).top) * 0.5;
					}
				}
			}
			if (_goal is IsoCharacter) {
				var receiver:DisplayObject;
				character = IsoCharacter(_goal).getHitMC();
				if (character) {
					receiver = character.getChildByName('receiver');
					if (receiver) {
						_xGoal += receiver.x * character.scaleX;
						_yGoal += receiver.y;
					}else{
						_yGoal -= (_goal.y - _goal.getBounds(_goal.parent).top) * 0.5;
					}
				}
			}
			
			if (_goal is IsoBuilding) {
				_xGoal += 0.75 * _goal.isoSize * (Math.random() - 0.5) * IsoBase.GRID_PIXEL_SIZE;
				_yGoal += 0.75 * _goal.isoSize * (Math.random() - 0.5) * IsoBase.GRID_PIXEL_SIZE * 0.5;
			}
			
			if (sourceScale < 0 && _motionStyle == MOTIONSTYLE_DROP) {
				_xStart = _xGoal - _xOffset;
			}
			
			_xDiff = _xGoal - _xStart;
			_yDiff = _yGoal - _yStart;
			
			// ------------------------------------------------------------------------------------------
			
			if (_projectile.mcStart) 	_effectStart = new IsoProjectileStart(_projectile.mcStart, _xStart,_yStart);
			if (_projectile.mcEnd) 		_effectEnd = new IsoProjectileEnd(_projectile.mcEnd, _xGoal,_yGoal);
			
			if ((!_projectile.mcStart && !_projectile.mcEnd) && !_projectile.mcMiddle) 
			{
				_effectMiddle = new IsoProjectile(null, true);
			}
			else
			{
				_effectMiddle = new IsoProjectile(_projectile.mcMiddle);
			}
			
			
			
			if (_effectStart && _effectStart.parent == null) 	IsoController.gi.isoWorld.isoMap.addProjectile(_effectStart);
			if (_effectMiddle && _effectMiddle.parent == null) 	IsoController.gi.isoWorld.isoMap.addProjectile(_effectMiddle);
			if (_effectEnd && _effectEnd.parent == null) 		IsoController.gi.isoWorld.isoMap.addProjectile(_effectEnd);
			
			if(_projectile.soundSpawn.length) {				
				IsoController.gi.playSoundFX(_projectile.soundSpawn);
			}
			
			if (_effectStart) {
				_effectStart.play();
			}
			
			if (_effectMiddle) {
				startProjectile();				
			}else{
				onAniFinishProjectile();
			}
		}
		
		public function isoRange():Number {
			var xIsoDiff:Number = _goal.isoX - _src.isoX;
			var yIsoDiff:Number = _goal.isoY - _src.isoY;
			return Math.sqrt(xIsoDiff * xIsoDiff + yIsoDiff * yIsoDiff);
		}
		
		private function startProjectile(e:Event = null):void {
			if(_projectile.soundFly.length) {
				_soundFly = RakaSoundManager.getInstance().getSoundFX(_projectile.soundFly);
				if (_soundFly) 
				{
					_soundFlyChannel = _soundFly.play(0,999);
				}
			}
			updatePosition();
			_effectMiddle.visible = true;
			_effectMiddle.play();
			var easing:Function = Linear.easeNone;
			if (_motionStyle == MOTIONSTYLE_DROP) {
				easing = Quad.easeIn;
			}/*else if (_motionStyle == MOTIONSTYLE_STRAIGHT) {
				easing = Quad.easeInOut;
			}*/
			TweenNano.to(this, _distance/(speed * 640), {tweenRatio: 1, ease: easing, onUpdate: updatePosition, onComplete: onAniFinishProjectile});
		}
		
		private function onAniFinishProjectile(e:Event = null):void {
			if(_soundFlyChannel) {
				_soundFlyChannel.stop();
			}
			if(_projectile.soundHit.length) {
				IsoController.gi.playSoundFX(_projectile.soundHit);
				var shakeParam:Array = _projectile.shake.split(',');
				if (shakeParam.length == 3) {
					var result:Number =  shakeParam[0] * shakeParam[1] * shakeParam[2];
					if (!isNaN(result) && result > 0) {
						new Shaker(shakeParam[0],shakeParam[1],shakeParam[2]);						
					}
				}
			}
			if (_effectMiddle) {
				_effectMiddle.visible = false;
				_effectMiddle.stop();
			}
			if (_effectEnd) {
				_effectEnd.addEventListener(IsoProjectileEnd.ANI_FINISH, onAniFinishEnd);
				_effectEnd.scaleX = (_src.x < _goal.x) ? 1:-1;
				_effectEnd.play();
			}else{
				onAniFinishEnd();
			}
			dispatchEvent(new Event(ON_PROJECTILE_HIT));
		}
		
		private function onAniFinishEnd(e:Event = null):void {
			dispatchEvent(new Event(ON_PROJECTILE_COMPLETE));
			dispose();
		}
		
		public function updatePosition():void {
			
			var tweenRatioNext:Number = tweenRatio + 0.001;
			var isoDistance:Number = Math.sqrt((_src.isoX - _goal.isoX) * (_src.isoX - _goal.isoX) + (_src.isoY - _goal.isoY) * (_src.isoY - _goal.isoY));
			
			var nowArc:Number = (_motionStyle == MOTIONSTYLE_CURVE) ? 1 * (tweenRatio * tweenRatio - tweenRatio) * _distance : 0;
			nowArc *= Math.atan(isoDistance - 6) / 3.14 + 0.5;
			var nowX:Number = _xStart + _xDiff * tweenRatio;
			var nowY:Number = _yStart + _yDiff * tweenRatio + nowArc;
			
			var nextArc:Number = (_motionStyle == MOTIONSTYLE_CURVE) ? 1 * (tweenRatioNext * tweenRatioNext - tweenRatioNext) * _distance:0;
			nextArc *= Math.atan(isoDistance - 6) / 3.14 + 0.5;
			var nextX:Number = _xStart + _xDiff * tweenRatioNext; 
			var nextY:Number = _yStart + _yDiff * tweenRatioNext + nextArc;
			
			var nowRotation:Number = Math.atan2(nextY - nowY, nextX - nowX);
			
			_effectMiddle.rotation = nowRotation * 180 / Math.PI; // radians to degrees
			_effectMiddle.x = nowX;
			_effectMiddle.y = nowY;
		}
		
		public function get speed():Number {
			return _speed;
		}
		
		public function set speed(value:Number):void {
			_speed = value;
		}
		
	}
}