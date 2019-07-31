package common.iso.control.ai
{
	import common.iso.view.display.IsoCharacter;
	
	import common.iso.view.display.IsoAvatar;
	import common.iso.view.display.IsoFPCAvatar;
	import common.iso.view.display.IsoMonster;

	public class MoverFactory
	{
		private static var __instance:MoverFactory;
		
		static public function getInstance():MoverFactory
		{
			if (__instance == null) {
				__instance = new MoverFactory(new SingletonBlocker());
			}
			return __instance;
		}
		
		public function MoverFactory(blocker:SingletonBlocker)
		{
			
		}
		
		public function createMoverFor(obj:IsoCharacter):MoverCharacter
		{
			// TODO - aray - should we keep track of these references so we handle the cleaning automatically? Or should we make sure all IsoCharacters dispose this like they used to.
			if(obj is IsoMonster) return new MoverMonster(obj);
			else if(obj is IsoFPCAvatar) return new MoverHomeAndFriendTownNPC(obj);
			else if(obj is IsoAvatar) return new MoverAvatar(obj);
			
			return new MoverCharacter(obj);
		}
	}
}

internal class SingletonBlocker { }