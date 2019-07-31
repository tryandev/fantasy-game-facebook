package common.iso.control
{
	import com.greensock.TweenNano;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.ai.MoverCharacter;
	import common.iso.control.ai.MoverProjectile;
	import common.iso.model.IsoModel;
	import common.iso.model.projectile.Projectile;
	import common.iso.view.display.IsoAvatar;
	import common.iso.view.display.IsoMonster;
	
	import flash.events.Event;

	public class IsoControllerRevenge
	{
		// Private incoming vars
		private var _monster:IsoMonster;
		private var _avatar:IsoAvatar;
		private var _callback:Function;
		
		// Private local vars
		private var _disposed:Boolean;
		private var _projectile:Projectile;
		private var _countAttacks:int;
		private var _countReacts:int;
		private var _movers:Array;
		private var _projectileKey:String;
		private var _monsterFinished:Boolean;
		private var _avatarFinished:Boolean;
		private var _isDodged:Boolean;
		
		public function IsoControllerRevenge(inIsoMonster:IsoMonster, inIsoAvatar:IsoAvatar, inIsDodged:Boolean) {
			_monster = inIsoMonster;
			_avatar = inIsoAvatar;
			_isDodged = inIsDodged;
//			trace('IsoControllerRevenge() _isDodged: ' + _isDodged);
			_movers = [];
		}
		
		public function dispose():void {
			if (_disposed) return;
			_disposed = true;
			_monster.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_HIT, melee); 
			_monster.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_LAUNCH, launch); 
			_monster.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_COMPLETE, timelineEndMonster); 
			_avatar.mover().removeEventListener(MoverCharacter.ON_ANI_TIMELINE_COMPLETE, timelineEndAvatar); 
			_monster = null;
			_avatar = null;
			_callback = null;
			while (_movers.length) {
				var moverP:MoverProjectile = MoverProjectile(_movers.pop());
				moverP.removeEventListener(MoverProjectile.ON_PROJECTILE_HIT, hitReact);
				moverP.dispose();
			}
			_movers = null;
			TweenNano.killTweensOf(this);
		}
		
		public function start(inCallback:Function, delayed:Boolean = false):void {
			if (_disposed) {
				throw new Error(this + ' this instance had already been disposed');
			}
			_callback = inCallback;
			//trace('REVENGE HIT START');
			_projectileKey = _monster.model.enemy.projectile_base_cache_key;
			if (_projectileKey && _projectileKey.length) {
				_projectile = IsoModel.gi.getProjectile(_projectileKey);
				_projectile.loadAssets(onProjectileLoaded, onProjectileFail);
			}else{
				if (delayed)  {
					// monster probably failed assets, delay attack
					TweenNano.to(this, 1, {onComplete: attack});
				} else {
					attack();					
				}
			}
		}
		
		private function attack():void {
			if (_disposed) {
				return;
			}
//			trace('attack();');
			_monster.mover().addEventListener(MoverCharacter.ON_ANI_ATTACK_HIT, melee);						// when monster hits 'hit' frame, hit();
			_monster.mover().addEventListener(MoverCharacter.ON_ANI_ATTACK_LAUNCH, launch);					// when monster hits 'launch' frame, launch();
			_monster.mover().addEventListener(MoverCharacter.ON_ANI_ATTACK_COMPLETE, timelineEndMonster);	// when monster's timeline finish, timelineEndMonster();
			_avatar.mover().addEventListener(MoverCharacter.ON_ANI_TIMELINE_COMPLETE, timelineEndAvatar);	// when avatar's timeline finish, timelineEndAvatar();
			_monster.mover().attack(_avatar);																// monster attacks the avatar
		}

		private function onProjectileLoaded(inProjectile:Projectile):void {
			attack();
		}
		
		
		private function onProjectileFail(inProjectile:Projectile):void {
			Log.error(this, 'Project Failed to load: ' + inProjectile.cacheKey);
			attack();
		}
		
		private function launch(e:Event = null):void {
			_countAttacks++;
			trace('launch _countAttacks: ' + _countAttacks);
			if (_projectileKey && _projectileKey.length && !_projectile) {
				_projectile = IsoModel.gi.getProjectile(_projectileKey);
				_projectile.loadAssets(dummy,dummy);
			}
			var moverProjectile:MoverProjectile = new MoverProjectile(_monster, _avatar, _projectile);
			_projectile = null;
			moverProjectile.start();
			moverProjectile.addEventListener(MoverProjectile.ON_PROJECTILE_HIT, hitReact);
			_movers.push(moverProjectile);
		}
		
		private function melee(e:Event = null):void {
//			trace('melee()');
			_countAttacks++;
			hitReact();
		}
		
		private function hitReact(e:Event = null):void {
			_countReacts++;
//			trace('hit _countReacts: ' + _countReacts);
			//_avatar.mover().removeEventListener(MoverCharacter.ON_ANI_TIMELINE_COMPLETE, timelineEndAvatar);	// when avatar's timeline finish, timelineEndAvatar();
//			trace('hitReact _isDodged: ' + _isDodged);
			_avatar.mover().hitReact(_monster, false, _isDodged);												// avatar reaction				
		}
		
		private function timelineEndMonster(e:Event = null):void {
			if (_countAttacks == 0) {
//				trace('timelineEndMonster: didnt find hit frame, doing one now');
				_monsterFinished = true;
				melee();
				return;
			}
//			trace('timelineEndMonster');
			// monster is done, remove all frame label listeners from monster
			_monster.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_LAUNCH, launch);
			_monster.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_HIT, melee);
			_monster.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_COMPLETE, timelineEndMonster);
			_monsterFinished = true;
			if (!_avatarFinished) {
//				trace('timelineEndMonster: avatar not done');
				return;
			}
			checkAttackReactCounts();
		}
		
		private function timelineEndAvatar(e:Event = null):void {
//			trace('timelineEndAvatar');
			_avatarFinished = true;
			if (!_monsterFinished) {
//				trace('timelineEndAvatar: monster not done');
				return;
			}
			checkAttackReactCounts();
		}
		
		private function checkAttackReactCounts():void {
//			trace('_countAttacks, _countReacts: \t' + _countAttacks + ', '+ _countReacts);
			if (_countReacts < _countAttacks) {
				return;
			}
			_avatar.mover().removeEventListener(MoverCharacter.ON_ANI_TIMELINE_COMPLETE, timelineEndAvatar); 	// now wait for avatar reaction to finish
			complete();
		}
		
		private function complete(e:Event = null):void {
			if (_callback != null) {
				_callback();
				_callback = null;
			}
			this.dispose();
		}
		
		private function dummy(p:Projectile):void {
			
		}
	}
}