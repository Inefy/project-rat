extends RefCounted
## Demo starting builds use the same wave-clear and boss rewards as normal play.
const MIN_WAVE := 1
const MAX_WAVE := 100
const DEFAULT_WAVE := 20

static func starting_wave(value: int) -> int:
	return clampi(value, MIN_WAVE, MAX_WAVE)

static func rewards_for_wave(wave: int) -> int:
	return 2 if wave % 5 == 0 else 1

static func upgrade_budget(wave: int) -> int:
	var cleared := starting_wave(wave) - 1
	return cleared + floori(cleared / 5.0)

static func starting_treats(wave: int) -> int:
	return mini(3, floori((starting_wave(wave) - 1) / 5.0))
