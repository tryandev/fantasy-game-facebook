package common.iso.control
{
	import com.greensock.TweenNano;
	import com.raka.crimetown.model.game.Item;
	import com.raka.crimetown.util.AppConfig;
	import com.raka.crimetown.util.GameConfigEnum;
	import com.raka.crimetown.view.hud.menu.HudMenuItemProfile;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.ai.AStarNode;
	import common.iso.control.ai.MoverAvatar;
	import common.iso.control.ai.MoverCharacter;
	import common.iso.control.ai.MoverMonster;
	import common.iso.control.ai.MoverProjectile;
	import common.iso.control.load.FactoryAniAttack;
	import common.iso.model.projectile.Projectile;
	import common.iso.view.containers.IsoMap;
	import common.iso.view.display.IsoAvatar;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoCharacter;
	import common.iso.view.display.IsoMonster;
	import common.iso.view.display.IsoState;
	import common.iso.view.display.IsoTile;
	import common.test.debug.FPS;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.getTimer;
	
	
	public class IsoControllerFight extends EventDispatcher
	{
		public static const EVENT_POSITIONS_READY:String = 'onFightPositionsReady';
		public static const EVENT_OFFENSE_COMPLETE:String = 'onFightOffenseComplete';
		public static const EVENT_HIT_COMPLETE:String = 'onFightHitComplete';
		public static const EVENT_REVENGE_COMPLETE:String = 'onFightRevengeComplete';
		public static const EVENT_FIGHT_COMPLETE:String = 'onFightComplete';
		public static const EVENT_RECEIVE_HIT:String = 'onReceiveHit';
		public static const ISO_MELEE_RANGE:Number = 3;
		
		public static var isBusy:Boolean = false;
		
		private var _isoAvatar:IsoAvatar;
		private var _isoTarget:IsoBase;
		private var _attacksComplete:int;
		private var _disposed:Boolean;
		
		private var _isAvatarInPosition:Boolean;
		private var _isAvatarAttackAniReady:Boolean;
		
		private var _attackAniFactory:FactoryAniAttack;
		private var _projectile:Projectile;
		private var _moverProjectile:MoverProjectile;
		
		private var _revenge:IsoControllerRevenge;
		private var _revengeDodged:Boolean;
		private var _didDispatchHit:Boolean;
		
		public function IsoControllerFight(inIsoAvatar:IsoAvatar, inIsoTarget:IsoBase)
		{
			//trace('IsoControllerFight constructor');
			_isoAvatar = inIsoAvatar;
			_isoTarget = inIsoTarget;
			
			_didDispatchHit = false;
		}
		
		public function dispose():void {
			if (_disposed) return;
			_disposed = true;
			if (_isoTarget is IsoCharacter) {
				(_isoTarget as IsoCharacter).mover().removeEventListener(MoverCharacter.ON_ANI_IDLE, onTargetIsInPosition, false);
			}
			_isoTarget = null;
			
			if (_attackAniFactory) {
				_attackAniFactory.dispose();
				_attackAniFactory = null;
			}
			if (_projectile) {
				_projectile.dispose();
				_projectile = null;
			}
			
			if (_moverProjectile) {
				_moverProjectile.dispose();
				_moverProjectile = null;
			}
			
			if (_revenge) {
				_revenge.dispose()
				_revenge = null;
			}
			
			isBusy = false;
			
			if (_isoAvatar && _isoAvatar.mover()) {
				_isoAvatar.isFighting = false;
				_isoAvatar.mover().removeEventListener(MoverCharacter.ON_ANI_IDLE, onAvatarIsInPosition, false);
				_isoAvatar.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_COMPLETE, attackComplete, false);
				_isoAvatar.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_HIT, attackHit, false);
				_isoAvatar.mover().removeEventListener(MoverCharacter.ON_ANI_HIT_REACT, reactHit, false);
				_isoAvatar = null;
			}
		}
		
		public function get hasFightAssets():Boolean
		{
			if(_isoTarget is IsoCharacter)
			{
				return IsoCharacter(_isoTarget).hasFightAsset && _isoAvatar.hasFightAsset;
			}
			
			return _isoAvatar.hasFightAsset
		}	
		
		public function start(e:Event = null):void 
		{
//			tr("start()");
			
			if (isBusy) {
				Log.warn(this, "Fight Controller is BUSY");
				return;
			}
			
			isBusy = true;
			//trace('IsoControllerFight start');
			_isoAvatar.isFighting = true;
			
			if (_attackAniFactory) {
				_attackAniFactory.dispose();
			}
			
			//FPS.timerGet('FactoryAniAttack start');
			_attackAniFactory = new FactoryAniAttack(_isoTarget, onAvatarAttackAniReady);
			_attackAniFactory.initialize();
			//FPS.timerGet('FactoryAniAttack finish');
			
			if (_isoTarget is IsoCharacter) { 
				(_isoTarget as IsoCharacter).mover().stop();
			}
			onTargetIsInPosition();
		}
		
		public function get bestWeapon():Item
		{
			return _attackAniFactory ? _attackAniFactory.bestWeapon : null;
		}
		
		private function onTargetIsInPosition(e:Event = null):void {
			var nodes:Array = [];
			var distAttack:int = _attackAniFactory.getAttackRange();
			if (_isoTarget is IsoCharacter) {
				var mover:MoverMonster = (_isoTarget as IsoCharacter).mover() as MoverMonster;
				mover.removeEventListener(MoverCharacter.ON_ANI_IDLE, onTargetIsInPosition, false);
				//trace("IsoControllerFight assembledTarget " + mover.targetIsoX + ", " + mover.targetIsoY);
			}else{
				//trace('IsoControllerFight assembledTarget _isoTarget NOT IsoCharacter');	
			}
			
			if (distAttack == 0) {
				// if no distance, just attack from left or right
				if (_isoTarget is IsoCharacter) {
					var configMeleeRange:int = AppConfig.game.getNumberValue(GameConfigEnum.MELEE_ATTACK_RANGE);
					distAttack = configMeleeRange - 1;
				}
				nodes = getMeleeNodes(_isoTarget, distAttack, nodes);
				/*var nodeLeft:AStarNode; 
				var nodeRight:AStarNode; 
				
				nodeLeft =  new AStarNode(Math.round(_isoTarget.isoX + _isoTarget.isoSize + distAttack), Math.round(_isoTarget.isoY - distAttack - 1));
				nodeRight = new AStarNode(Math.round(_isoTarget.isoX - distAttack - 1), Math.round(_isoTarget.isoY + _isoTarget.isoSize + distAttack));
					
				nodes.push(nodeLeft);
				nodes.push(nodeRight);	*/
				
			}else{
				// get all nodes from left and right quadrant that's within range
				nodes = getRangedNodes(_isoTarget, distAttack);
			}
			_isoAvatar.mover().addEventListener(MoverCharacter.ON_ANI_IDLE, onAvatarIsInPosition, false, 0, true);
			FPS.timerGet('walkNodeGoal start');
			_isoAvatar.walkNodeGoal(nodes);
			FPS.timerGet('walkNodeGoal finish');
		}
		
		private function getMeleeNodes(inIsoTarget:IsoBase, inDistStart:int, inNodes:Array):Array 
		{
			var isoMap:IsoMap = IsoController.gi.isoWorld.isoMap;
			var distCurrent:int = inDistStart;
			var xLeft:int;
			var yLeft:int;
			var xRight:int;
			var yRight:int;
			var tries:int = 5;
			var success:Boolean = false;
			
			//for (var i:int = 0; i < 10; i++) {
				xLeft = Math.round(inIsoTarget.isoX + inIsoTarget.isoSize + distCurrent);
				yLeft = Math.round(inIsoTarget.isoY - distCurrent - 1);
				xRight = Math.round(inIsoTarget.isoX - distCurrent - 1);
				yRight = Math.round(inIsoTarget.isoY + inIsoTarget.isoSize + distCurrent);
				distCurrent++;
				success = false;
				if (isoMap.getIsoTileFree(xLeft, yLeft)) {
					inNodes.push(new AStarNode(xLeft, yLeft));
					success = true;
				}
				if (isoMap.getIsoTileFree(xRight, yRight)) {
					inNodes.push(new AStarNode(xRight, yRight));
					success = true;
				}
				//if (success) break;
				if (!success) {
					inNodes.push(new AStarNode(inIsoTarget.isoX, inIsoTarget.isoY));
				}
			//}
			return inNodes;
		}
		
		private function getRangedNodes(inIsoBase:IsoBase, inRange:int):Array 
		{
			var nodes:Array = [];
			var map:IsoMap = IsoController.gi.isoWorld.isoMap;
			var tile:IsoTile;
			var size:int = inIsoBase.isoSize - 1;
			var range:int = inRange + 1;
			var xTarget:int = inIsoBase.isoX;
			var yTarget:int = inIsoBase.isoY;
			var xTargetMid:Number = inIsoBase.isoX + size * 0.5;
			var yTargetMid:Number = inIsoBase.isoY + size * 0.5;
			
			var xCurrent:int;
			var yCurrent:int;
			var xMin:int; 
			var yMin:int;
			var xMax:int; 
			var yMax:int;
			var isInQuadrantLeft:Boolean;
			var isInQuadrantRight:Boolean;
			
			var distanceX:Number;
			var distanceY:Number;
			var distanceCenter:Number;
			
			xMin = xTarget - range; 
			xMax = xTarget + range + size;
			yMin = yTarget - range; 
			yMax = yTarget + range + size;
			
			for (yCurrent = yMin; yCurrent <= yMax; yCurrent++) {
				for (xCurrent = xMin; xCurrent <= xMax; xCurrent++) {
					isInQuadrantLeft =	(xCurrent <= xTarget + size && yCurrent >= yTarget);
					isInQuadrantRight =	(xCurrent >= xTarget && yCurrent <= yTarget + size);
					if (isInQuadrantLeft || isInQuadrantRight) {				// only consider tiles to the left or right of the target
						distanceX = xCurrent - xTargetMid;
						distanceY = yCurrent - yTargetMid;
						distanceCenter = Math.sqrt(distanceX*distanceX + distanceY*distanceY);
						if (Math.floor(distanceCenter) < range + size * 0.5) { 				// is this tile within range of the target's EDGE
							tile = map.getIsoTile(xCurrent, yCurrent);
							if (xCurrent != xTarget || yCurrent != yTarget) {	// the target must not be standing on it
								if (tile && tile.isWalkable) {					// is this a valid and walkable tile
									nodes.push(new AStarNode(xCurrent, yCurrent));	// add to the list of valid tiles to walk to					
								}
							}							
						}
					}
				}
			}
			
			return nodes;
		}
		
		private function onAvatarIsInPosition(e:Event = null):void
		{
//			tr("onAvatarIsInPosition()");
			
			_isAvatarInPosition = true;
			_isoAvatar.mover().removeEventListener(MoverCharacter.ON_ANI_IDLE, onAvatarIsInPosition, false);
			//trace('IsoControllerFight assembledAvatar ' + e.target + " " + e.type);
			
			if (_isAvatarAttackAniReady)
			{
				dispatchEvent(new Event(EVENT_POSITIONS_READY));
			}
		}
		
		private function onAvatarAttackAniReady(inMC:MovieClip, inProjectile:Projectile):void
		{
			
//			tr("onAvatarAttackAniReady()");
			
			_isoAvatar.replaceAsset(inMC, IsoCharacter.ANI_ARRAY_ATTACK, 0);
			_isAvatarAttackAniReady = true;
			
			if (inProjectile) 
			{
				_projectile = inProjectile;
				_moverProjectile = new MoverProjectile(_isoAvatar, _isoTarget, _projectile);
			}
		
			if (_isAvatarInPosition)
			{
				dispatchEvent(new Event(EVENT_POSITIONS_READY));
			}
		}
		
		public function attackStart(isRevengeDodged:Boolean = false):void
		{
			_revengeDodged = isRevengeDodged;
//			tr('attackStart() IsoControllerFight attackStart _revengeDodged: ' + _revengeDodged);

			_attacksComplete = 0;
			
			if (_moverProjectile && _isoAvatar.hasFightAsset) {
				_isoAvatar.mover().addEventListener(MoverCharacter.ON_ANI_ATTACK_LAUNCH,	attackLaunchProjectile, false, 0, true);
				_isoAvatar.mover().addEventListener(MoverCharacter.ON_ANI_TIMELINE_COMPLETE,attackLaunchProjectile, false, 0, true);
				_moverProjectile.addEventListener(MoverProjectile.ON_PROJECTILE_COMPLETE,	attackComplete, false, 0, true);
				_moverProjectile.addEventListener(MoverProjectile.ON_PROJECTILE_HIT,		attackHit, false, 0, true);			
			}else if(_isoAvatar.hasFightAsset || true){
				_isoAvatar.mover().addEventListener(MoverCharacter.ON_ANI_ATTACK_COMPLETE,	attackComplete, false, 0, true);
				_isoAvatar.mover().addEventListener(MoverCharacter.ON_ANI_ATTACK_LAUNCH,	attackHit, false, 0, true);
				_isoAvatar.mover().addEventListener(MoverCharacter.ON_ANI_ATTACK_HIT,		attackHit, false, 0, true);
			}else{
				attackComplete();
				//(_isoTarget as IsoMonster).mover().addEventListener(MoverCharacter.ON_ANI_TIMELINE_COMPLETE,	attackComplete, false, 0, true);
				if (_isoTarget is IsoMonster) 
				{
					(_isoTarget as IsoMonster).mover().addEventListener(MoverCharacter.ON_ANI_ATTACK_COMPLETE,	attackComplete, false, 0, true);
					attackHit();
				}else{
					attackComplete();
				}
				return;
			}
			
			_isoAvatar.mover().addEventListener(MoverCharacter.ON_ANI_HIT_REACT, reactHit, false);		
			
			if (_isoTarget is IsoMonster) 
			{
				if((_isoTarget as IsoMonster).hasFightAsset)
				{
					(_isoTarget as IsoMonster).mover().addEventListener(MoverCharacter.ON_ANI_ATTACK_COMPLETE,	attackComplete, false, 0, true);
				}else{
					attackComplete();
				}
			}else{
//				attackComplete();
				_attacksComplete++;
			}
			_isoAvatar.mover().attack(_isoTarget);
		}
		
		
		private function attackLaunchProjectile(e:Event = null):void 
		{
			if(_moverProjectile) 
				_moverProjectile.start();
			
			if(_isoAvatar && _isoAvatar.mover())
			{
				_isoAvatar.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_LAUNCH,		attackLaunchProjectile);
				_isoAvatar.mover().removeEventListener(MoverCharacter.ON_ANI_TIMELINE_COMPLETE,	attackLaunchProjectile);
			}	
		}
		
		private function attackHit(e:Event = null):void {
			//trace('IsoControllerFight attackHit ' + e.target);
			if (_isoTarget is IsoCharacter) {
				(_isoTarget as IsoCharacter).mover().hitReact(_isoAvatar);
			}
			
			dispatchEvent(new Event(EVENT_HIT_COMPLETE));
			_didDispatchHit = true;
		}
		
		private function reactHit(e:Event = null):void
		{
			dispatchEvent(new Event(EVENT_RECEIVE_HIT));
		}
		
		private function attackComplete(e:Event = null):void 
		{
//			tr("attackComplete()  1");
			
			_attacksComplete++;
			if (!(_isoTarget is IsoCharacter)) {
				_attacksComplete++;
			}
			//trace('IsoFightController attackComplete: _attacksComplete = ' + _attacksComplete);
			
			if (!_didDispatchHit)
			{
//				tr("attackComplete() !_didDispatchHit", _isoTarget);
				attackHit();
				return;
			}else{
//				tr("attackComplete() _didDispatchHit", _isoTarget);
			}
			
			if (_attacksComplete < 2) {
				//trace('IsoFightController attackComplete: return');
				return;
			}
			//trace('IsoFightController attackComplete: completing');
			_isoAvatar.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_COMPLETE,	attackComplete, false);
			_isoAvatar.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_LAUNCH,		attackHit, false);
			_isoAvatar.mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_HIT,		attackHit, false);
			
			if (_moverProjectile) {
				_moverProjectile.removeEventListener(MoverProjectile.ON_PROJECTILE_COMPLETE,	attackComplete, false);
				_moverProjectile.removeEventListener(MoverProjectile.ON_PROJECTILE_HIT,			attackHit, false)		
			}
			
			dispatchEvent(new Event(EVENT_OFFENSE_COMPLETE));
			
//			tr("attackComplete()   2", _isoTarget);
			
			if (_isoTarget is IsoMonster && IsoMonster(_isoTarget).willDie == false) 
			{
				(_isoTarget as IsoMonster).mover().removeEventListener(MoverCharacter.ON_ANI_ATTACK_COMPLETE, attackComplete, false);
				
//				tr("attackComplete()", "call revenge", (_isoTarget as IsoMonster).hasFightAsset);
				
				if((_isoTarget as IsoMonster).hasFightAsset || true)
				{
					_revenge = new IsoControllerRevenge(IsoMonster(_isoTarget), IsoAvatar(_isoAvatar), _revengeDodged);
					_revenge.start(revengeComplete, (_isoTarget as IsoMonster).assetsFailed);
				}else{
					reactHit();
					revengeComplete();
				}
				
			}else{
				dispatchComplete();
			}

			//_isoTarget.visible = true;
			//TweenNano.delayedCall(1, dispatchComplete);
		}
		
		private function revengeComplete():void 
		{
//			tr('revengeComplete()');
			
			dispatchEvent(new Event(EVENT_REVENGE_COMPLETE));
			dispatchComplete();
		}
		
		private function dispatchComplete():void
		{
//			tr('dispatchComplete()');
			
			isBusy = false;
			if (_disposed) return;
			
			dispatchEvent(new Event(EVENT_FIGHT_COMPLETE));
		}
		
		public function releaseClients():void 
		{
			isBusy = false;
			if (_isoAvatar) {
				_isoAvatar.isFighting = false;
				_isoAvatar.doChangePending();
			}
			
			IsoController.gi.isoWorld.isoMap.releaseAvatar();
			
			if (_isoTarget is IsoMonster && IsoMonster(_isoTarget).isAlive) 
			{
				MoverMonster(IsoMonster(_isoTarget).mover()).idle();
			}
		}
		
		/*public function get busy():Boolean 
		{
			return isBusy;
		}*/
		
//		public function tr(...rest):void
//		{
//			var args:Array = ["\t ["+getTimer()/1000+"] \t{∆∆∆∆} ", this].concat(rest);
//			trace.apply(this, args);
//		}		
	}
}

