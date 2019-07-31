package common.iso.control.load {
	import com.raka.crimetown.model.game.Item;
	import com.raka.crimetown.model.game.Player;
	import com.raka.crimetown.model.game.PlayerItem;

	// TODO - aray - refactor -- pretty ugly
	public class FactoryKeyArmorBest 
	{
		public static function get(player:Player):Item 
		{
			//var armors:Array = GameObjectManager.player.armors.sortOn(["attack", "defense"], Array.NUMERIC | Array.DESCENDING);
			var armors:Array = player.armor;
			var armorBest:PlayerItem = null;
			var damageBest:Number = 0;
			
			for each (var armor:PlayerItem in armors) 
			{
				var playerClassId:int = player.character_class_id;
				var armorClassId:int = Item(armor.item).character_class_id;
				
				if (armor.quantity == 0 || (armorClassId != 0 && armorClassId != playerClassId))
					continue;
				
				var damageArmor:Number = armor.defense;//armor.attack + armor.defense; 
				var damageBonus:Number = 0; //(inTarget is IsoMonster) ? getDamageBonus(IsoMonster(inTarget), Item(currentArmor.item)):0;
				var damageClassMulti:Number = 0; //getDamageClass(currentArmor);
				
				// This is where the formula is calculated
				var damageTotal:Number = (damageArmor + damageBonus) * (1 + damageClassMulti);
				
				if (armorBest == null || damageTotal > damageBest) {
					damageBest = damageTotal;
					armorBest = armor;
					//trace('[FactoryKeyArmorBest]' + ' new best armor: ' + itemBest.name + " with damage = " + damageBest);
				}
				else if(damageTotal == damageBest) {
					
					var currentBestArmorTotal:Number = armorBest.defense + armorBest.attack;
					if((armor.defense + armor.attack) > currentBestArmorTotal) armorBest = armor;
				}
			}
			if (armorBest == null) {
				//throw new Error('itemBest armor is null');
				//trace('[FactoryKeyArmorBest]' + ' itemBest armor is null');
			}else{
				//trace('[FactoryKeyArmorBest]' + ' overall best armor is ' + itemBest.name + " with damage = " + damageBest);
			}
			return armorBest != null ? Item(armorBest.item) : null;			
		}
		
		private static function getDamageClass(inPlayerItem:PlayerItem):Number 
		{
			
			// DISABLED
			
			/*if (inPlayerItem.isArmor) {
				var item:Item = Item(inPlayerItem.item);
				var subtype:String = item.subtype;
				var characterClassId:int = GameObjectManager.player.character_class_id;
				var characterClassBuffs:Array = GameObjectLookup.getCharacterClassBuffs();
				for each (var pcb:CharacterClassBuff in characterClassBuffs) {
					if (pcb.character_class_id == characterClassId) {
						//trace('[FactoryKeyArmorBest]' + ' getDamageClass characterClassId('+characterClassId+') == pcb.character_class_id(' + pcb.character_class_id +')');
						if (subtype == pcb.item_subtype) {
							//trace('[FactoryKeyArmorBest]' + ' getDamageClass subtype('+subtype+') == pcb.item_subtype(' + pcb.item_subtype +')');
							//trace('[FactoryKeyArmorBest]' + ' getDamageClass returning ' + pcb.multiplicative);
							return pcb.multiplicative;
						}else{
							//trace('[FactoryKeyArmorBest]' + ' getDamageClass subtype('+subtype+') != pcb.item_subtype(' + pcb.item_subtype +')');
						}
					}else{
						//trace('[FactoryKeyArmorBest]' + ' getDamageClass characterClassId('+characterClassId+') != pcb.character_class_id(' + pcb.character_class_id +')');
					}
				}
				//trace('[FactoryKeyArmorBest]' + ' getDamageClass player has no match in characterClassBuffs');
			}else{
				throw new Error('[FactoryKeyArmorBest]' + ' getDamageClass inPlayerItem !isArmor');
			}*/
			return 0;
		}
	}
}