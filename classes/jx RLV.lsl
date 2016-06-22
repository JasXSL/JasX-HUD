#define RLVMethod$recacheFolders 1			// void - Recaches folders hurdur
#define RLVMethod$setClothes 2				// (str)layer - Sets fully clothed/underwear/bits layer


#define RLV$recacheFolders() runMethod((string)LINK_ROOT, "jx RLV", RLVMethod$recacheFolders, [], TNN)
#define RLV$setClothes(layer) runMethod((string)LINK_ROOT, "jx RLV", RLVMethod$setClothes, [layer], TNN)


#define RLVShared$RLV_FOLDERS "a"


