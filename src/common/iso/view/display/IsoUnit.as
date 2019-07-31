package common.iso.view.display
{
	import com.greensock.TweenLite;
	import com.greensock.TweenNano;
	import com.raka.crimetown.model.game.ITargetable;
	import com.raka.crimetown.model.game.Unit;
	import com.raka.crimetown.util.AppConfig;
	import com.raka.utils.Config;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.IsoController;
	import common.iso.control.ai.MoverCharacter;
	import common.iso.control.ai.MoverMonster;
	import common.iso.control.ai.MoverProjectile;
	import common.iso.control.ai.MoverUnit;
	import common.iso.model.FrameAction;
	import common.iso.model.IsoModel;
	import common.iso.model.projectile.Projectile;
	
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;

	public class IsoUnit extends IsoCharacter implements ITargetable
	{
		public static var WALK_TYPES:Array = ["walk_S", "walk_SE", "walk_E", "walk_NE", "walk_N"];
		public static var IDLE_TYPES:Array = ["idle_S", "idle_SE", "idle_E", "idle_NE", "idle_N"];
		public static var ATTACK_TYPES:Array = ["attack", "attack", "attack", "attack", "attack"];
		public static var HIT_TYPES:Array = ["hit", "hit", "hit", "hit", "hit"];
		public static var DEATH_TYPES:Array = ["death", "death", "death", "death", "death"];
		
		protected var _model:Unit;
		protected var _dirX:int;
		protected var _dirY:int;
		protected var _destX:int;
		protected var _destY:int;
		protected var _target:ITargetable;
		protected var _isAlive:Boolean;
		protected var _attackDelay:Number;
		protected var _attackTimer:Timer;
		protected var _attackSubject:IsoBase;
		
		protected var _randomOffsetX:Number;
		protected var _randomOffsetY:Number;
		
		protected var _numHitsToDie:int;
		
		protected var _player:String;
		
		private const minNumHitsToDie:int = 2;
		private const maxNumHitsToDie:int = 4;
		
		public function IsoUnit(dirX:int = 1, dirY:int = 0)
		{
			_dirX = dirX;
			_dirY = dirY;
			_isAlive = true;
			_player = "player";
			
			_characterMover = new MoverUnit(this);
			
			moverUnit.speed = 1.5;
			moverUnit.speedRatio = 32;
			
			_numHitsToDie = Math.random() * (maxNumHitsToDie - minNumHitsToDie) + minNumHitsToDie;
			
			_randomOffsetX = (0.5 - Math.random()) * GRID_PIXEL_SIZE / 4.0;
			_randomOffsetY = (0.5 - Math.random()) * GRID_PIXEL_SIZE / 4.0 / 2;
		}
		
		public function init(model:Unit, isRivalUnit:Boolean = false):void
		{
			_player = isRivalUnit ? "rival" : "player";
			this.model = model;
		}
		
		public function get isRivalUnit():Boolean
		{
			return _player == "rival";
		}
		
		public function get model():Unit
		{
			return _model;
		}
		
		public function set model(value:Unit):void
		{
			if (!_initialized)
			{
				moverUnit.speed = value.move_speed;
				moverUnit.speedRatio = value.anim_rate;
				
				_model = value;
				_cacheKey = _model.base_cache_key;
				_assetURL = AppConfig.env.getValue(_player + "_unit_assets_url").replace(Config.PLACEHOLDER, _cacheKey);
				
				_attackDelay = Math.random() * (value.max_attack_delay - value.min_attack_delay);
				// we want the first attack to happen with minimal delay
				
				loadAsset(onAssetLoad, onAssetFail);
			}
		}
		
		public function shouldAttackBuilding():Boolean
		{
			if (!model) return false;
			
			return model.attack_preference >= Math.random();
		}
		
		public function get isMelee():Boolean
		{
			return model.animation_type == "melee";
		}
		
		public function get isRanged():Boolean
		{
			return model.animation_type == "ranged";
		}
		
		public function spawn(isoX:Number = NaN, isoY:Number = NaN):void
		{
			map.addChildObj(this);
			
			if (!isNaN(isoX)) this.isoX = isoX;
			if (!isNaN(isoY)) this.isoY = isoY;
		}
		
		public function set target(aTarget:ITargetable):void
		{
			_target = aTarget;
			
			if (!_initialized) return;
			
			if (_target == null) return;
			
			var spacing:int = (_target && x < _target.x)? -1 : 1;
			
			if (isRanged)
			{
				_destX = isoX;
				_destY = isoY;
				
				attack(_target.isoBase);
			}
			else if (target.isRanged)
			{
				setDestination(_target.isoX + spacing * 2, _target.isoY - spacing * 2);
			}
			else if (_target is IsoRivalBuilding)
			{
				var building:IsoRivalBuilding = _target as IsoRivalBuilding;
				var dest:Point = building.getAttackPoint();
				
				setDestination(dest.x, dest.y);
			}
			else if (_target.target == this)
			{
				var dX:int = (isoX + target.isoX) / 2;
				var dY:int = (isoY + target.isoY) / 2;
				
				setDestination(dX + spacing, dY - spacing);
				_target.setDestination(dX - spacing, dY + spacing);
			}
			else if (_target.target != null)
			{
				setDestination(_target.destX + spacing * 2, _target.destY - spacing * 2);
			}
		}
		
		public function get target():ITargetable
		{
			return _target;
		}
		
		public function setDestination(destX:int, destY:int):void
		{
			_destX = destX;
			_destY = destY;
			
			if (!_initialized) return;
			if (isRanged) return;
			
			moverUnit.walkTo(destX, destY);
		}
		
		public function get destX():int
		{
			return _destX;
		}
		
		public function get destY():int
		{
			return _destY;
		}
		
		public function fadeOutAndRemove():void
		{
			target = null;
			_attackSubject = null;
			TweenLite.to(this, 0.3, {alpha:0, onComplete:onFadeOutComplete});
		}
		
		private function onFadeOutComplete():void
		{
			map.removeChildObj(this);
			dispose();
		}
		
		override protected function reposition():void
		{
			x = GRID_PIXEL_SIZE * (_isoX - _isoY) + _randomOffsetX;
			y = GRID_PIXEL_SIZE * (_isoX + _isoY) / 2 + _randomOffsetY;
		}
		
		override protected function addedToStage():void
		{
			if (_initialized) moveStart();
		}
		
		public override function moveStart():void
		{
			moverUnit.start();
		}
		
		public override function moveStop():void
		{
			moverUnit.stop();
		}
		
		public override function mover():MoverCharacter
		{
			return moverUnit;
		}
		
		public function hit(isoUnit:IsoBase):void
		{
			if (!_initialized) return;
			
			mover().hitReact(isoUnit);
		}
		
		public function attack(isoUnit:IsoBase):void
		{
			if (_attackTimer == null)
			{
				_attackSubject = isoUnit;
				_attackTimer = new Timer(_attackDelay * 1000, 0);
				_attackTimer.addEventListener(TimerEvent.TIMER, onAttackTimeComplete);
				_attackTimer.start();
			}
		}
		
		private function onAttackTimeComplete(e:TimerEvent):void
		{
			if (!_initialized || !_isAlive) return;
			
			mover().attack(_attackSubject);
			
			disposeAttackTimer();
			_attackDelay = model.randomAttackDelay;
		}
		
		public function launchProjectile():void
		{
			if (isRanged)
			{
				fireProjectile();
			}
		}
		
//		override public function playerFrameSounds():void
//		{
//			var actions:Array = _actions.getFrameActionsOfType(_liveMC.currentFrame, FrameAction.TYPE_SFX);
//			
//			for each (var action:FrameAction in actions)
//			{
//				IsoController.gi.playStreamingSound(action.asset);
//			}	
//		}	
//		
		private function disposeAttackTimer():void
		{
			_attackSubject = null;
			if (_attackTimer)
			{
				_attackTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onAttackTimeComplete);
				_attackTimer.stop();
				_attackTimer = null;
			}
		}
		
		public function get moverUnit():MoverUnit
		{
			return _characterMover as MoverUnit;
		}
		
		public function receiveDamage():void
		{
			_numHitsToDie--;
			
			if (_numHitsToDie <= 0)
				die();
		}
		
		public function die():void
		{
			if (!_isAlive || !_initialized) return;
			
			moverUnit.die();
			
			_isAlive = false;
		}
		
		override public function get isAlive():Boolean
		{
			return _isAlive;
		}
		
		private function fireProjectile():void
		{
			var projectile:Projectile = IsoModel.gi.getProjectile(model.projectile_base_cache_key);
			if (!projectile) {
				throw new Error(this.model.name + ':' + this.model.base_cache_key + " is launching: " +  model.projectile_base_cache_key);
				return;
				//onProjectileLoadFail(null);	
			}
			if (projectile.parent && projectile.parent.failedSWF) {
				projectile.drawDefaultMCs();
				onProjectileLoadSuccess(projectile);
			}else{
				projectile.loadAssets(onProjectileLoadSuccess, onProjectileLoadFail);				
			}
		}
		
		private function onProjectileLoadSuccess(projectile:Projectile):void
		{
			if (target)
			{
				var mover:MoverProjectile = new MoverProjectile(this, target.isoBase, projectile);
				
				mover.start();				
			}
		}
		
		private function onProjectileLoadFail(projectile:Projectile):void
		{
			onProjectileLoadSuccess(projectile);
			projectile.drawDefaultMCs();
			Log.warn(this, "Failed to load projectile", projectile);
		}
		
		private function onAssetLoad():void
		{
			_initialized = true;
			
			addAnimations(WALK_TYPES, 	IsoCharacter.ANI_ARRAY_WALK);
			addAnimations(IDLE_TYPES, 	IsoCharacter.ANI_ARRAY_IDLE);
			addAnimations(ATTACK_TYPES,	IsoCharacter.ANI_ARRAY_ATTACK);
			addAnimations(HIT_TYPES, 	IsoCharacter.ANI_ARRAY_HIT);
			addAnimations(DEATH_TYPES, 	IsoCharacter.ANI_ARRAY_DEATH);
			
			changeSprite(_dirX, _dirY, ANI_ARRAY_IDLE, true);
		}
		
		private function onAssetFail():void 
		{
			_initialized = true;
			changeSprite(_dirX, _dirY, ANI_ARRAY_IDLE, true);
		}
		
		private function addAnimations(items:Array, animation:String):void
		{
			var item:String;
			
			for each (item in items)
				addAnimation(getLibraryItemInstance(item), animation);
		}
		
		override protected function makeMoveable(isAllowedToMove:Boolean):void
		{
			if (isAllowedToMove)
			{
				if ((_characterMover as MoverMonster).state == MoverMonster.STATE_ANI_IDLE)
					moveStart();
			}
			else
			{
				if ((_characterMover as MoverMonster).state == MoverMonster.STATE_ANI_WALK)
					moveStop(); 
			}
		}
		
		public function get isAttackable():Boolean
		{
			return isAlive;
		}
		
		public function get isoBase():IsoBase
		{
			return this;
		}
		
		override public function dispose():void
		{
			super.dispose();
			disposeAttackTimer();
		}
	}
}
