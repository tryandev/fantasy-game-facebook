package common.iso.control.load {
	import com.raka.commands.interfaces.ICommand;
	import com.raka.crimetown.model.GameObjectManager;
	import com.raka.crimetown.model.game.Item;
	import com.raka.crimetown.model.game.PlayerItem;
	import com.raka.iso.map.MapConfig;
	import com.raka.iso.utils.IDisposable;
	import com.raka.utils.logging.Log;
	
	import common.iso.control.cmd.IsoCommandLoadAsset;
	import common.iso.model.IsoModel;
	import common.iso.model.projectile.Projectile;
	import common.iso.view.display.IsoBase;
	import common.iso.view.display.IsoMonster;
	
	import flash.display.MovieClip;

	public class FactoryAniAttack implements IDisposable
	{
		private var _isAssetReadyAttack:Boolean;
		private var _isAssetReadyProjectile:Boolean;
		
		private var _bestWeapon:Item;
		private var _weaponProjectile:Projectile;
		
		private var _keyAttack:String;
		private var _keyProjectile:String
		
		private var _urlAssetAttack:String;
		private var _callback:Function;
		
		private var _commandLoadAttack:ICommand;
		
		private var _isFemale:Boolean;
		
		public function FactoryAniAttack(inTarget:IsoBase, inCallback:Function)
		{
			_bestWeapon = calcBestWeapon(inTarget);
			_keyAttack = calcAttackKey(_bestWeapon);
			_callback = inCallback;
			_isFemale = ('female' == GameObjectManager.player.playerOutfit.gender);
			_urlAssetAttack =	MapConfig.getInstance().url("new_avatar_assets_url").replace(MapConfig.PLACEHOLDER, (_isFemale ? 'Female_': '') + 'Avatar_' + _keyAttack);
			
			_keyProjectile = _bestWeapon.projectile_base_cache_key;
			if (_keyProjectile)
			{
				_weaponProjectile = IsoModel.gi.getProjectile(_keyProjectile);
				
				if (!_weaponProjectile)
				{
					throw new Error('_weaponProjectile: "' + _keyProjectile + '" not found in IsoModel, or not defined in XML');
				}
			}
		}
		
		public function dispose():void
		{
			_callback = null;
			_bestWeapon = null;
			
			if (_commandLoadAttack)
			{
				_commandLoadAttack.dispose();
				_commandLoadAttack = null;
			}
			if (_weaponProjectile)
			{
				_weaponProjectile.dispose();
				_weaponProjectile = null;
			}
		}
		
		public function getAttackRange():int
		{
			if (_weaponProjectile)
			{
				return _weaponProjectile.maxRange;
			}
			
			return 0;
		}
		
		public function initialize():void
		{
			if (_keyProjectile && _keyProjectile.length)
			{
				_weaponProjectile.loadAssets(onReadyAssetProjectile, onReadyAssetProjectile);
			}
			else
			{
				_isAssetReadyProjectile = true;
			}
			_commandLoadAttack = new IsoCommandLoadAsset(_urlAssetAttack, onReadyAssetAttack, onAssetLoadFail);
			_commandLoadAttack.execute();
		}
		
		private function onAssetLoadFail(data:Object):void
		{
			Log.error(this, "Failed to load attack ", _urlAssetAttack);	
			
			onReadyAssetAll();
		}
		
		public function get bestWeapon():Item
		{
			return _bestWeapon;
		}
		
		final private function calcAttackKey(bestWeapon:Item):String
		{
			var attackList:String = bestWeapon.attack_anim_list; //monster.model.enemy.attack_anim_list;
			var list:Array = attackList.split(',');
			var randomIndex:int = Math.round(Math.random() * (list.length - 1));
			var attackKey:String = list[randomIndex];
			//trace(this + ' randomIndex: ' + randomIndex);
			attackKey = attackKey.replace(' ', '');
			return attackKey;
		}
		
		final private function calcBestWeapon(inTarget:IsoBase):Item
		{
			//var weapons:Array = GameObjectManager.player.weapons.sortOn(["attack", "defense"], Array.NUMERIC | Array.DESCENDING);
			var weapons:Array = GameObjectManager.player.weapons;
			var itemBest:Item = null;
			var damageBest:Number = 0;
			
			for each (var currentWeapon:PlayerItem in weapons)
			{
				if (currentWeapon.quantity == 0)
					continue;

				var playerClassId:int = GameObjectManager.player.character_class_id;
				var weaponClassId:int = Item(currentWeapon.item).character_class_id;
				if (weaponClassId != 0 && weaponClassId != playerClassId)
					continue;
					
				var damageWeapon:Number = currentWeapon.attack; 
				var damageBonus:Number = (inTarget is IsoMonster) ? getDamageBonus(IsoMonster(inTarget), Item(currentWeapon.item)) : 0;
				var damageClassMulti:Number = 0;//getDamageClass(currentWeapon);
				
				// This is where the formula is calculated
				var damageTotal:Number = (damageWeapon + damageBonus) * (1 + damageClassMulti);
		
				if (itemBest == null || damageTotal > damageBest)
				{
					damageBest = damageTotal;
					itemBest = Item(currentWeapon.item);
//					trace(this + ' new best weapon: ' + itemBest.name + " with damage = " + damageBest);
				}
				else if(damageTotal == damageBest && currentWeapon.defense > itemBest.defense)
				{
					itemBest = Item(currentWeapon.item);
//					trace(this + ' new best weapon: ' + itemBest.name + " with defense = " + itemBest.defense);
				}
			}
			
			if (itemBest == null)
			{
				throw new Error('itemBest weapon is null');
			}
			
			//trace(this + ' overall best weapon is ' + itemBest.name + " with damage = " + damageBest);
			return itemBest;
		}
		
		private function getDamageClass(inPlayerItem:PlayerItem):Number
		{
			/*if (inPlayerItem.isWeapon)
			{
				var item:Item = Item(inPlayerItem.item);
				var charClass:String = item.character_class_id;
				var characterClassId:int = GameObjectManager.player.character_class_id;
				var characterClassBuffs:Array = GameObjectLookup.getCharacterClassBuffs();
				for each (var pcb:CharacterClassBuff in characterClassBuffs)
				{
					if (pcb.character_class_id == characterClassId)
					{
						if (charClass == pcb.item_subtype) {
							return pcb.multiplicative;
						}
					}
				}
			}
			else
			{
				throw new Error(this + ' getDamageClass inPlayerItem !isWeapon');
			}*/
			
			return 0;
		}
		
		private function getDamageBonus(inIsoMonster:IsoMonster, inItem:Item):Number
		{
			var damageBonus:Number;
			var monsterType:int = int(inIsoMonster.model.enemy.type);
			var bonusEnemyType:int = inItem.bonusEnemyType;
			
			if (monsterType == bonusEnemyType)
			{
				damageBonus = inItem.bonus; 
				//trace(this + " weapon type: " + inItem.bonusEnemyType + " is  monster type " + monsterType + " bonus = " + damageBonus);
				return damageBonus;
			}

			return 0;
		}
		
		private function onReadyAssetAttack(c:ICommand):void
		{
			_isAssetReadyAttack = true;
			checkAllAssetReady();
		}
		
		private function onReadyAssetProjectile(projectile:Projectile):void
		{
			_isAssetReadyProjectile = true;
			checkAllAssetReady();
		}
		
		private function checkAllAssetReady():void 
		{
			if (_isAssetReadyAttack && _isAssetReadyProjectile) 
			{
				onReadyAssetAll();
			}
		}
		
		private function onReadyAssetAll(c:ICommand = null):void
		{
			var classAttack:Class;
			var mcAttack:MovieClip;
			
			try{
				classAttack = IsoModel.gi.getCachedAsset((_isFemale ? 'Female_': '') + 'Avatar_' + _keyAttack + '_E', _urlAssetAttack);
				mcAttack = MovieClip(new classAttack());
			} catch(e:Error){
				Log.error(this, e.message);
			}	
			
			
			if (_callback != null) {
				_callback(mcAttack, _weaponProjectile);
			}
		}
	}
}