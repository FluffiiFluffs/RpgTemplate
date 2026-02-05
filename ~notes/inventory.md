Inventory Menu


appearance possibilities
	text menu w/ small icons (FF7+)
		can look boring for the player
		most compact design. can fit the most items on the screen.
		can be confusing since it's mostly just a wall of text if no description to the side (just a huge list)
	nested windows (DQ/Mother)
		can be exhausting to go through for the player (especially if animations are not very short)
	grid of icons with description to the side
		The issue with this is the possible need for unique icons for every item
		and the player put the cursor over the item to see what the item is
		can work with a smaller total amount of items in the game
	

Selection Feature
	First selection selects item
		a menu for that item pops up depending on what kind of item it is
			use: uses item effect
				will need an item effect for NOTHING as well just so the menu knows what to do
			move: move the item to another slot within the inventory
			destroy: removes item from current_inventory dictionary
	Can move item around and swap with other items (inventory slots)

Infinite Inventory 
	Inventory size must grow in accordance with the amount of items
		dictionary will need to have (items + n slots) if x amount of slots left?
			may be easiest way to do it, but needs to have a buffer so player can move items easier
	Should not have to worry about having too many items, annoying to fill up
		or maybe there should be a bool to toggle if it is infinite vs a set amount in Options global

Sorting
	Should have an option for sorting items within the inventory slots
		healing > status recovery > battle-only > weapons > head > chest > arms > legs > accessory
		sorted by item ID within respective categories
	Key items should be in a separate menu section
	Probably should not auto-sort on its own, but should have a sort button for the player to press
	
Backend
	All items of every type held within an array
	All items to be resources
		ID, name, max stack size, if unique, type, on-use effect, -1 on use flag, in-battle only toggle, can use in-battle toggle
		who can equip, stat bonuses when equipped


How Items Are Obtained
	Found
		Through exploration in the world
			conditions needed:
				if player needs to interact with interaction area a certain number of times
					variable updated via dialoguemanager (times_interacted, updated via interaction manager through dialoguemanager)
				if interaction_area will give an item
					if the player receives an item they should always see a text box
				if interaction area will not given an item (or there is no interaction area at all)
					if the player does not receive an item,
						text box can appear to notify the player there was nothing there
						nothing happens (but text for getting the item was intended)

	Given
		From NPC
			just given
			given for quest
	Battle
		Looted
	Shopping
		Purchased
		Traded
