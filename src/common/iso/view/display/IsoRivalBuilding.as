package common.iso.view.display
{
	import com.greensock.TweenLite;
	import com.raka.crimetown.model.game.Building;
	import com.raka.crimetown.model.game.ITargetable;
	import com.raka.crimetown.model.game.PlayerBuilding;
	import com.raka.crimetown.model.game.PlayerBuildingStateChangeEvent;
	import com.raka.crimetown.util.sound.CTSoundFx;
	import com.raka.media.sound.RakaSoundManager;
	
	import common.ui.view.overlay.BuildingHealthOverlay;
	import common.ui.view.overlay.EnemyNameAndHealth;
	import common.ui.view.overlay.GoalArrowOverlay;
	import common.ui.view.tutorial.controller.TutorialController;
	import common.ui.view.tutorial.model.TutorialObjects;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	public class IsoRivalBuilding extends IsoPlayerBuilding implements ITargetable
	{
		public static const RIVAL_HIGHLIGHT_COLOR:int = 0xefaa03;
		public static const RIVAL_HIGHLIGHT_FILTER:GlowFilter = new GlowFilter(RIVAL_HIGHLIGHT_COLOR, 1, 2, 2, 100, BitmapFilterQuality.HIGH);
		
		private var _goalArrowOverlay:GoalArrowOverlay;
		private var _healthOverlay:BuildingHealthOverlay;
		private var _hitCount:int;
		private var _startHealth:Number;
		private var _willTakeDamage:Boolean;
		private var _attackPointsGenerated:int;
		
		public var damagedHealth:Number = 0;
		
		public function IsoRivalBuilding()
		{
			super();
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage)
			
			_highlightColor = RIVAL_HIGHLIGHT_COLOR;
			_hitCount = 0;
			_willTakeDamage = false;
			_attackPointsGenerated = 0;
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			if (_healthOverlay)
			{
				_healthOverlay.dispose();
				_healthOverlay = null;
			}
			
			TweenLite.killDelayedCallsTo(hideOverlay);
			TweenLite.killDelayedCallsTo(destroy);
		}
		
		protected function onAddedToStage(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
			// flag for tutorial
			if(model.building.output_type == Building.OUTPUT_TYPE_FOOD_PRODUCTION && TutorialController.getInstance().active)
			{
				TutorialObjects.setObject(tutorialDisplayObject , TutorialObjects.ATTACK_RIVAL);
			}	
		}
		
		override protected function initializeOverlay():void
		{
			_startHealth = model.current_health;
			_healthOverlay = new BuildingHealthOverlay(_startHealth, model.generated_player_building_values.max_health);
		}
		
		private function hideOverlay():void
		{
			_willTakeDamage = false;
			
			if (_healthOverlay) 
				_healthOverlay.hide();
		}
		
		override protected function updateOverlayPosition():void
		{
			if (_healthOverlay)
				_healthOverlay.setMapPosition(mapOverlayPostion);
		}

		override protected function onModelStateChange(event:PlayerBuildingStateChangeEvent=null):void
		{
			event = event ? event : new PlayerBuildingStateChangeEvent(model.state, model.state);
			
			switch (model.state)
			{
				case PlayerBuilding.DESTROYED:
					showDestroyedGraphic();
					break;
				
				case PlayerBuilding.CONSTRUCTING:
				case PlayerBuilding.WAITING_TO_START_CONSTRUCTION:
					showUnderConstructionGraphic();
					break;
				
				default:
					showCompletedBuildingGraphic();
					break;
			}
			
			_healthOverlay.currentHealth = model.current_health;
		}
		
		override protected function onLoadBuildingComplete():void
		{
			updateOverlayPosition();
		}	
		
		override public function get tutorialDisplayObject():DisplayObject
		{
			return this;
		}	
		
		override protected function showHighlight(show:Boolean):void
		{
			if (show)
			{
				var filter:GlowFilter = IsoRivalBuilding.RIVAL_HIGHLIGHT_FILTER;
				
				_assetDisplay.filters = [filter];
			}
			else
				_assetDisplay.filters = [];
		}
		
		override public function mouseUp():void {}
		
		public function showHealthBar():void
		{
			_startHealth = model.current_health;
			
			if (shouldShowHealthBar) 
			{
				_healthOverlay.maxHealth = model.generated_player_building_values.max_health;
				_healthOverlay.show();
			}
			
			updateOverlayPosition();
		}
		
		protected function get shouldShowHealthBar():Boolean
		{
			return _startHealth > 0 && model.state != PlayerBuilding.DESTROYED && model.state != PlayerBuilding.CONSTRUCTING && model.state != PlayerBuilding.WAITING_TO_START_CONSTRUCTION;
		}
		
		public function getAttackPoint():Point
		{
			var point:Point = new Point();
			point.x = isoX - isoWidth/2 + 4 + 2 * _attackPointsGenerated;
			point.y = isoY + isoLength/2 + 4;
			
			_attackPointsGenerated = (_attackPointsGenerated + 1) % (isoWidth/2);
			return point;
		}
		
		public function buildingWillTakeDamage():void
		{
			_willTakeDamage = true;
		}
		
		public function battleComplete():void
		{
			if (_willTakeDamage && damagedHealth <= 0) destroy();
			
			TweenLite.delayedCall(0.5, hideOverlay);
		}
		
		public function destroy():void
		{
			if (model.state == PlayerBuilding.DESTROYED) return;
			
			model.state = PlayerBuilding.DESTROYED;
			model.current_health = 0;
			_healthOverlay.currentHealth = 0;
			
			RakaSoundManager.getInstance().playSoundFX(CTSoundFx.BUILDING_DESTROYED);
		}
		
		public function receiveDamage():void
		{
			if (!_willTakeDamage || model.state == PlayerBuilding.DESTROYED) return;
			if (isNaN(damagedHealth)) damagedHealth = 0;
			
			_hitCount ++;
			
			var hitsToZero:Number = 4;
			var percent:Number = Math.min(hitsToZero - _hitCount, hitsToZero) / hitsToZero;
			percent = Math.max(0, Math.min(1, percent));
			
			var newHealth:Number = percent * (_startHealth - damagedHealth) + damagedHealth
			_healthOverlay.currentHealth = newHealth;
			
			if (newHealth <= 0) TweenLite.delayedCall(0.5, destroy);
		}
		
		public function get isAttackable():Boolean
		{
			return model.isAttackable;
		}
		
		public function get isRanged():Boolean
		{
			return false;
		}
		
		public function get isoBase():IsoBase
		{
			return this;
		}
		
		public function get destX():int
		{
			return isoX;
		}
		
		public function get destY():int
		{
			return isoY;
		}
		
		public function set target(aTarget:ITargetable):void
		{
			
		}
		
		public function get target():ITargetable
		{
			return null;
		}
		
		public function get isRivalUnit():Boolean
		{
			return true;
		}
		
		public function setDestination(destX:int, destY:int):void
		{
			trace("IsoRivalBuilding does not acknowledge setDestnation calls");
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
				//_goalArrowOverlay.(new Point(x, y - this._assetDisplay.height))
			}
		}
		
		public function goalArrowShow(value:Boolean):void
		{
			if (!_goalArrowOverlay)
				return; 
			
			if (value)
			{
				_goalArrowOverlay.show();
				_goalArrowOverlay.setMapPosition(new Point(this.x, mapOverlayPostion.y));
			}
			else
			{
				_goalArrowOverlay.hide();
			}
		}

	}
}
