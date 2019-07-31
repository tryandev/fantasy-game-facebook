package common.iso.view.display
{
	import com.greensock.TweenMax;
	import com.greensock.TweenNano;
	import com.raka.crimetown.business.command.building.CancelBuildingConstructionCommand;
	import com.raka.crimetown.business.command.building.CancelBuildingUpgradeCommand;
	import com.raka.crimetown.business.command.building.RepairBuildingCommand;
	import com.raka.crimetown.business.command.harvest.AsyncHarvestBuildingCommand;
	import com.raka.crimetown.control.town.area.PlayerBuildingTimer;
	import com.raka.crimetown.model.game.Building;
	import com.raka.crimetown.model.game.CollectResult;
	import com.raka.crimetown.model.game.LootItem;
	import com.raka.crimetown.model.game.PlayerBuilding;
	import com.raka.crimetown.model.game.PlayerBuildingStateChangeEvent;
	import com.raka.crimetown.model.game.QueuedUnit;
	import com.raka.crimetown.model.game.lookup.GameObjectLookup;
	import com.raka.crimetown.util.AppConfig;
	import com.raka.crimetown.util.GameConfigEnum;
	import com.raka.crimetown.util.sound.CTSoundFx;
	import com.raka.crimetown.view.popup.CancelBuildingPopup;
	import com.raka.crimetown.view.popup.PopupManager;
	import com.raka.crimetown.view.popup.PopupPriorities;
	import com.raka.crimetown.view.popup.PopupProperties;
	import com.raka.crimetown.view.popup.bank.BankPopup;
	import com.raka.crimetown.view.popup.finishBuilding.FinishBuildingPopup;
	import com.raka.crimetown.view.popup.research.ResearchPopup;
	import com.raka.crimetown.view.popup.speedUp.SpeedupPopup;
	import com.raka.crimetown.view.popup.transitions.PopupTransitionType;
	import com.raka.crimetown.view.popup.unit.control.UnitController;
	import com.raka.crimetown.view.popup.upgrade.UpgradePopupHelper;
	import com.raka.crimetown.view.tooltip.LootItemIcon;
	import com.raka.media.sound.RakaSoundManager;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.IsoController;
	import common.iso.control.mouse.IsoMouseBuildingHelper;
	import common.iso.model.BuildingOverlayVO;
	import common.iso.view.containers.IsoWorld;
	import common.ui.view.overlay.BuildingFlagOverlay;
	import common.ui.view.overlay.BuildingInfoOverlay;
	import common.ui.view.overlay.BuildingProgressOverlay;
	import common.ui.view.overlay.BuildingStatsOverlay;
	import common.ui.view.overlay.ProgressiveBuildingStatsOverlay;
	import common.ui.view.tutorial.TutorialEvent;
	import common.ui.view.tutorial.controller.TutorialController;
	import common.ui.view.tutorial.model.TutorialObjects;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	public class IsoPlayerBuilding extends IsoBuilding
	{
		public static const DEFENSE_HIGHLIGHT_COLOR:int = 0x0000FF;
		public static const ISO_MODEL_CHANGE:String = "IsoPlayerBuilding.ISO_MODEL_CHANGE";
		
		protected var _progress:BuildingProgressOverlay;
		protected var _overlay:BuildingStatsOverlay;
		protected var _flag:BuildingFlagOverlay;
//		protected var _isDragging:Boolean = false;
		
		protected var _data:BuildingOverlayVO;
		
		protected var _highlightColor:uint;
		protected var _buildingGlowHelper:IsoMouseBuildingHelper;
		
		private var _isReparingAll:Boolean = false;
		
		public function IsoPlayerBuilding()
		{
			super();
			
			_highlightColor = DEFENSE_HIGHLIGHT_COLOR;
			
//			this.mouseChildren = false;
//			buttonMode = true;
//			useHandCursor = true;
		}
		
		override public function dispose():void
		{
			
			_data = null;	
			
			if (_overlay) 
			{
				_overlay.dispose();
				_overlay = null;
			}
			
			removeProgress();
			removeFlag();
			
			removeModelListeners();
			super.dispose();
		}	

		public function get model():PlayerBuilding
		{
			return _model as PlayerBuilding;
		}

		public function set model(value:PlayerBuilding):void
		{
			if (!value)
				return;

			removeModelListeners();
			
			_model = PlayerBuilding(value);
			
			model.addEventListener(PlayerBuildingStateChangeEvent.CHANGE, onModelStateChange)
			model.addEventListener(PlayerBuilding.EVENT_UPDATE_QUEUE, onUpdateQueue);
			
			if (!_initialized)
			{
				_initialized = true;
				
				initializeOverlay();
				
				positionIso();
			}

			onModelStateChange();
			
			dispatchEvent(new Event(ISO_MODEL_CHANGE));
		}	
		
		protected function initializeOverlay():void
		{
			if (model.building.output_type == Building.OUTPUT_TYPE_BANK)
				_overlay = new ProgressiveBuildingStatsOverlay(model.building.output_type);
			else
				_overlay = new BuildingStatsOverlay(model.building.output_type);
		}

		public function removeModelListeners():void
		{
			if (model)
			{
				model.removeEventListener(PlayerBuildingStateChangeEvent.CHANGE, onModelStateChange);
				model.removeEventListener(PlayerBuilding.EVENT_UPDATE_QUEUE, onUpdateQueue);
			}	
		}	
		
		public function get isInteractive():Boolean
		{
			return (TutorialController.getInstance().active && TutorialController.getInstance().currentFocusObject == tutorialDisplayObject) || !TutorialController.getInstance().active;
		}	
		
		public function updateOverylay():void 
		{
			updateOverlayPosition();
		}
		
		//  START FUNCTIONS
		// -----------------------------------------------------------------//
	
		public function startPlacement():void
		{
			alpha = 0.5;
		}	
		
		public function startConstruction():void
		{
			alpha = 1;
			
			RakaSoundManager.getInstance().playSoundFX(CTSoundFx.BUILDING_CONSTRUCTION);
			update();
			
			if (model.state == PlayerBuilding.WAITING_TO_START_CONSTRUCTION)
				showSpecialBuildingFinishPopUp();
		}
		
		public function startProduction():void
		{
			update();
		}
		
		public function startUpgrading():void
		{
			RakaSoundManager.getInstance().playSoundFX(CTSoundFx.BUILDING_CONSTRUCTION);
			update();
		}
		
		public function startResearching():void
		{
			update();
		}
		
		public function startRepairing(isReparingAll:Boolean=false):void
		{
			_isReparingAll = isReparingAll;
			model.timeLastRepairStarted = new Date().getTime();
			
			if (!_isReparingAll)
				RakaSoundManager.getInstance().playSoundFX(CTSoundFx.BUILDING_CONSTRUCTION);
			
			update();
		}
		
		public function startWither():void
		{
			model.timeLastWitherStarted = new Date().getTime();
			update();
		}
		
		public function startSpeedup():void
		{
			update();
		}	
		
		public function startFinishing():void
		{
			update();
		}
		
		public function cancelUpgrade():void
		{
			update();
		}	
	
		public function update():void
		{
			PlayerBuildingTimer.getInstance().update();	
			updateState();
		}
		
		public function updateProtectedMoney():void
		{
			setBuildingData("Click to Protect Money", 
				"Protecting " + model.player.protected_money, 0 , 0, model.player.protected_money, model.generated_player_building_values.current_output_quantity);
		}
		
		protected function updateOverlayPosition():void
		{
			if (_overlay)
				_overlay.setMapPosition(mapOverlayPostion);
			
			if (_flag)
				_flag.setMapPosition(mapOverlayPostion);
			
			if (_progress)
				_progress.setMapPosition(new Point(this.x, this.y));
		}	
		
		protected function updateOverlayData():void
		{
			if (_overlay)
				_overlay.data = _data;
			
			if (_flag)
				_flag.data = _data;
			
			if (_progress)
				_progress.data = _data;
		}	
		
		protected function setBuildingData(cta:String = "", detail:String = "", start:Number = 0, end:Number = 0, progress:int = 1, total:int = 1, paused:Boolean = false):void
		{
			_data = new BuildingOverlayVO();
			_data.cta = cta;
			_data.detail = detail;
			_data.level = model.upgrade_rank;
			_data.totalLevels = model.building.max_upgrade_rank;
			_data.name = model.building.name;
			_data.startTime = start;
			_data.endTime = end;
			_data.currentProgress = progress;
			_data.totalProgress = total;
			_data.paused = paused;
			
			updateOverlayData();
		}	
		
		protected function onModelStateChange(event:PlayerBuildingStateChangeEvent = null):void
		{
			event = event ? event : new PlayerBuildingStateChangeEvent(model.state, model.state);
			
			switch (model.state)
			{
				case PlayerBuilding.NOT_PLACED:
					break;
				
				case PlayerBuilding.CONSTRUCTING:
				case PlayerBuilding.UPGRADING:
				case PlayerBuilding.WAITING_TO_START_CONSTRUCTION:
				case PlayerBuilding.REPAIRING:
					showUnderConstructionGraphic();
					break;
				
				case PlayerBuilding.DESTROYED:
				case PlayerBuilding.WAITING_TO_REPAIR:
					showDestroyedGraphic();
					break;
				
				default:
					hideProgressDisplay();
					showCompletedBuildingGraphic();
					break;
			}
			
			switch (model.state)
			{
				case PlayerBuilding.REPAIRING:
					showRepairingProgressBar();
					setBuildingData("", "Repairing...", 
						model.repairTimePeriod.start, 
						model.repairTimePeriod.end);
					break;
				
				case PlayerBuilding.WAITING_TO_REPAIR:
				case PlayerBuilding.DESTROYED:
					showWaitingToRepair(BuildingFlagOverlay.REPAIR);
					setBuildingData("Click to Repair");
					break;
				
				case PlayerBuilding.CONSTRUCTING:
					showConstructionProgressBar();
					setBuildingData("", "Building...", 
						model.constructionTimePeriod.start, 
						model.constructionTimePeriod.end);
					break;
				
				case PlayerBuilding.UPGRADING:
					showUpgradeTooltip();
					setBuildingData("", "Upgrading...", 
									model.upgradeTimePeriod.start, 
									model.upgradeTimePeriod.end);		
					break;
				
				case PlayerBuilding.WAITING_TO_TRAIN:
					showWaitingToStart();
					setBuildingData("Click to Train");
					break;
				
				case PlayerBuilding.WAITING_TO_RESEARCH:
					showWaitingToResearch();
					setBuildingData("Click to Research");
					break;
				
				case PlayerBuilding.WAITING_TO_START_CONSTRUCTION:
					enterWaitToFinishState();
					setBuildingData("Click to Finish");
					break;
				
				case PlayerBuilding.PRODUCING_UNIT:
					onUnitUpdate();
					hideFlagDisplay();
					break;
				
				case PlayerBuilding.PRODUCING_RESEARCH:
					onResearchUpdate();
					hideFlagDisplay();
					break;
				
				case PlayerBuilding.PRODUCING_STAT:
					setBuildingData("Click to Upgrade", model.statDetails);
					hideFlagDisplay();
					break;
				
				case PlayerBuilding.BANK:
					updateProtectedMoney();
					hideFlagDisplay();
					break;
				
				case PlayerBuilding.PRODUCING:
					
					switch (event.oldState)
					{
						case PlayerBuilding.CONSTRUCTING:
						case PlayerBuilding.UPGRADING:
							hideProgressDisplay();
						case PlayerBuilding.WAITING_TO_START_CONSTRUCTION:
							model.resetTimeLastProductionStartedToNow();
							break;
					}
					
					setBuildingData("Click to Upgrade", 
									"Collect "+model.generated_player_building_values.actual_harvest_quantity, 
									model.productionTimePeriod.start, 
									model.productionTimePeriod.end);
								
					break;
				
				case PlayerBuilding.WITHERED:
				case PlayerBuilding.HARVESTABLE:
					showCollectStatus();
					setBuildingData("Click to Collect", "...", 
									0, 0, 
									model.generated_player_building_values.actual_harvest_quantity,
									model.generated_player_building_values.full_harvest_quantity);

					break;
			}
			
			trace(this)
			
			updateState();
			
		}
		
		protected function onUpdateQueue(event:Event):void
		{
			onUnitUpdate();
			onResearchUpdate();	
		}
		
		protected function onUnitUpdate():void
		{
			// check to see if array is null (note - unit queue is array)
			if (model.hasUnitQueue)
			{
				var unit:QueuedUnit = model.nextActiveUnit();
				
				if (unit.startable)
					setBuildingData("Click to Train More Units", "TRAINING "+ unit.unit.name, unit.startTime, unit.endTime);
				else
					setBuildingData("Click to Train More Units", "TRAINING "+ unit.unit.name, 0, 0, 1, 1, true);
			}
		}
		
		protected function onResearchUpdate():void
		{
			//  NOTE VC : this is called redundantly each time another building event happens 
			
			// check to see if object exists (note - research in an object becasue no queue is currently allowed) 
			if (model.hasResearchQueue)
			{
				if (model.state != PlayerBuilding.DESTROYED && model.state != PlayerBuilding.REPAIRING && model.state != PlayerBuilding.WAITING_TO_REPAIR)
					setBuildingData("Click to Speed Up", "RESEARCHING "+ model.tech_research.tech.name , model.tech_research.startTime, model.tech_research.endTime);
			}
		}
		
		
		
		//  PUBLIC HANDLERS
		// -----------------------------------------------------------------//
	
		/**
		 *	Executed when harvest sevice is sent without knowing the result.
		 */	
		public function onHarvestComplete():void
		{
			hideProductionResult();
			hideCollectIcon();
			
			showCollectEffect();
			
			showTooltipCollectEffect();
		}

		public function onHarvestFail():void
		{
//			model.timeLastProductionStarted = 0;
			model.updateTimeEvent();
			updateState();
			
		}
		
		//  MOUSE FUNCTIONS
		// -----------------------------------------------------------------//
		
		override public function mouseUp():void 
		{
			if (!isInteractive || model.hasPendingServiceCall)
				return;

			switch(model.state)
			{
				case PlayerBuilding.DESTROYED:
				case PlayerBuilding.WAITING_TO_REPAIR:
					repair();
					break;
				
				case PlayerBuilding.HARVESTABLE:
				case PlayerBuilding.WITHERED:
					if (!model.isBank)
						collect();
					break;
				
				case PlayerBuilding.WAITING_TO_RESEARCH:
				case PlayerBuilding.PRODUCING_RESEARCH:
					showResearchPopop();
					break;
				
				case PlayerBuilding.WAITING_TO_START_CONSTRUCTION:
					showSpecialBuildingFinishPopUp();
					break;
				
				case PlayerBuilding.PRODUCING_UNIT:
				case PlayerBuilding.WAITING_TO_TRAIN:
					showUnitsPopup();
					break;
				
				// when producing you can click to upgrade
				case PlayerBuilding.PRODUCING_STAT:
				case PlayerBuilding.PRODUCING:
					if (model.canUpgradeFurther()) UpgradePopupHelper.openUpgradePopup(model);
					break;
				
				case PlayerBuilding.BANK:
					PopupManager.instance.addPopup(new BankPopup(this), PopupProperties.NORMAL_MODAL, PopupPriorities.SEQUENTIAL, PopupTransitionType.SLIDE_IN_LEFT_OUT_RIGHT);
					break;
			}
		}
		
		protected function repair():void
		{
			Log.info(this, "Reparing " + this.cacheKey);
			new RepairBuildingCommand(model).execute();
		}
		
		
		private function collect():void
		{
			Log.info(this, "Harvesting " + this.cacheKey);
			
			new AsyncHarvestBuildingCommand(model).execute();
			
			var lootCountMin:int = AppConfig.game.getNumberValue(GameConfigEnum.LOOT_HARVEST_ICONS_COUNT_MIN);
			var lootPerDigit:int = AppConfig.game.getNumberValue(GameConfigEnum.LOOT_HARVEST_ICONS_PER_DIGIT);
			var lootCountMax:int = AppConfig.game.getNumberValue(GameConfigEnum.LOOT_HARVEST_ICONS_COUNT_MAX);
			var lootDelayMs:int = AppConfig.game.getNumberValue(GameConfigEnum.LOOT_DROP_DELAY_MS);
			
			var lootCountUse:int = (String(model.harvestValue).length - 1) * lootPerDigit;
			lootCountUse = (lootCountUse < lootCountMin) ? lootCountMin:lootCountUse;
			lootCountUse = (lootCountUse > lootCountMax) ? lootCountMax:lootCountUse;
			
			for (var i:int = 0; i < lootCountUse; i++)
			{
				TweenNano.delayedCall(i * lootDelayMs / 1000, spawnLoot,[i != 0]);
			}
		}
		
		private function spawnLoot(noText:Boolean):void
		{
			// There are two seperate kinds of money loots, one for building and one for pvp.  This tells the loot item it's building loot
			var lootType:String = model.building.output_type;
			if (lootType == Building.OUTPUT_TYPE_MONEY)
			{
				lootType = LootItem.BUILDING_COLLECT_TYPE_MONEY;
			}
			
			// TODO - ks - String itemkey_3 seems not to be used right now, will it be?
			var lootItem:LootItem = new LootItem('itemkey_3', lootType, this.model.harvestValue, 0, noText);
			var lootItemIcon:LootItemIcon = new LootItemIcon(lootItem, true);
			var point:Point = IsoBase(this).localPosition;
			point.x += (Math.random() - 0.5)*150;
			point.y += (Math.random() - 0.5)*150;
			lootItemIcon.setMapPosition(point);
			lootItemIcon.flyAnimation();
		}
		
		override protected function showHighlight(show:Boolean):void
		{	
			Mouse.cursor = MouseCursor.ARROW;
			
			if (show && isInteractive)
			{
				if (_assetDisplay)
				{
					_assetDisplay.filters = [IsoState.HOME_HIGHLIGHT_FILTER];
					
					Mouse.cursor = MouseCursor.BUTTON;
				}
				
				updateOverlayData();
				
				if (_flag)
					_flag.show();
				
				if (_model)
				{
					switch(model.state)
					{
						case PlayerBuilding.HARVESTABLE:
						case PlayerBuilding.PRODUCING:
						case PlayerBuilding.PRODUCING_STAT:
						case PlayerBuilding.PRODUCING_UNIT:
						case PlayerBuilding.PRODUCING_RESEARCH:	
							if (!_flag) 
								_overlay.show();
							break;
						
						case PlayerBuilding.BANK:
							if (!_flag) 
							{
								_overlay.show();
								updateProtectedMoney();
							}
							break;
						
						default:
							_overlay.hide();
					}
					
					if(isDefenseBuilding)
					{
						if(!_buildingGlowHelper) 
							_buildingGlowHelper = new IsoMouseBuildingHelper(this);
						_buildingGlowHelper.addGlows();
						// TODO TJ: does this change size with upgrade?
						drawDefenseFloor(IsoWorld.BUILDING_PADDING);
					}
				}

			}
			else
			{	
				if(!model || isDefenseBuilding)
				{
					if(_buildingGlowHelper)
					{
						_buildingGlowHelper.removeGlows();
						_buildingGlowHelper = null;
					}
					
					clearGraphics();
				}
				
				if (_assetDisplay)
					_assetDisplay.filters = [];
				
				if (_overlay)
					_overlay.hide();
				
				if (_flag)
					_flag.hide();
			}
		}
	
		public function set highlight(value:Boolean):void
		{
			if (value)
				TweenMax.to(_assetDisplay, 0.2, {glowFilter:{color:_highlightColor, alpha:1, blurX:2, blurY:2, strength:16, quality:BitmapFilterQuality.LOW}});
			else
				TweenMax.to(_assetDisplay, 0.2, {glowFilter:{color:_highlightColor, alpha:0, blurX:2, blurY:2, strength:16, quality:BitmapFilterQuality.LOW}, onComplete:removeFilters});
		}
		
		private function removeFilters():void
		{
			if (_assetDisplay)
				_assetDisplay.filters = [];
		}
		
		protected function onProgressSpeedUp(event:Event):void
		{
			if (IsoController.gi.isoWorld.isoMap.isMouseLive)
			{
				showSpeedupPopup();
			}		
		}
		
		protected function onProgressCancel(event:Event):void
		{
			if (IsoController.gi.isoWorld.isoMap.isMouseLive)
			{
				showCancelPopup();
			}	
		}
		
		
		
		//  POPUP FUNCTIONS
		// -----------------------------------------------------------------//
		
		private function showUnitsPopup():void
		{
			// tutorial injection
			new TutorialEvent(TutorialEvent.SELECT_BARRACKS).dispatch();
			
			UnitController.gi.createUnitPopup(this);
		}	
		
		private function showResearchPopop():void
		{
			PopupManager.instance.addPopup(new ResearchPopup(model), PopupProperties.TRANSPARENT_MODAL, PopupPriorities.SEQUENTIAL, PopupTransitionType.SLIDE_IN_LEFT_OUT_RIGHT);
		}	
		
		private function showSpecialBuildingFinishPopUp():void
		{
			PopupManager.instance.addPopup(new FinishBuildingPopup(model), PopupProperties.NORMAL_MODAL, PopupPriorities.SEQUENTIAL, PopupTransitionType.SLIDE_IN_LEFT_OUT_RIGHT);
		}
		
		private function showSpeedupPopup():void
		{
			
			var pop:SpeedupPopup;
			
			switch(model.state)
			{
				case PlayerBuilding.CONSTRUCTING:
					pop = new SpeedupPopup(model, model, SpeedupPopup.TYPE_CONSTRUCTION);
					break;
				
				case PlayerBuilding.UPGRADING:
					pop = new SpeedupPopup(model, model, SpeedupPopup.TYPE_UPGRADE);
					break;
			}
			
			// check if this is during tutorial
			if (TutorialController.getInstance().active)
				new TutorialEvent(TutorialEvent.SELECT_SPEEDUP_TIMEOUT).dispatch();
			
			PopupManager.instance.addPopup(pop, PopupProperties.TRANSPARENT_MODAL, PopupPriorities.IMMEDIATE, PopupTransitionType.NONE);
		}	
		
		private function showCancelPopup():void
		{
			var pop:CancelBuildingPopup;
			
			// FIXME: hard coded string
			switch(model.state)
			{
				case PlayerBuilding.CONSTRUCTING:
					pop = new CancelBuildingPopup(model, "Cancel Building?", onCancelBuild);
					break;
				
				case PlayerBuilding.UPGRADING:
					pop = new CancelBuildingPopup(model, "Cancel Upgrade?", onCancelUpgrade);
					break;
			}
		
			if(pop)
				PopupManager.instance.addPopup(pop, PopupProperties.TRANSPARENT_MODAL, PopupPriorities.IMMEDIATE, PopupTransitionType.NONE);
		}
		
		private function onCancelBuild():void
		{
			new CancelBuildingConstructionCommand(model).execute();
		}
		
		private function onCancelUpgrade():void
		{
			new CancelBuildingUpgradeCommand(model).execute();
		}
	
		
		//  CHANGE ASSET FUNCTIONS
		// -----------------------------------------------------------------//
	
		public function showCompletedBuildingGraphic():void
		{
			 
			_cacheKey = getCacheKey(_model.cacheKey);
			_assetURL = getBuildingURL(_cacheKey);
			
			loadStationaryAsset(onAssetFailed);
		
		}
		
		protected function showUnderConstructionGraphic():void
		{
			_cacheKey = getConstructionCacheKey();
			_assetURL = getBuildingURL(_cacheKey);
			
			loadStationaryAsset(onAssetFailed);
		}	
		
		protected function showDestroyedGraphic():void
		{
			_cacheKey = getDestroyedCacheKey();
			_assetURL = getBuildingURL(_cacheKey);
			
			loadStationaryAsset(onAssetFailed);
		}	
		
		override protected function onLoadBuildingComplete():void
		{
			updateOverlayPosition();
			
			// flag for tutorial
			if (model.building.output_type == Building.OUTPUT_TYPE_UNIT && TutorialController.getInstance().active)
				TutorialObjects.setObject(tutorialDisplayObject , TutorialObjects.SELECT_BARRACKS, true);
			
		}	
		
		public function get tutorialDisplayObject():DisplayObject
		{
			return _assetDisplay;
		}	

		//  SHOW HIDE STATUS FUNCTIONS
		// -----------------------------------------------------------------//
		private function showTooltipCollectEffect():void
		{
			// TODO Auto Generated method stub
		}
		
		private function showCollectEffect():void
		{
			hideFlagDisplay();
		}
		
		private function hideCollectIcon():void
		{
			hideFlagDisplay();
		}
		
		private function hideProductionResult():void
		{
			hideFlagDisplay();
		}
		
		private function addFlagListener():void
		{
			_flag.addEventListener(MouseEvent.CLICK, onFlagClick);
			_flag.addEventListener(MouseEvent.MOUSE_DOWN, onOverlayDown);
		}
		
		private function removeFlag():void
		{
			if (_flag)
			{
				_flag.removeEventListener(MouseEvent.CLICK, onFlagClick);
				_flag.removeEventListener(MouseEvent.MOUSE_DOWN, onOverlayDown);
				_flag.dispose();
				_flag = null;
			}
		}	
				
		
		
		private function showCollectStatus():void
		{
			hideOverlays();
			
			if (model.building.output_type == Building.OUTPUT_TYPE_MONEY)
				_flag = new BuildingFlagOverlay(BuildingFlagOverlay.MONEY, this);
			else if (model.building.output_type == Building.OUTPUT_TYPE_ENERGY)
				_flag = new BuildingFlagOverlay(BuildingFlagOverlay.ENERGY, this);
			
			addFlagListener();
			updateOverlayPosition();
			_flag.fadeIn();
		}

		private function onFlagClick(event:MouseEvent):void
		{
			if(IsoController.gi.isoWorld.isoMap.isMouseLive && !IsoController.gi.isoWorld.isWorldDragged)
			{
				mouseUp();			
			}
		}
		
		protected function onOverlayDown(event:MouseEvent):void
		{
			IsoController.gi.isoWorld.worldMouseDown(event);
		}
		
//		protected function onOverlayMove(event:MouseEvent):void
//		{	
//			if(IsoController.gi.isoWorld && event.buttonDown)
//			{
//				_isDragging = true;
//			}
//		}

		public function showWaitingToResearch():void
		{			
			if (GameObjectLookup.hasUncompletedTechs)
				showWaitingToStart();
			else
				showBuildingInfo();
		}
		
		private function showBuildingInfo():void
		{
			hideOverlays();
			
			_flag = new BuildingInfoOverlay(null, this);
			addFlagListener();
			updateOverlayPosition();
			_flag.fadeIn();
		}
	
		private function showWaitingToStart():void
		{
			hideOverlays();
			
			_flag = new BuildingFlagOverlay(BuildingFlagOverlay.INACTIVE, this);
			addFlagListener();
			updateOverlayPosition();
			_flag.fadeIn();
		}	
		
		protected function showWaitingToRepair(flagType:String):void
		{
			hideOverlays();
			
			_flag = new BuildingFlagOverlay(flagType, this);
			addFlagListener();
			updateOverlayPosition();
			_flag.fadeIn();
		}	
		
		private function enterWaitToFinishState():void
		{
			hideOverlays();
			
			_flag = new BuildingFlagOverlay(BuildingFlagOverlay.INACTIVE, this);
			addFlagListener();
			updateOverlayPosition();
			_flag.fadeIn();
	
		}

		private function hideFinishButton():void
		{
			hideFlagDisplay();	
		}
		
		private function showUpgradeTooltip():void
		{
			hideOverlays();
			createProgressOverlay(BuildingProgressOverlay.UPGRADING);
		}
		
		private function showConstructionProgressBar():void
		{
			hideOverlays();
			createProgressOverlay(BuildingProgressOverlay.BUILDING);
		}
		
		protected function showRepairingProgressBar():void
		{
			hideOverlays();
			if (_isReparingAll)
				createProgressOverlay(BuildingProgressOverlay.REPAIR_ALL);
			else
				createProgressOverlay(BuildingProgressOverlay.REPAIRING);
		}

		public function showServiceCall():void
		{
			//addMarker("Server Call " , 0x888888);
		}
		
		public function showError(err:String = "Error"):void
		{
			addMarker(err , 0xFF2222);
		}	
		
		public function hideProgressDisplay():void
		{
			removeProgress();
			removeFlag();
			clearUI();
		}	
		
		private function removeProgress():void
		{
			if (_progress)
			{
				_progress.removeEventListener(MouseEvent.MOUSE_DOWN, onOverlayDown);
				_progress.removeEventListener(BuildingProgressOverlay.SPEED_UP, onProgressSpeedUp);
				_progress.removeEventListener(BuildingProgressOverlay.CANCEL_BUILDING, onProgressCancel);
				_progress.dispose();
				_progress = null;
			}
		}	
		
		private function createProgressOverlay(type:String):void
		{
			_progress = new BuildingProgressOverlay(type);
			_progress.addEventListener(MouseEvent.MOUSE_DOWN, onOverlayDown);
			_progress.addEventListener(BuildingProgressOverlay.SPEED_UP, onProgressSpeedUp);
			_progress.addEventListener(BuildingProgressOverlay.CANCEL_BUILDING, onProgressCancel);
			updateOverlayPosition();
			_progress.fadeIn();
		}	
			
		public function hideFlagDisplay():void
		{			
			removeFlag();
			clearUI();
		}
		
		public function hideOverlayDisplay():void
		{
			if (_overlay) 
				_overlay.hide();
		}	
		
		public function hideOverlays():void
		{
			hideFlagDisplay();
			hideOverlayDisplay();
			hideProgressDisplay();
		}	

		
		//  UTIL FUNCTIONS
		// -----------------------------------------------------------------//
		private function addMarker(label:String, color:Number = 0xCCCCCC):void
		{
			var padding:Number = 17;
			var txt:TextField = new TextField();
			txt.autoSize = "left";
			
			txt.defaultTextFormat = new TextFormat(null, 17, 0xFFFFFF);
			txt.text = label;
			txt.x = padding;
			txt.y = padding;
			
			var holder:Sprite = new Sprite();
			
			var clip:Sprite = new Sprite();
			clip.graphics.beginFill(color,0.7);
			clip.graphics.drawRoundRect(0,0,txt.width + padding*2 ,txt.height + padding*2,10,10);
			clip.graphics.endFill();
			
			holder.addChild(clip);
			holder.addChild(txt);
			
			//holder.y = -_gridShift.y;
			holder.x = holder.width/2 * -1;
			
//			trace("BUILDING VIEW STATE :: ", label, holder);
			
			clearUI();
			addUI(holder);
		}	
		
		private function hoursToSec(num:Number):String
		{
			return int(num * 60 * 60) + " sec";
		}	

		
		public override function set direction(value:String):void
		{
			var newDirPos:int = "SESWNWNE".indexOf(value);
			
			// TODO VC:	what's with the empty conditionals? he who wrote this must finish it
			if (value == _model.direction)
			{
				
			}
			else if (newDirPos % 2 == 0)
			{
				_model.direction = value;
				var isConstructing:Boolean = 		(model.state == PlayerBuilding.CONSTRUCTING);
				var isDestroyed:Boolean = 			(model.state == PlayerBuilding.DESTROYED);
				var isWaitingToFinish:Boolean = 	(model.state == PlayerBuilding.WAITING_TO_START_CONSTRUCTION);
				var isRepairing:Boolean = 			(model.state == PlayerBuilding.REPAIRING);
				
				if (isConstructing || isDestroyed || isWaitingToFinish || isRepairing)
				{
					// No rotated assets for these states, don't reload assets			
				}
				else
				{
					loadAsset(onAssetLoaded, onAssetFailed);					
				}
			}
			else
			{
				// invalid new direction
			}
		}
		
		override public function drawPlacementFloor(validPlace:Boolean, remove:Boolean=false, inBorderSize:int=0, hideDefense:Boolean = false):void
		{
			super.drawPlacementFloor(validPlace, remove, inBorderSize, hideDefense);
			
			if (isDefenseBuilding && !remove && !hideDefense)
				drawDefenseFloor(inBorderSize);
		}
		
		
		protected override function placeHolderColor():int
		{
			if (model && model.state && model.state.length) 
			{
				if (model.state == PlayerBuilding.WAITING_TO_START_CONSTRUCTION) return 0xFFFF66;
				if (model.state == PlayerBuilding.CONSTRUCTING) return 0xFFAA66;
				if (model.state == PlayerBuilding.DESTROYED) return 0x555555;
				if (model.state == PlayerBuilding.REPAIRING) return 0xFF6666;
			}
			return 0xAAFFAA;
		}
		
		protected function drawDefenseFloor(inBorderSize:int):void
		{
			var defenseSize:int = model.generated_player_building_values.minus_attack_iso_width;
			if (defenseSize != model.generated_player_building_values.minus_attack_iso_length)
				Log.warn(this, "Expected minus attack iso width == minus attack iso length");
			
			var isoYOffset:int = ((isoWidth + isoLength)/2) * IsoBase.GRID_PIXEL_SIZE * 0.5;
			var g:Graphics = _graphicsDisplay.graphics;
			var colour:int = 0x0000FF;
			
			g.lineStyle(0, 0, 0);
			g.beginFill(colour, 0.3);
			g.moveTo(0,											   isoYOffset + defenseSize * -0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(defenseSize *  1.0 * IsoBase.GRID_PIXEL_SIZE, isoYOffset);
			g.lineTo(0,											   isoYOffset + defenseSize *  0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(defenseSize * -1.0 * IsoBase.GRID_PIXEL_SIZE, isoYOffset);
			g.lineTo(0,											   isoYOffset + defenseSize * -0.5 * IsoBase.GRID_PIXEL_SIZE);
			
			var size:int = isoSize + 2 * inBorderSize;
			
			g.moveTo(0,										isoYOffset + size * -0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(size * -1.0 * IsoBase.GRID_PIXEL_SIZE, isoYOffset);
			g.lineTo(0,										isoYOffset + size *  0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(size *  1.0 * IsoBase.GRID_PIXEL_SIZE, isoYOffset);
			g.lineTo(0,										isoYOffset + size * -0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.endFill();
			
			g.lineStyle(3, colour, 0.3);
			g.moveTo(0,											   isoYOffset + defenseSize * -0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(defenseSize *  1.0 * IsoBase.GRID_PIXEL_SIZE, isoYOffset);
			g.lineTo(0,											   isoYOffset + defenseSize *  0.5 * IsoBase.GRID_PIXEL_SIZE);
			g.lineTo(defenseSize * -1.0 * IsoBase.GRID_PIXEL_SIZE, isoYOffset);
			g.lineTo(0,											   isoYOffset + defenseSize * -0.5 * IsoBase.GRID_PIXEL_SIZE);
		}
		
		public function get isDefenseBuilding():Boolean
		{
			return model && model.generated_player_building_values.minus_attack > 0;
		}
		
		public function get defenseWidth():int
		{
			return model.generated_player_building_values.minus_attack_iso_width;
		}
		
		public function get defenseLength():int
		{
			return model.generated_player_building_values.minus_attack_iso_length;
		}
		
		//  HELPER FUNCTIONS
		// -----------------------------------------------------------------//
		override public function toString():String
		{
			var arr:Array = ["\t[- ISO PLAYER BUILDING -] ", model.building.name, model.id, "["+model.state+"]", "CONST: "+ model.constructionTimePeriod.timeLeft/1000, 
			"UPGR: "+ model.upgradeTimePeriod.timeLeft/1000, "sec ",
			"PROD: "+ model.productionTimePeriod.timeLeft/1000,  "sec ",
			"RES: "+ model.tech_research, "sec ",
			"REPAIR: "+ model.repairTimePeriod.timeLeft/1000, "sec ",
			"NEXT EVENT: "+ ((model.getNextTimeEvent() - new Date().time )/1000), "sec"];
			
			return arr.join();
		}	
		
	}
}
