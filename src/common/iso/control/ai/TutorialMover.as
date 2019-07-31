package common.iso.control.ai
{
	import com.greensock.TweenNano;
	
	import common.iso.view.display.IsoCharacter;
	
	public class TutorialMover extends MoverMonster
	{
		public function TutorialMover(inClient:IsoCharacter)
		{
			super(inClient);
			
			_allowMovement = true;
		}
		
		public override function stop():void 
		{
			
			if (_client.isAlive) 
			{
				state = STATE_ANI_IDLE;
				_client.changeSprite(-1, 1, IsoCharacter.ANI_ARRAY_IDLE, false);
				TweenNano.killTweensOf(this);
				TweenNano.to(this, Infinity, {onUpdate: updateFrameSkipByTime, onUpdateParams: [1/30 * 1000]});
			}	
		}
		
		public override function start():void
		{
			
		}
	}
}