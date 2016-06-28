#API Reference:

You can use the JasX wardrobe in your own projects, or just by chat command on channel 1.

The syntax is: jasx.setfolder [outfit]/[subfolder]

For example: 
- /1 jasx.setclothes Dressed<br />
  will attach everything in #RLV/JasX/Lynx/Fully Clothed, and detach bits and underwear if your current outfit is lynx
- /1 jasx.setclothes Bits/Groin<br />
    will attach everything in #RLV/JasX/Lynx/Bits/Groin and detach Fully Clothed/groin and Underwear/Groin

Strapon example:
- /1 jasx.setstrapon 1<br />
Will attach your strapon
- /1 jasx.setstrapon 0<br />
Will detach your strapon

Changing your outfit folder:
- /1 jasx.setoutfit Lynx<br />
Will set your outfit to lynx, you can NOT have a comma in your outfit name

Toggling onAttach:
- /1 jasx.onattach BARE, 1<br />
Will attach all items in #RLV/JasX/onAttach/BARE
- /1 jasx.onattach BARE, 0<br />
Will detach all items in #RLV/JasX/onAttach/BARE
    
Toggling a single folder without affecting other folders. Only use this for Bits, Dressed & Underwear
- /1 jasx.togglefolder Bits, 0<br />
Will detach all items in #RLV/JasX/Lynx/Bits without attaching anything else.

Forcing an outfit info command:
- /1 jasx.getoutfitinfo
    
You can use this from a prim as long as you are the owner of the prim:

``llRegionSayTo(llGetOwner(), 1, "jasx.setfolder Underwear");``
    


###Settings:
    
*GET*
- /1 jasx.settings - Outputs settings on channel 2 (see below)

*Set sex*
- /1 jasx.sex (int)sex - Sets your sex. Int is a bitwise value with the following constants
<pre>
#define SEX_PENIS 1
#define SEX_VAGINA 2
#define SEX_BREASTS 4
</pre>
- /1 jasx.species (int)species - Sets what kind of avatar you have in the LFP system
<pre>
#define SPECIE_UNDEFINED 0
#define SPECIE_HUMAN 1
#define SPECIE_ANIME 2
#define SPECIE_FURRY 3
#define SPECIE_OTHER 4
</pre>    
    
##HUD SENT EVENTS
The HUD sends events on channel 2. They are in the form of "event:(obj)JSON"

*Outfit info:*
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

*Game attached:*
<pre>
gameattached:{
  "game":(str)lowercase_game_name
}
</pre>

*Settings:*
<pre>
settings:{
  "sex":(int)sex,
  "id":(int)jasx_id,
  "species":(int)species
}
</pre>
