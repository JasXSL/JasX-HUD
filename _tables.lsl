#ifndef __tables
#define __tables

#define table$root db4$0						// Table managed by #ROOT
	#define table$root$tooltipStage db4$0	// (int)stage - Current tooltip stage

#define table$ud db4$1							// Note. Index is string based with BSUD$* keys from jx Bridge

#define table$rlv db4$2							// jx RLV
	#define table$rlv$folders db4$0				// (arr)available_folders
	

#endif
