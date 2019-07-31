package common.iso.control.mouse
{
	import com.raka.crimetown.business.command.enemy.AttackRivalCommand;
	import com.raka.crimetown.control.expansions.ExpansionController;
	import com.raka.crimetown.model.GameObjectManager;
	import com.raka.crimetown.model.game.CommerceProduct;
	import com.raka.crimetown.view.attack.AttackHintTooltip;
	import com.raka.crimetown.view.popup.PopupManager;
	import com.raka.crimetown.view.popup.outOfEnergy.OutOfEnergyOrStaminaPopup;
	
	import common.iso.view.containers.IsoMap;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoPlayerBuilding;
	import common.ui.view.tutorial.controller.TutorialController;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import ka.control.ControllerHud;
	
	public class IsoMouseModeRival extends IsoMouseModeGlowBase implements IIsoMouseMode
	{
		private var _map:IsoMap;
		private var _attackReticule:DisplayObject;
		private var _attackSize:int;
		
		private var _tileX:int;
		private var _tileY:int;
		private var _constrainedTileX:int;
		private var _constrainedTileY:int;
		private var _attackableBuildings:Array;
		
		public function IsoMouseModeRival(attackReticule:DisplayObject, attackSize:int)
		{
			_attackReticule = attackReticule;
			_attackSize = attackSize;
		}
		
		override public function pause():void
		{
			super.pause();
			
			_attackReticule.visible = false;
			AttackHintTooltip.instance.hide();
		}
		
		override public function resume():void
		{
			super.resume();
			
			_attackReticule.visible = true;
			AttackHintTooltip.instance.show();
		}
		
		public function init(map:IsoMap):void
		{
			_map = map;
			
			_map.addEventListener(Event.ENTER_FRAME, onMouseMove);
			_map.addEventListener(MouseEvent.CLICK, onMouseClick);
			
			_map.addTileOverlayItem(_attackReticule);
			
			_attackableBuildings = [];
			
			AttackHintTooltip.instance.show();
		}
		
		private function onMouseClick(event:MouseEvent):void
		{
			if (_paused) return;
			
			updateTileCoordinates();
			updateReticulePosition();
			
			if(TutorialController.getInstance().active && !isTutoriaBuildingInRange())
			{
				TutorialController.getInstance().badRivalAttack();	
			}
			else if (GameObjectManager.player.stamina <= 0)
			{
				PopupManager.instance.addPopup(new OutOfEnergyOrStaminaPopup(CommerceProduct.COMMERCE_TYPE_STAMINA, "ADD STAMINA"));
			}
			else
			{
				new AttackRivalCommand(GameObjectManager.areaOwner, _constrainedTileX, _constrainedTileY).execute();
			}
		}
		
		private function onMouseMove(event:Event):void
		{
			if (_paused) return;
			
			updateTileCoordinates();
			
			if (!(_tileX == _constrainedTileX && _tileY == _constrainedTileY))
			{
				updateReticulePosition();
				updateBuildingGlows();
			}
			
			AttackHintTooltip.instance.setOverlayPosition(_attackReticule, false);
		}
		
		private function updateTileCoordinates():void
		{
			_tileX = Math.round((_map.mouseY + 0.5 * _map.mouseX) / IsoBase.GRID_PIXEL_SIZE);
			_tileY = Math.round((_map.mouseY - 0.5 * _map.mouseX) / IsoBase.GRID_PIXEL_SIZE);
		}
		
		override protected function getBuildings():Array
		{
			return _map.getRivalBuildings();
		}
		
		override protected function isBuildingInRange(building:IsoPlayerBuilding):Boolean
		{
			var halfSize:int = _attackSize / 2;
			var bx:int = building.isoX + (building.isoWidth / 2.0);
			var by:int = building.isoY + (building.isoLength / 2.0);
			
			var left:int = _constrainedTileX - halfSize;
			var top:int  =_constrainedTileY - halfSize;
			
			return isBuildingWithinRect(building, left, top, _attackSize, _attackSize);
		}
		
		private function updateReticulePosition():void
		{
			var halfSize:int = _attackSize / 2;
			var reticuleRect:Rectangle = new Rectangle(_constrainedTileX - halfSize, _constrainedTileY - halfSize, _attackSize, _attackSize);
			
			ExpansionController.instance.constrainRectInsideExpandedArea(reticuleRect, _tileX - halfSize, _tileY - halfSize);
			
			_constrainedTileX = reticuleRect.x + halfSize;
			_constrainedTileY = reticuleRect.y + halfSize;
			
			_attackReticule.x = IsoBase.GRID_PIXEL_SIZE * (_constrainedTileX - _constrainedTileY);
			_attackReticule.y = IsoBase.GRID_PIXEL_SIZE * (_constrainedTileX + _constrainedTileY) / 2;
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			ControllerHud.gi.hud.helpText = "";
			
			AttackHintTooltip.instance.hide();
			
			_map.removeTileOverlayItem(_attackReticule);
			
			_attackReticule = null;
			
			_map.removeEventListener(Event.ENTER_FRAME, onMouseMove);
			_map.removeEventListener(MouseEvent.CLICK, onMouseClick);
			
			_map = null;
		}
	}
}