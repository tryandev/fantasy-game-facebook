package common.iso.control.ai
{
	import com.greensock.TweenNano;
	import com.raka.crimetown.business.command.battle.BattleController;
	
	import common.iso.control.IsoController;
	import common.iso.view.containers.IsoMap;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoCharacter;
	import common.iso.view.display.IsoUnit;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class MoverUnit extends MoverMonster
	{
		private var _destX:int;
		private var _destY:int;
		
		private var _unit:IsoUnit;
		private var _recentFrameLabel:String;
		private var _countDownToFire:int = 15;
		
		public var battleController:BattleController;
		
		public function MoverUnit(inClient:IsoUnit)
		{
			super(inClient);
			
			_unit = inClient;
			
			_constrainToBounds = false;
		}
		
		override public function start():void
		{
			_frozen = false;
			
			_moveDistance = 0;
			_moveDirection = Math.random() * 8;
			_moveIdle = _moveIdleMin + Math.random() * (_moveIdleMax - _moveIdleMin);
			_flagStopped = true;
			TweenNano.killTweensOf(this);
		}
		
		override public function idle():void
		{
			_client.changeSprite(_dX, _dY, IsoCharacter.ANI_ARRAY_IDLE, false);
			TweenNano.killTweensOf(this);
			TweenNano.to(this, _moveIdle, {onUpdate: updateFrameSkipByTime, onComplete:nextTile});
			state = STATE_ANI_IDLE;
		}
		
		override public function dispose():void
		{
			super.dispose();
			
			_unit = null;
			_recentFrameLabel = null;
			battleController = null;
			TweenNano.killTweensOf(this);
		}
		
		public function walkTo(destX:int, destY:int):void
		{
			_destX = destX;
			_destY = destY;
			
			_flagStopped = false;
			nextTile();
		}
		
		override protected function nextTile(coord:Array = null, shouldCollide:Boolean = false):void
		{
			var dir:Array = [0, 0];
			var dx:int = _destX - _client.isoX;
			var dy:int = _destY - _client.isoY;
			
			dir[0] = dx;
			dir[1] = dy;
			
			if (dx != 0) dir[0] = dx / Math.abs(dx);
			if (dy != 0) dir[1] = dy / Math.abs(dy);
			
			_moveDistance = Math.sqrt(dx*dx + dy*dy);
			
			if (_moveDistance > 0)
				super.nextTile(dir, false);
			else if (_unit && _unit.target && _unit.target.isoBase)
				attack(_unit.target.isoBase);
		}
		
		override protected function nextTileFinish():void
		{
			super.nextTileFinish();
			
			if (_moveDistance == 0 && _unit.target != null)
			{
				if (_unit.target.isAttackable) 
				{
					TweenNano.killTweensOf(this, true);
					attack(_unit.target.isoBase);
				}
				else
				{
					battleController.assignNewTarget(_unit);
				}
			}
		}
		
		override public function attack(target:IsoBase):void
		{
			if (target == null) return;
			
			TweenNano.killTweensOf(this, true);
			TweenNano.to(this, Math.random() * 10, {onComplete: super.attack, onCompleteParams:[target], useFrames: true});
		}
		
		override protected function attackComplete():void
		{
			super.attackComplete();
			
			battleController.reportCompletedAttackAnim(_unit);
		}
		
		override public function hitReact(attacker:IsoBase, isDeathBlow:Boolean = false, isDodged:Boolean = false):void
		{
			super.hitReact(attacker, false);
		}
		
		override protected function hitReactComplete():void
		{
			super.hitReactComplete();
			
			battleController.reportCompletedHitAnim(_unit);
		}
		
		override protected function updateFrameSkipByTime(inFrameSpeed:int=100, inSkipFrames:Boolean = true):void
		{
			super.updateFrameSkipByTime(inFrameSpeed);
			
			if (!_client) return;
			
			var _clientMC:MovieClip = _client.getMC();
			
			if (!_clientMC) return;
			
			if (_clientMC.name == 'placeholder' && _unit.isRanged) 
			{
				_countDownToFire--;
				if (_countDownToFire <= 0 ) {
					_countDownToFire = 30 + Math.random() * 15
					_unit.launchProjectile();
				}
				return;
			}
			
			var fLabelFull:String = _clientMC.currentLabel;
			
			if (_recentFrameLabel != fLabelFull)
			{
				_recentFrameLabel = fLabelFull;
				if (_recentFrameLabel != null)
				{
					if (_recentFrameLabel.indexOf('launch') > -1)
					{
						_unit.launchProjectile();
					}
				}
			}
			
		}
	}
}