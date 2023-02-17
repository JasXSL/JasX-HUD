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

vector BROWSER_POS = <0.516400, 0.064820, 0.633541>;

key TOUCH_HOLDER;
integer TOUCH_BUTTON;
integer TOUCH_SEC;

int TOOLTIP_STAGE;

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

openDialog(){

	str vis = "PRIVATE";
	if( (int)userData(BSUD$hud_flags) & HUDFLAG_PINGABLE )
		vis = "PUBLIC";
		
	string text = "
["+vis+"]

-- LINKS --
	[http:\/\/jasx.org/#hud/ JasX.org]
	[https:\/\/goo.gl/AkC1Ug API/Bugs]
	[https:\/\/bit.ly/3YCncGD Video Tutorial]
	[https:\/\/bit.ly/3aeYAdU Outfit Help]

-- COMMANDS --
Ch 0 or /1:
	jasx.setoutfit <name> - Set outfit
	jasx.setclothes dressed/underwear/bits - Outfit state

-- Buttons --
	Log In - Browser Login
	Dressed/Underwear/Bits - Set clothing
	Visibility - Anyone can see your HUD
";
	
	list buttons = ["Dressed", "Underwear", "Bits", "Visibility", "Log In", "Pass Reset", "Changelog", "Tutorial"];
	
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
			
			
			if( message == "Log In" )
				Bridge$login();
				
			else if( message == "Pass Reset" ){
				
				llOwnerSay("Generating a new password");
				Bridge$resetPass();
				
			}
			else if( message == "Changelog" )
				llGiveInventory(llGetOwner(), "Changelog");
			else if( ~llListFindList(["Dressed","Underwear","Bits"], [message]) )
				RLV$setClothes(message);
				
			else if( message == "Visibility" ){
				
				int hudFlags = (int)userData(BSUD$hud_flags);
				if( hudFlags & HUDFLAG_PINGABLE )
					hudFlags = hudFlags &~HUDFLAG_PINGABLE;
				else
					hudFlags = hudFlags | HUDFLAG_PINGABLE;
				Bridge$setHudFlags(hudFlags);
				
			}
			else if( message == "Tutorial" ){
				TOOLTIP_STAGE = 0;
				saveTooltipStage();
				advanceTooltip();
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
			openDialog();
			
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
