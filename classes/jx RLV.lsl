#define RLVMethod$setClothes 2				// (str)layer - Sets fully clothed/underwear/bits layer
#define RLVMethod$dialog 3					// void - Dialog button clicked
#define RLVMethod$refreshStag 4				// void - Refreshes sTag tags

#define RLV$setClothes(layer) runMethod((string)LINK_ROOT, "jx RLV", RLVMethod$setClothes, [layer], TNN)
#define RLV$refreshStag() runMethod((string)LINK_ROOT, "jx RLV", RLVMethod$refreshStag, [], TNN)

#define RLVConst$GROUP_INDICATOR "+"

#define RLVShared$RLV_FOLDERS "a"


