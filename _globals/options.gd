##options.gd
##Global Script Options
extends Node2D


#region Dialogue Options
## 0 : FULL = Speaking characters play their voice sound rapidly.[br]
## 1 : START = Speaking characters only play their voices at the beginning of text.[br]
## 2 : OFF = Speaking characters do not make sound.
@export_enum("FULL", "START", "OFF") var voices_type : int = 0
## 0 : TALKING = Speaking character portraits fully animate.[br]
## 1 : STILL = Speaking character portraits do not animate (but will show expression).
@export_enum("TALKING", "STILL") var portrait_type : int = 1
#endregion
