package common.iso.view.display
{
	import com.raka.crimetown.model.game.IJob;
	
	import common.iso.control.IsoControllerFight;
	
	import flash.events.IEventDispatcher;
	
	/**
	 *	Implement this on any iso object that the avatar will be able to attack.
	 */	

	public interface IAttackableIso extends IEventDispatcher
	{
		function get isAlive():Boolean;
		function get energyPerAttack():Number;
		function get requirements():Array;
		function areRequirementsMet():Boolean;
		
		/**
		 *	Destroys the iso, this sould remove the object or
		 * 	put it in a non interactive state.
		 */	
		function kill():void;
		
		/**
		 *	Reset the iso to a brand new state. This should include
		 * 	filling the health back up, reset assets, and remove the 
		 * 	unique_id if needed (like monster). 
		 */	
		function reset():void;
		function spawn():void;
		function handleAttackResult(result:Object):void;
		
		function get respawnTime():Number;
		function set respawnTime(value:Number):void;
		
		function get queueCount():int;
		function set queueCount(value:int):void;
		
		function get resetTime():Number;
	}
}