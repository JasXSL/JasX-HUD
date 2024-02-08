#define OVERRIDE_TOKEN			// Override 
#define USE_DB4
#define getToken(senderKey, recipient, saltrand) "jasx$"
#include "./_tables.lsl"
#include "xobj_core/_ROOT.lsl"

#include "./classes/jx Bridge.lsl"
#include "./classes/jx RLV.lsl"
#include "./classes/jx API.lsl"

#include "./stag/stag.lsl"

#define jasxSlotState(slots, slot) ((slots>>(slot*2))&3)

#define STATE_BITS 0
#define STATE_UNDERWEAR 1
#define STATE_DRESSED 2

// Slots index
#define SLOT_HEAD 0
#define SLOT_ARMS 1
#define SLOT_TORSO 2
#define SLOT_GROIN 3
#define SLOT_BOOTS 4

#define PENIS 1
#define VAGINA 2
#define TITS 4

// Aliases
#define GENITALS_PENIS PENIS
#define GENITALS_VAGINA VAGINA
#define GENITALS_BREASTS TITS


#define GENITALS_ALL (PENIS|VAGINA|TITS)

#define HUDFLAG_PINGABLE 0x1		// Allows the getSettings and getOutfitInfo commands to be used by anyone

