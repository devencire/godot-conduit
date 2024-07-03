class_name AttackEffect

func display_text() -> String:
    return 'Missing name'

func is_enabled() -> bool:
    return true

## Is passed the maximum power the attack can be overcharged by
## (or 0 if the attack was not overcharged).
## Returns the excess power that was used.
func enact() -> int:
    return 0
