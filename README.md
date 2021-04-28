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
    
**Toggling a single folder without affecting other folders.** Only use this for Bits, Dressed & Underwear
- /1 jasx.togglefolder Bits, 0<br />
Will detach all items in #RLV/JasX/Lynx/Bits without attaching anything else.

**Forcing an outfit info command:**
- /1 jasx.getoutfitinfo
    
You can use this from a prim as long as you are the owner of the prim:

``llRegionSayTo(llGetOwner(), 1, "jasx.setfolder Underwear");``
    


### Settings (SET):
    
**GET**
- /1 jasx.settings - Outputs settings on channel 2 (see below)

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
The HUD sends events on channel 2. They are in the form of "event:(obj)JSON"

**Outfit info:**
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
  "id":(int)jasx_id,
  "species":(int)species
}
</pre>

# Bridge shared vars
jx Bridge has a userdata object that other scripts in the linkset can read:
<pre>
userData()
OR 
db3$get("jx Bridge", ([BridgeShared$USER_DATA])) 
</pre>

This object consists of the following data:

| Key   | Type | Data  |
| --- |---| --- |
| id | int | JasX User ID |
| username | str | JasX Username |
| accountstatus | int | Will be 1 for all non admins |
| signupdate | str | Date the user signed up |
| avatar | str | JasX Avatar, located in http://jasx.org/media/avatars/ |
| fullname | str | Full username including title |
| bitflags | int | Settings. 2 = Credit terms accepted, 4 = hidden |
| last_lfp | int | Unix timestamp of last LFP refresh |
| sex | int | Standard sex bitwise. 1 = Penis, 2 = Vagina, 4 = Breasts |
| species | int | id of avatar type. 1 = human, 2 = amine, 3 = furry, 4 = other, 0 = undefined |
| lfp_for | array | List of game IDs you are looking to play. See the URLs at jasx.org game pages for the ID |
| games_owned | array | List of IDs of games owned |
| charname | str | SL character name |
| currenttitle | int | Current title ID number |
| flist | str | Active F-List.net character |
| outfit | str | Current JasX outfit name |
| spname | str | Avatar type name |
| credits | int | JXC |
| _new_inv | int | Nr unseen inventory items |
| _new_mail | int | New unseen messages |
| charkey | key | Character UUID |
| email | str | Email address |
| _link_req | obj | Info about an active link request |


## Settings folder

If you want to automatically change your species/gender settings when changing an outfit, you can put a folder underneath our outfit folder containing settings like `$SEX=<sex>` and/or `$SPEC=<species>`

Example: `#RLV/JasX/ThiccFox/$SEX=6$SPEC=3` - Sets sex to female (vag+breasts = 2+4 = 6) and species to furry (3) when activating that outfit. See above for genital flags and species.
