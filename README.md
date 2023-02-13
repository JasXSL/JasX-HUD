# API Reference:

You can use the JasX wardrobe in your own projects, or just by chat command on channel 1.

The syntax is: jasx.setfolder [outfit]/[subfolder]

For example:
- /1 jasx.setclothes Dressed<br />
  will attach everything in #RLV/JasX/Lynx/Fully Clothed, and detach bits and underwear if your current outfit is lynx
- /1 jasx.setclothes Bits/Groin<br />
    will attach everything in #RLV/JasX/Lynx/Bits/Groin and detach Fully Clothed/groin and Underwear/Groin

**Changing outfit:**
- /1 jasx.setoutfit Lynx<br />
Will set your outfit to lynx, you can NOT have a comma in your outfit name

**Toggle Strapon:**
- /1 jasx.setstrapon 1<br />
Will attach your strapon
- /1 jasx.setstrapon 0<br />
Will detach your strapon

**Toggling onAttach:**
- /1 jasx.onattach BARE, 1<br />
Will attach all items in #RLV/JasX/onAttach/BARE
- /1 jasx.onattach BARE, 0<br />
Will detach all items in #RLV/JasX/onAttach/BARE
    
**WARNING: REMOVED in 0.6** **Toggling a single folder without affecting other folders.** Only use this for Bits, Dressed & Underwear
- /1 jasx.togglefolder Bits, 0<br />
Will detach all items in #RLV/JasX/Lynx/Bits without attaching anything else.

**Forcing an outfit info command:**
- /1 jasx.getoutfitinfo<br />
Will send the outfit info command (see below) on channel 2 to the prim that triggered the command.<br />
This can be used on other avatars so long as they have opted into public HUD visbility.

**Forcing a settings command:**
- /1 jasx.settings<br />
Will send the settings command (see below) on channel 2 to the prim that triggered the command.
This can be used on other avatars so long as they have opted into public HUD visbility.

**Set sex**
- /1 jasx.sex (int)sex - Sets your sex. Int is a bitwise value with the following constants
<pre>
#define SEX_PENIS 1
#define SEX_VAGINA 2
#define SEX_BREASTS 4
</pre>

**Set Species**
- /1 jasx.species (int)species - Sets what kind of avatar you have in the LFP system
<pre>
#define SPECIE_UNDEFINED 0
#define SPECIE_HUMAN 1
#define SPECIE_ANIME 2
#define SPECIE_FURRY 3
#define SPECIE_OTHER 4
</pre>    
    
    
    
## HUD SENT EVENTS (OUTPUTS)
The HUD sends events on channel 2 in an llRegionSayTo to the owner. They are in the form of "event:(obj)JSON"
Some events can be requested to other targets than the owner, but they must be requested by a command such as jasx.settings or jasx.getoutfitinfo.

**Outfit info:**
0.6
<pre>
outfits:{
    "root":(str)outfit,                            // Ex: Lynx
    "strapon":(bool)strapon_on,                    // Ex: 1
    "slots":(int)dressed_slots                     // 2-bit array, from right to left being head, arms, torso, crotch, boots. Ex: 0b00 00 00 01 10 = head dressed, arms underwear. You can use jasxSlotState(slots, slot) to get the current state. 0 = bits, 1 = underwear, 2 = nude
}
</pre>
0.5 and older
<pre>
outfits:{
    "root":(str)root_folder,                            // Ex: Lynx
    "strapon":(bool)strapon_on,                     // Ex: 1
    "dressed":(arr)dressed_slots,                 // Ex: [1,1,1,0,1]  (( All but groin is dressed ))
    "underwear":(arr)underwear_slots,           // == || == For underwear
    "bits":(arr)bits_slots                                 // == || == For Bits
}
</pre>

The slots are as follows:
<pre>
  #define SLOT_HEAD 0
  #define SLOT_ARMS 1
  #define SLOT_TORSO 2
  #define SLOT_GROIN 3
  #define SLOT_BOOTS 4
</pre>

**Game attached:**
<pre>
gameattached:{
  "game":(str)lowercase_game_name
}
</pre>

**Settings:**
<pre>
settings:{
  "sex":(int)sex,
  "id":(int)jasx_id (owner only),
  "species":(int)species,
  "lfp":(bool)lfp_enabled,
  "flist":(str)f_list_character,
  "rp":(int)rp_style, 
}
</pre>

# Bridge shared vars
jx Bridge creates a multitude of DB4 entries for userdata stored in linkset data:
<pre>
userData(BSUD$username)
</pre>
See jx RLV.lsl for a full list of values. Note: userData always returns a string.


## Settings folder

If you want to automatically change your species/gender settings when changing an outfit, you can put a folder underneath our outfit folder containing settings like `$SEX=<sex>` and/or `$SPEC=<species>`

Example: `#RLV/JasX/ThiccFox/$SEX=6$SPEC=3` - Sets sex to female (vag+breasts = 2+4 = 6) and species to furry (3) when activating that outfit. See above for genital flags and species.
