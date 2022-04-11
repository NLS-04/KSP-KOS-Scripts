clearScreen.

runOncePath("0:/Auriga/Auriga3_ChecklistCompiler.ks").

// local CHECKLIST_JSON_PATH is "Auriga/Auriga3_Checklist.json".
// local jsonContent is open( CHECKLIST_JSON_PATH ):readall():string().

// local listOfLines is jsonContent:split("
// ").
// local out is listOfLines[0].
// listOfLines:remove(0).

// for line in listOfLines {
//     set out to out +" "+ line:trim.
// }

// deletePath( "c.json" ).
// create( "c.json" ).
// open("c.json"):write( out ).