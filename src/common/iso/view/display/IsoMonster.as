package common.iso.view.display
{

	import com.greensock.TweenNano;
	import com.greensock.layout.AlignMode;
	import com.raka.crimetown.business.command.enemy.SelectEnemyCommand;
	import com.raka.crimetown.model.GameObjectManager;
	import com.raka.crimetown.model.game.EnemyActive;
	import com.raka.crimetown.model.game.EnemyRequirement;
	import com.raka.crimetown.model.game.Player;
	import com.raka.crimetown.util.text.TextFieldUtil;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.ai.MoverCharacter;
	import common.iso.control.ai.MoverMonster;
	import common.iso.control.ai.TutorialMover;
	import common.iso.model.EnemyOverlayVO;
	import common.iso.model.IsoModel;
	import common.test.debug.FPS;
	import common.ui.view.overlay.EnemyNameAndHealth;
	import common.ui.view.overlay.EnemyOverlay;
	import common.ui.view.overlay.GoalArrowOverlay;
	import common.ui.view.tutorial.TutorialEvent;
	import common.ui.view.tutorial.controller.TutorialController;
	import common.ui.view.tutorial.model.TutorialData;
	import common.ui.view.tutorial.model.TutorialObjects;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;

	public class IsoMonster extends IsoCharacter implements IAttackableIso, IIsoGoal
	{
		// arrays of all the possible suffix's for the different monster clip classes
		public static var WALK_TYPES:Array = ["walk_S", "walk_SE", "walk_E", "walk_NE", "walk_N"];
		public static var IDLE_TYPES:Array = ["idle_S", "idle_SE", "idle_E", "idle_NE", "idle_N"];
		public static var ATTACK_TYPES:Array = ["attack", "attack", "attack", "attack", "attack"];
		public static var HIT_TYPES:Array = ["hit", "hit", "hit", "hit", "hit"];
		public static var DEATH_TYPES:Array = ["death", "death", "death", "death", "death"];
		
		private const NAME_PADDING:int = 65;
		private const GOAL_ARROW_PADDING:int = 75;

		private var _model:EnemyActive;
		private var _nameOverlay:EnemyNameAndHealth;
		private var _goalArrowOverlay:GoalArrowOverlay;
		private var _overlay:EnemyOverlay;
		private var _overlayData:EnemyOverlayVO;
		private var _assetsFailed:Boolean;
		private var _queueCount:int = 0;
		private var _disposed:Boolean = false;
		public var willDie:Boolean = false;
		
		public function IsoMonster()
		{
			this.alpha = 0;
			super();
			
		}
		
		public function get isTutorialTarger():Boolean
		{
			return TutorialController.getInstance().active && model && model.enemy_id == TutorialData.TUTORIAL_ENEMY_ID
		}	
		
		public override function dispose():void
		{
			if (_disposed) 
			{
				return;
			}
			else
			{
				_disposed = true;
				if (_assetsFailed)
				{
					trace('');
				}
			}
			
			super.dispose();
			
			_model = null;
			if (_nameOverlay)
			{
				_nameOverlay.dispose();
				_nameOverlay = null;
			}
			
			if (_goalArrowOverlay)
			{
				_goalArrowOverlay.dispose();
				_goalArrowOverlay = null;
			}
			
			if (_overlay)
			{
				_overlay.dispose();
				_overlay = null;				
			}
			
			_overlayData = null;
			
			TweenNano.killTweensOf(this);
		}
		

		
		//  PRIVATE FUNCTIONS
		// -----------------------------------------------------------------//

		/**
		 *	Instantiate all the walk and idle movie clips that will be used
		 * 	by this monster.
		 */
		private function initView():void
		{
			if (super._assetLoaded) {
				// only add animations if assets didn't fail
				addAnimations(WALK_TYPES, IsoCharacter.ANI_ARRAY_WALK);
				addAnimations(IDLE_TYPES, IsoCharacter.ANI_ARRAY_IDLE);
				addAnimations(ATTACK_TYPES, IsoCharacter.ANI_ARRAY_ATTACK);
				addAnimations(HIT_TYPES, IsoCharacter.ANI_ARRAY_HIT);
				addAnimations(DEATH_TYPES, IsoCharacter.ANI_ARRAY_DEATH);
			}
			addMover();
		}
		
		private function addMover():void 
		{
			if (_disposed) 
			{
				return;
			}
			
			if(isTutorialTarger)
			{
				TutorialObjects.setObject(this, TutorialObjects.KILL_GOBLIN);
				if(_characterMover) _characterMover.dispose();
				_characterMover = new TutorialMover(this);
			}
			
			_characterMover.addEventListener(MoverCharacter.ON_ANI_DIE_COMPLETE, onDieComplete);
			_characterMover.speed = _model.enemy.move_speed;
			_characterMover.speedRatio = _model.enemy.move_anim_rate;
		}
		
		override protected function addedToStage():void
		{
			maybeShowEnemy();
		}
		
		private function addTooltip():void
		{
			_nameOverlay = new EnemyNameAndHealth();
			
			_overlay = new EnemyOverlay(model.enemy.isElite ? EnemyOverlay.ELITE_OVERLAY : EnemyOverlay.STANDARD_OVERLAY);
			_overlayData = new EnemyOverlayVO();
		}

		private function addAnimations(items:Array, animation:String):void
		{
			var item:String;

			for each (item in items)
				addAnimation(getLibraryItemInstance(item), animation);
		}

		/**
		 *	After assets for this monster have been succesfully loaded.
		 */
		private function onEnemyLoad():void
		{
			
			initView();	
			
			// add overlay – waited because we don't want a overlay showing without an enemy
			// correction, yes we do
			
			addUI(_nameOverlay);
			updateNamePostition();
			
			maybeShowEnemy();
		}
		
		private function onEnemyFail():void
		{
			_assetsFailed = true;
			onEnemyLoad();
		}
		
		private function maybeShowEnemy():void
		{
			if(super._assetLoaded && this.stage)
			{
				// asset success
				moveStart();
				fadeIn();
			}else if (_assetsFailed && this.stage) {
				// asset failed
				moveStart();
				fadeIn();
			}
		}
		
		override public function onAssetUpdated():void
		{
			updateNamePostition();
		}	
		
		override public function updateOverlayPosition():void
		{
			if(_goalArrowOverlay)
				_goalArrowOverlay.setMapPosition(new Point(x, y - assetIdleHeight - GOAL_ARROW_PADDING));
		}
		
		private function updateNamePostition():void
		{
			if(_nameOverlay)
			{
				_nameOverlay.x = _assetDisplay.x;
				_nameOverlay.y = -(assetIdleHeight) - NAME_PADDING;
			}
		}	
		
		public override function moveStart():void
		{
			if(_characterMover){
				(_characterMover as MoverMonster).start();
			}
			
			
			if (isTutorialTarger) moveStop();
		}

		public override function moveStop():void
		{
			if(_characterMover){
				(_characterMover as MoverMonster).stop();
			}
			
		}

		public override function mover():MoverCharacter
		{
			return (_characterMover as MoverMonster);
		}

		protected override function redraw():void
		{
			super.redraw();
		}
		
		private function fadeIn():void
		{
			if(!_initialized) {
				return;
			}
			TweenNano.killTweensOf(this);
			
			alpha = 0;
			TweenNano.to(this, 1, {alpha:1});
		}	
		
		private function fadeOutAndRemove():void
		{
			TweenNano.to(this, 1, {alpha:0, onComplete:fadeOutComplete});
		}	
		
		private function fadeOutComplete():void
		{
			map.removeChildObj(this);
			this.dispose();
		}	
		
		public function get isAttackable():Boolean
		{
			return isTutorialTarger || !TutorialController.getInstance().active;
		}	

		//  IAttackableIso FUNCTIONS
		// -----------------------------------------------------------------//
		override public function get isAlive():Boolean
		{
			return (_model) ? _model.isAlive : false;
		}
		
		public function get energyPerAttack():Number
		{
			return model.enemy.energy_cost;
		}
		
		public function get requirements():Array
		{
			var reqs:Array = [];
			for each (var req:EnemyRequirement in _model.generated_requirements)
			{
				if (req.requirement_fulfill_id && req.requirement_fulfill_id != 0)
					reqs.push(req);
			}	
			
			return reqs;
		}
		
		public function areRequirementsMet():Boolean
		{
//			trc("areRequirementsMet()");
			
			var player:Player = GameObjectManager.player;
			for each (var req:EnemyRequirement in requirements)
			{
//				trc("Req :: ", req.id, req.requirement_fulfill_id, "has:", req.getPlayerQuantity(player), "needs:", req.requirement_fulfill_quantity, "MET?", req.getMissingQuantity(player) > 0);
				if (req.getMissingQuantity(player) > 0) return false;
			}
			
			return true;
		}
		
		public function kill():void
		{
			Log.info(this, 'IsoMonster kill()');
			model.time_expires = null;
			model.respawnTime = -1;
		
			goalArrowEnable(false);
			
			(_characterMover as MoverMonster).die();
			
			if (isTutorialTarger)
			{
				new TutorialEvent(TutorialEvent.GOBLIN_HIT).dispatch();
				new TutorialEvent(TutorialEvent.GOBLIN_KILLED).dispatch();
			}
		}	
		
		public function reset():void
		{
			Log.info(this, 'IsoMonster reset()');
			_model.time_expires = null;
			_model.health = _model.max_health;
			updateStats();

			this.model = _model;
		}	
		
		public function spawn():void
		{
			map.addChildRandomLocation(this as IsoCharacter);
			fadeIn();
			
			if(isTutorialTarger) 
			{
				var center:Point = map.getCenterIsoPoint();
				isoX = center.x + 5;
				isoY = center.y - 5;
				
				if (_characterMover) MoverMonster(_characterMover).setAllowMovement(false);
			}
		}	
		
		public function get respawnTime():Number
		{
			if(!isAlive) return -1;
			return model.respawnTime;
		}
		
		public function set respawnTime(value:Number):void
		{
			model.respawnTime = value;
		}
		
		public function get resetTime():Number
		{
			if(!isAlive) return -1;
			return model.resetTime;
		}
		
		public function get queueCount():int
		{
			return _queueCount;
		}
		
		public function set queueCount(value:int):void
		{
			_queueCount = value;
			updateStats();
		}
		
		public function handleAttackResult(result:Object):void
		{
			model = result.enemy_active as EnemyActive;
			updateStats();
		}	
		
		public function updateStats():void
		{
			if (model && _overlayData)
			{
				_overlayData.name = model.enemy.display_name;
				_overlayData.type = TextFieldUtil.capitalize(model.enemy.enemyType);
				_overlayData.health = model.health;
				_overlayData.maxHealth = model.max_health;
				_overlayData.energyCost = model.enemy.energy_cost;
				_overlayData.queueCount = queueCount;
				
				if(model.isInjured && isTutorialTarger)
				{
					new TutorialEvent(TutorialEvent.GOBLIN_HIT).dispatch();
				}
			
				if(model.enemy.isElite)
				{
					_overlayData.startTime = model.startTime;
					_overlayData.endTime = model.resetTime;
				}
				
				if (_nameOverlay)
				{
					if (model && model.isInjured)
						_nameOverlay.state = EnemyNameAndHealth.NAME_AND_HEALTH;
					else
						_nameOverlay.state = EnemyNameAndHealth.NAME;
					
					_nameOverlay.type = model.enemy.isElite ? EnemyNameAndHealth.ELITE_NAME : EnemyNameAndHealth.STANDARD_NAME;
					_nameOverlay.data = _overlayData;
				}
				
				if (_overlay)
				{
					_overlay.data = _overlayData;
				}
			}
		}	

		//  HANDLER FUNCTIONS
		// -----------------------------------------------------------------//
		
		protected function onDieComplete(event:Event):void
		{
			if (_assetsFailed) 
			{
				// delay death if no assets
				TweenNano.to(this,1, {onComplete:fadeOutAndRemove});
			}
			else
			{
				fadeOutAndRemove();
			}
			goalArrowEnable(false);
		}

		
		// ISOSTATE OVERRIDES
		// -----------------------------------------------------------------//
		
		override protected function showHighlight(show:Boolean):void
		{
			if(!isAttackable) return;
			
			super.showHighlight(show);
			
			if (_nameOverlay)
			{
				if (model && model.isInjured)
					_nameOverlay.state = EnemyNameAndHealth.NAME_AND_HEALTH;
				else
					_nameOverlay.state = EnemyNameAndHealth.NAME;				
			}
			
			if (show)
			{
				if (_goalArrowOverlay)
					goalArrowShow(false);
				
				if (_nameOverlay)
					_nameOverlay.hide();
				
				if (_overlay)
				{		
					_overlay.setMapPosition(mapOverlayPostion);
					_overlay.show();					
				}
			}
			else
			{
				if (_goalArrowOverlay)
					goalArrowShow(true);
				
				if (_nameOverlay)
					_nameOverlay.show();
				
				if (_overlay)
				{
					_overlay.setMapPosition(mapOverlayPostion);
					_overlay.hide();					
				}
			}
		}
		
		override protected function showJobActive(show:Boolean):void
		{
			if (!_nameOverlay)
				return;
			
			if (show || (model && model.isInjured))
				_nameOverlay.state = EnemyNameAndHealth.NAME_AND_HEALTH;
			else
				_nameOverlay.state = EnemyNameAndHealth.NAME;
		} 
		
		override public function mouseUp():void
		{
			if(isAttackable)
			{
				FPS.timerStart();
				FPS.timerGet();
				if(isAlive)
					new SelectEnemyCommand(this).execute();
			}
			
		}
		
		override protected function makeMoveable(isAllowedToMove:Boolean):void
		{
			return;	// TODO VC:	der... should we delete this method? why is it just returning? clean up
			
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

		//  GETTERS & SETTERS
		// -----------------------------------------------------------------//
		
		public function get assetsFailed():Boolean
		{
			return _assetsFailed;
		}
		
		public function get model():EnemyActive
		{
			return _model;
		}

		public function set model(value:EnemyActive):void
		{
			_model = value as EnemyActive;

			if (!_initialized)
			{
				_initialized = true;
				
				_cacheKey = _model.enemy.base_cache_key;
				_assetURL = IsoModel.gi.getMonsterUrl(_cacheKey);

				addTooltip();
				updateStats();
				
				loadAsset(onEnemyLoad, onEnemyFail);
			}

		}

		public function get tooltipData():EnemyOverlayVO
		{
			return _overlayData;
		}
		
		public function goalArrowEnable(value:Boolean):void
		{
			if (!value && _goalArrowOverlay)
			{
				_goalArrowOverlay.dispose();
				_goalArrowOverlay = null;
			}
			else if (value && !_goalArrowOverlay)
			{
				_goalArrowOverlay = new GoalArrowOverlay();
				updateOverlayPosition();
			}
		}
		
		public function goalArrowShow(value:Boolean):void
		{
			if (!_goalArrowOverlay)
				return; //goalArrowEnable(true);
			
			if (value && isAlive)
			{
				_goalArrowOverlay.show();
				updateOverlayPosition();
			}
			else
			{
				_goalArrowOverlay.hide();
			}
		}
		
	}
}
