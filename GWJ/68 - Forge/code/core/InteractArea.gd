extends Area2D
class_name InteractArea

## Called when player interacts with this interactable
signal _onInteractionEnter

## Called when player ends interaction with the interactable
signal _onInteractionExit

## An handler for handling continuos interaction beetween player and interactable
signal _onInteraction

@export
var toggle_only : bool

## Signals player entered interaction
func interact(): _onInteractionEnter.emit()


## Signals interaction termination
func exitInteraction(): _onInteractionExit.emit()
	
	
## Signals the interaction handler to be called
func handleInteraction(): _onInteraction.emit()
	
	
## Player entered interaction zone
func _on_interaction_zone_entered(_area):
	InteractionManager.registerInteraction(self)

## Player exited interaction zone
func _on_interaction_zone_exited(_area):
	InteractionManager.unregisterInteraction(self)
