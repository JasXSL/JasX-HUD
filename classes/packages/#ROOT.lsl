#define USE_EVENTS
#define SCRIPT_IS_ROOT
#include "jasx_hud/_core.lsl"

integer BFL;
#define BFL_BROWSER_OPEN 0x1

integer LFP_ON;
integer NUM_LFP = -1;

integer P_BUTTON;
integer P_BROWSER;
integer P_CONF;
integer P_LFP;
integer P_TOOLTIP;

integer CHAN_DIAG;				// Handles user dialogs
int TOOLTIP_STAGE;

vector BROWSER_POS = <0.516400, 0.064820, 0.633541>;

key TOUCH_HOLDER;
integer TOUCH_BUTTON;
integer TOUCH_SEC;



toggleBrowser( integer show ){

    vector pos = BROWSER_POS;
    if( !show ){
	
        // Store position on close if open
        if(BFL&BFL_BROWSER_OPEN)
            BROWSER_POS = l2v(llGetLinkPrimitiveParams(P_BROWSER, [PRIM_POS_LOCAL]), 0);
        pos = <0.516400,0.064820,-1>;
        BFL = BFL&~BFL_BROWSER_OPEN;
		
    }
    else
        BFL = BFL|BFL_BROWSER_OPEN;
    
    llSetLinkPrimitiveParamsFast(P_BROWSER, [PRIM_POSITION, pos]);
	
}

setLFP(){

	integer numPlayers = NUM_LFP;
	string text = (str)numPlayers;
	if( numPlayers == -1 )
		text = "??";
	while( llStringLength(text) < 2 )
		text = "0"+text;
	
	string index = "0123456789?";
	list out; integer i;
	for( ; i<2; ++i ){
	
		integer offset = llSubStringIndex(index, llGetSubString(text, i, i));
		out += (list)PRIM_TEXTURE + i + "be7f6cd7-9062-c395-6b71-8fee14bccc02" + <1./16, 1, 0> + <1./32-1./16*8+1./16*offset,0,0> + 0;
		
	}
	
	vector color = <0.667, 0.667, 0.667>;
	if( numPlayers == -1 )
		color = <.7,.5,.5>;
	else if( LFP_ON )
		color = <.5,.7,.5>;
	
	out += (list)PRIM_COLOR + 2 + color + 1;
	
	llSetLinkPrimitiveParamsFast(P_LFP, out);
	
}

#define MENU_DEFAULT 0
#define MENU_HELP 1
#define MENU_TOOLS 2

openDialog( integer menu ){

	string text; list buttons;

	if( menu == MENU_DEFAULT ){
		str vis = "⭕ private ⭕";
		if( (int)userData(BSUD$hud_flags) & HUDFLAG_PINGABLE )
			vis = "🔴 PUBLIC 🔴";
		list genitals;
		integer gf = (int)userData(BSUD$sex);
		string species = trim(userData(BSUD$species));
		if( species == "" )
			species = "<UNDEFINED>";
		if( gf & GENITALS_PENIS )
			genitals += "P";
		if( gf & GENITALS_VAGINA )
			genitals += "V";
		if( gf & GENITALS_BREASTS )
			genitals += "B";
		if( genitals == [] )
			genitals = (list)"<UNDEFINED>";
		
		text = "
Visibility: "+vis+"

[http:\/\/jasx.org/#hud/ 🌐 JasX.org] | [https:\/\/goo.gl/AkC1Ug 🐙 GitHub] | [secondlife:\/\/\/app\/group\/6ff2300b-8199-518b-c5be-5be5d864fe1f\/about 🖼️ SL Group]

⚧️ Genitals: "+llDumpList2String(genitals, ", ")+"
🦊 Species: "+species+"
";
		buttons = [
			"🔴 Visibility", "💳 Log In", "🔑 Reset Pass", "❓ Help", "🛠️ Tools"
		];

	}
	else if( menu == MENU_HELP ){
		text = "
Help Resources:
- [https:\/\/dangly.parts\/w\/1BJx5mB8w5UGetDrFmecVp 📽️  Outfit Video Tutorial]
- [https:\/\/drauslittlewebsite.com\/jasx-folders 👚  Outfit Text Tutorial]
- [https:\/\/github.com\/JasXSL\/JasX-HUD\/blob\/master\/README.md ⌨️ Chat Commands]
- [https:\/\/github.com\/JasXSL\/JasX-HUD\/issues 🐛  Bug Reports ]
- [https:\/\/jasx.org\/blog\/category\/jasx\/jasx-hud 📝  Patch Notes]
";
		buttons = (list)"⬅️ Back" + "ℹ️ HUD Tutorial";	
	}
	else if( menu == MENU_TOOLS ){
		text = "
-- Buttons
- 🔄 Tag Refresh: Refreshes sTag tags. This automatically happens twice per minute.
- 🖊️ Tag Builder: Helps you setup sTag tags for your avatar.
- 📋 List Tags: Outputs primary & secondary tags in chat.
- 🧺 Dressed/Underwear/Bits: Changes your outfit state.
";
		buttons = [
			"⬅️ Back", "🔄 Tag Refresh", "📋 List Tags", "🖊️ Tag Builder", "👔 Dressed", "🩲 Underwear", "🍑 Bits"
		];
	
	}
	
	
	
	
	/*
	"Tag Refresh"
		"Dressed", 
		"Underwear", 
		"Bits", 
		"Changelog"
	*/
	llDialog(llGetOwner(), text, buttons, CHAN_DIAG);
	
}

onEvt( string script, integer evt, list data ){

	if( script == "jx Bridge" ){
	
		if( evt == BridgeEvt$lfpPlayers ){
			
			NUM_LFP = l2i(data, 0);
			setLFP();
			
		}
		else if( evt == BridgeEvt$DATA_CHANGED ){
		
			LFP_ON = (int)userData(BSUD$last_lfp);
			setLFP();
			
		}
	}
	else if( script == cls$name ){
	
		if(evt == evt$TOUCH_HELD_SEC){
		
			integer prim = l2i(data, 0);
			if( llGetLinkName(prim) == "LFP" ){
			
				integer sec = l2i(data, 2);
				if(sec == 1){
					LFP_ON = !LFP_ON;
					Bridge$toggleLFP(LFP_ON);
					setLFP();
				}
				
			}
			
		}
		else if( evt == evt$TOUCH_END ){
		
			integer prim = l2i(data, 0);
			integer sec = l2i(data, 2);
			if( sec )
				return;
				
			if( llGetLinkName(prim) == "LFP" ){
			
				Bridge$setPage("lfp", []);
				toggleBrowser(TRUE);
				
			}
			
		}
		
	}
}
#define saveTooltipStage() db4$freplace(table$root, table$root$tooltipStage, TOOLTIP_STAGE)


string atcCache; // MD5 hash of tags
// Timer to handle double clicks and click hold
timerEvent( string id, string data ){

    if( id == "TOUCH" ){
		
		list d = [TOUCH_BUTTON, TOUCH_HOLDER, ++TOUCH_SEC];
		raiseEvent(evt$TOUCH_HELD_SEC, mkarr(d));
		multiTimer(["TOUCH", 0, 1, FALSE]);
		if( TOUCH_BUTTON == P_TOOLTIP && TOUCH_SEC > 1 ){
		
			TOOLTIP_STAGE = 0xFFFFFF;
			saveTooltipStage();
			advanceTooltip();
			
		}
		
	}
	else if( id == "TAGS" ){
		
		string atc; // Start by doing a quick scan of attachments
		
		
		
	}
	
}


advanceTooltip(){
	
	llSetLinkPrimitiveParams(P_TOOLTIP, [PRIM_POSITION, ZERO_VECTOR, PRIM_TEXT, "", <1,1,1>, 1]);

	list stages = [
		<0.470261, 0.059536, 0.204437>, "Thanks for using the JasX HUD.\nClick this triangle to continue.\nClick and hold the triangle to skip tutorial.",
		<0.470261, 0.059536, 0.204437>, "The main button toggles the\nJasX Browser.",
		<0.470261, 0.059536, 0.204437>, "Use it to change\nsettings and outfits.",
		<0.470261, 0.123600, 0.204437>, "Click this cog for help and\nin-SL commands.",
		<0.470261, -0.008211, 0.204437>, "Players looking for group are shown here.\nClick to see all players.\nClick and hold to toggle LFG."
	];
	if( TOOLTIP_STAGE > count(stages)/2 )
		return;
		
	llSetLinkPrimitiveParams(P_TOOLTIP, [PRIM_POSITION, l2v(stages, TOOLTIP_STAGE*2), PRIM_TEXT, l2s(stages, TOOLTIP_STAGE*2+1), <.5,.75,1>, 1]);
	saveTooltipStage();
	++TOOLTIP_STAGE;
	
}

output( string label, list data ){
	
	string text = llToUpper(label) + ": " + l2s(data, 0);
	if( count(data) > 1 )
		text += "[" + llList2CSV(data) + "]";
	llOwnerSay(text);
	
}

default{
    
    // Restart on change
    changed( integer change ){
	
        if( change&CHANGED_OWNER ){
		
            llDialog(
				llGetOwner(), 
				"Since the JasX HUD is open source, please take a moment to verify that you received this HUD from secondlife:///app/agent/cf2625ff-b1e9-4478-8e6b-b954abde056b/about : Do not accept HUDs from people you don't trust.", 
				[], 
				3267
			);
            TOOLTIP_STAGE = 0;
			llLinksetDataReset();
			saveTooltipStage();
			llResetScript();
			
        }
		
    }
    
	timer(){multiTimer([]);}
	
    state_entry(){
	
        links_each(nr, name,
		
            if( name == "BUTTON" )
                P_BUTTON = nr;
            else if( name == "BROWSER" )
                P_BROWSER = nr;
			else if( name == "CONF" )
				P_CONF = nr;
			else if( name == "LFP" )
				P_LFP = nr;
			else if( name == "TOOLTIP" )
				P_TOOLTIP = nr;
				
        )
                
        // Hide
        toggleBrowser(FALSE);
        setLFP();
				
        llSetLinkMedia(P_BROWSER, 1, [
            PRIM_MEDIA_AUTO_PLAY, TRUE,
            PRIM_MEDIA_CONTROLS, PRIM_MEDIA_CONTROLS_MINI,
            PRIM_MEDIA_FIRST_CLICK_INTERACT, TRUE,
            PRIM_MEDIA_HEIGHT_PIXELS, 1024,
            PRIM_MEDIA_WIDTH_PIXELS, 1024,
            PRIM_MEDIA_CURRENT_URL, "http://jasx.org",
            PRIM_MEDIA_HOME_URL, "http://jasx.org",
            PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_OWNER,
            PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_OWNER
        ]);
		
		resetAllOthers();
		TOOLTIP_STAGE = (int)db4$fget(table$root, table$root$tooltipStage);
		advanceTooltip();
		
		CHAN_DIAG = llCeil(llFrand(0xFFFFFFF));
		llListen(CHAN_DIAG, "", llGetOwner(), "");
		
		memLim(1.5);
				
    }
	
	listen( int chan, string name, key id, string message ){
		
		if( chan == CHAN_DIAG ){
			
			
			// Main
			if( message == "💳 Log In" )
				Bridge$login();
				
			else if( message == "🔑 Reset Pass" ){
				
				llOwnerSay("Generating a new password");
				Bridge$resetPass();
				
			}
			else if( message == "❓ Help" )
				openDialog(MENU_HELP);
			else if( message == "🛠️ Tools" )
				openDialog(MENU_TOOLS);
			else if( message == "🔴 Visibility" ){
				
				int hudFlags = (int)userData(BSUD$hud_flags);
				if( hudFlags & HUDFLAG_PINGABLE )
					hudFlags = hudFlags &~HUDFLAG_PINGABLE;
				else
					hudFlags = hudFlags | HUDFLAG_PINGABLE;
				Bridge$setHudFlags(hudFlags);
				
			}
			
			
			// Tools
			else if( ~llListFindList(["👔 Dressed", "🩲 Underwear", "🍑 Bits"], [message]) ){
				RLV$setClothes(llGetSubString(message, 2, -1));
				openDialog(MENU_TOOLS);
			}
			else if( message == "🔄 Tag Refresh" ){
				llOwnerSay("Refreshing sTag tags");
				RLV$refreshStag();
			}
			else if( message == "🖊️ Tag Builder" ){
				llLoadURL(llGetOwner(), "Site tool for helping setup sTag tags on your avatars.", "https://jasxsl.github.io/sTag/");
			}
			else if( message == "📋 List Tags" ){
				llOwnerSay(":: DETECTED TAGS ::");
				key t = llGetOwner();
				output("Species", (list)sTag$species(t));
				output("Species Group", (list)sTag$subspecies(t));
				output("Sex", (list)sTag$sex(t));
				output("Outfit JSON", (list)sTag$outfit2json(t));
				
				
				output("Pronouns", (list)sTag$pronouns(t));
				output("Tail Size (0-5)", (list)sTag$sizeToInt(sTag$tail(t)));
				output("Hair Size (0-5)", (list)sTag$sizeToInt(sTag$hair(t)));
				output("Body Coating", sTag$body_coat(t));
				output("Body Type", (list)sTag$body_type(t));
				output("Body Fat", (list)sTag$body_fat(t));
				output("Body Muscle", (list)sTag$body_muscle(t));
				
				
				llOwnerSay(":: DETECTED GENITAL SIZE ::");
				integer bits = sTag$getBitsPacked(t);
				output("-- Penis (0-5)", (list)sTag$penisSize(bits));
				output("-- Vagina (0-5)", (list)sTag$vagina(bits));
				output("-- Breasts (0-5)", (list)sTag$breastsSize(bits));
				output("-- Rear (0-5)", (list)sTag$rearSize(bits));
				output("-- Testicles (0-5)", (list)sTag$testiclesSize(bits));
				
				
			
			
				openDialog(MENU_TOOLS);
			}
			
			// Help
			else if( message == "ℹ️ HUD Tutorial" ){
				TOOLTIP_STAGE = 0;
				saveTooltipStage();
				advanceTooltip();
			}
			
			
			// Help/Tools
			else if( message == "⬅️ Back" ){
				openDialog(MENU_DEFAULT);
			}

		}
	
	}
    
    touch_start( integer total ){
        detOwnerCheck
        
        integer ln = llDetectedLinkNumber(0);
        integer face = llDetectedTouchFace(0);
        
        if( ln == P_BUTTON )
            toggleBrowser(~BFL&BFL_BROWSER_OPEN);
        
        if( ln == P_BROWSER && (
            face == 3 || face == 2
        ))
            toggleBrowser(FALSE);
        
		if( ln == P_CONF )
			openDialog(MENU_DEFAULT);
			
		raiseEvent(evt$TOUCH_START, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0)]));
		
		TOUCH_HOLDER = llDetectedKey(0);
		TOUCH_BUTTON = llDetectedLinkNumber(0);
		TOUCH_SEC = 0;
		
		multiTimer(["TOUCH", 0, 1, TRUE]);
		
    }
	
	touch_end( integer total ){ 
        detOwnerCheck
		
		multiTimer(["TOUCH"]);
		
        raiseEvent(evt$TOUCH_END, llList2Json(JSON_ARRAY, [llDetectedLinkNumber(0), llDetectedKey(0), TOUCH_SEC]));
		
		if( TOUCH_BUTTON == P_TOOLTIP )
			advanceTooltip();
		
    }
	
    // This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}
