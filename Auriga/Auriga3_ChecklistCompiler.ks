// ※ ‣ ↳ ╳ ┇┇┋ ┎┖┠ ░▒▓ □ ▣ ▶ ☐☑☒ ✓✔ ✱ ⟦⟧ [] 
// □▣▫▪◻◼◽◾
// ⁜ • ∙ ⊗ ⊠ █
// ▆ ⬤◯○●⚫ ❖ ✖✕𐌢 ⚠

//              |<------------- 34 ------------->| for name of Checklist
// │―――――――――――――――――――――――――――――――――――――――――――――――――――│
// │ CHECKLIST: PLANNING RENDEZVOUS                1/1 │ // max pages 9
// │ ⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃⁃ │
// │ [●] SAS ...................................... ON │ // AUTO ACTION
// │ [●] RCS ...................................... ON │ // AUTO ACTION
// │ [●] TARGET ........................ CONFIRM & SET │ // MANUAL CONFIRM
// │ ┎ [ ] IF ( TARGET ORBITS OTHER BODY )             │ // MAUNAL DECISION 
// │ ┋ [ ] RUNMODE ......................... SET TO 31 │ // AUTO CONFIRM
// │ ┖                  █  █  █  █                     │
// │ [ ] RUNMODE ........................... SET TO 15 │
// │ ┎ [●] IF ( DELTA-V IS NOT SUFFICIENT )            │ // CONFIRM THIS 
// │ ┋ >○< RUNMODE ......................... SET TO 11 │
// │ ┖                  █  █  █  █                     │
// │ [ ] DELTA-V MAIN                                  |
// |     RESSOURCE ............ CONFIRM SUFFICIENT QTY |
// │                    █  █  █  █                     │
// │―――――――――――――――――――――――――――――――――――――――――――――――――――│
// │                                                   │
// │                                                   │
// │                                                   │
// │                                                   │
// │                                                   │
// │                                                   │
// │ |<--------------------- 49 -------------------->| │ // printable area
// │ [ ] |<------------------- 45 ------------------>| │ // item area
// │ ┋ [ ] |<------------------ 43 ----------------->| │ // AUTO CONFIRM


// CHECKLIST ITEM MODES
// | MODE NAME       | JSON TYPE NUMBER | REQUIRES MANUAL ACTION | ABRIVIATION |
// | AUTO CONFIRM    | 0                | YES                    | AC          |
// | AUTO ACTION     | 1                | NO                     | AA          |
// | MANUAL CONFIRM  | 2                | NO                     | MC          |
// | MANUAL DECISION | 3                | YES (req. user input)  | MD          |


// USER INPUT INTERFACES FOR CONFIRMATION
// ...
// │―――――――――――――――――――――――――――――――――――――――――――――――――――│
// │ ░░░░░░░░░ YES ░░░░░░░░░ |           NO            │
// └ ================================================= ┘
// ...
// │―――――――――――――――――――――――――――――――――――――――――――――――――――│
// │           YES           | ░░░░░░░░░ NO ░░░░░░░░░░ │
// └ ================================================= ┘
// ...
// │―――――――――――――――――――――――――――――――――――――――――――――――――――│
// │ ░░░░░░░░░░░░░░░░░░░░ CONFIRM ░░░░░░░░░░░░░░░░░░░░ │
// └ ================================================= ┘


// END OF CHECKLIST 
// │                    █  █  █  █                     │

// IF SNIPPET
// │ ┎ [ ] IF ( |<-------------- 36 -------------->| ) │  
// │ ┋ [ ] ABCDEFG ........................... ABCDEFG │
// │ ┋ ┎ [ ] IF ( |<------------- 34 ------------->| ) │  
// │ ┋ ┖ [ ] ABCDEFG ......................... ABCDEFG │
// │ ┖ [ ] ABCDEFG ........................... ABCDEFG │
// >>> OR WITH END OF CHECKLIST
// │ ┖                  █  █  █  █                     │


// local example_checklist_format is list(
//     lex( 
//         "name", "PLANNING RENDEZVOUS", 
//         "runmode", 15,
//         "pages", 2,
//         "linesPerPage", 12,
//         "items", list( // this list holds the specified pages
//             list( // this list holds the items for the first page
//                 lex( "type", 1, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] SAS ...................................... ON") ),
//                 lex( "type", 1, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] RCS ...................................... ON") ),
//                 lex( "type", 2, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] TARGET ........................ CONFIRM & SET") ),
//                 lex( "type", 3, "checkCoordinate", 5, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("┎ [ ] IF ( TARGET ORBITS OTHER BODY )            ") ),
//                 lex( "type", 0, "checkCoordinate", 5, "logicDepth", 1, "isEndOfChecklist", false, "lines", list("┋ [ ] RUNMODE ......................... SET TO 31") ),
//                 lex( "type", 0, "checkCoordinate", 0, "logicDepth", 1, "isEndOfChecklist", true,  "lines", list("┖                  █  █  █  █                    ") ),
//                 lex( "type", 0, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] RUNMODE ........................... SET TO 15") ),
//                 lex( "type", 3, "checkCoordinate", 5, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("┎ [ ] IF ( DELTA-V IS NOT SUFFICIENT )           ") ),
//                 lex( "type", 0, "checkCoordinate", 5, "logicDepth", 1, "isEndOfChecklist", false, "lines", list("┋ [ ] RUNMODE ......................... SET TO 11") ),
//                 lex( "type", 0, "checkCoordinate", 0, "logicDepth", 1, "isEndOfChecklist", true,  "lines", list("┖                  █  █  █  █                    ") ),
//                 lex( "type", 2, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] DELTA-V MAIN                                 ", "    RESSOURCE ............ CONFIRM SUFFICIENT QTY") )
//             ),
//             list( // this list holds the items for the first page
//                 lex( "type", 3, "checkCoordinate", 5, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("┎ [ ] IF ( TARGET ORBITS OTHER BODY )            ") ),
//                 lex( "type", 0, "checkCoordinate", 5, "logicDepth", 1, "isEndOfChecklist", false, "lines", list("┋ [ ] RUNMODE ......................... SET TO 31") ),
//                 lex( "type", 0, "checkCoordinate", 0, "logicDepth", 1, "isEndOfChecklist", true,  "lines", list("┖                  █  █  █  █                    ") ),
//                 lex( "type", 1, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] SAS ...................................... ON") ),
//                 lex( "type", 1, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] RCS ...................................... ON") ),
//                 lex( "type", 2, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] DELTA-V MAIN                                 ", "    RESSOURCE ............ CONFIRM SUFFICIENT QTY") ),
//                 lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true,  "lines", list("                   █  █  █  █                    ") ),
//                 lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true,  "lines", list("                       .                         ") ),
//                 lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true,  "lines", list("                       .                         ") ),
//                 lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true,  "lines", list("                       .                         ") ),
//                 lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true,  "lines", list("                       .                         ") )
//             )
//         ) 
//     )
// ).

// writeJson( example_checklist_format, "0:/Auriga/Auriga3_Checklist.json" ).
// log readJson("0:/Auriga/Auriga3_Checklist.json"):dump to "0:/Auriga/_.txt".


  ///////////////
 // CONSTANTS //
///////////////
local PARENT_PATH is "0:/Auriga".
local CHECKLIST_TEXT_PATH  is PARENT_PATH+"/Auriga3_Checklist.txt".
local CHECKLIST_JSON_PATH  is PARENT_PATH+"/Auriga3_Checklist.json".
local CHECKLIST_DEBUG_PATH is PARENT_PATH+"/Auriga3_Checklist_debug.txt".

local STRING_IF_BEGIN is "┎".
local STRING_IF_RAIL  is "┋".
local STRING_IF_END   is "┖".
local STRING_END_OF_CHECKLIST is "                   █  █  █  █                    ".

local MAX_LINES_PER_PAGE is 12.
local MIN_DOTS_PER_ITEM is 3.
local SPLIT_RATIO is 0.5.

local STRING_EMPTY is "                                                 ". // length: 49
local STRING_DOTS  is ".................................................". // length: 49
local STRING_NOOP  is "                        .                        ". // length: 49

///////////////////////////////////////////////////////////////////////////////////////////////

  //////////
 // CODE //
//////////
local function convertType {
    parameter type.
    if type:matchespattern("AC") return 0.
    if type:matchespattern("AA") return 1.
    if type:matchespattern("MC") return 2.
    if type:matchespattern("MD") return 3.
}
local function calcCheckCoord {
    parameter depth.
    return 3 + depth*2.
}
local function depthOffset {
    parameter depth.
    return depth*2.
}
local function resizeTo {
    parameter str, len.
    return (str + STRING_EMPTY):substring( 0, len ).
}
local function overlay {
    parameter originStr, overlayStr, atIndex.
    return originStr:remove( atIndex, overlayStr:length ):insert( atIndex, overlayStr ).
}

local function wordwrapping {
    parameter sentence, spaceAvail.
    local wordList is sentence:split(" ").
    local outList is list("").

    for word in wordList {
        // the two combined words are small enought to fit into the space
        if ( outList[ outList:length-1 ] + " " + word ):length <= spaceAvail {
            set outList[ outList:length-1 ] to (outList[ outList:length-1 ] + " " + word):trim.
        } else if word:length > spaceAvail { // this single word does not fit onto ONE line => spliting it up into two parts (w/o regarding semantics)
            outList:add( word:substring( 0, floor(word:length/2) ) ).
            outList:add( word:substring( floor(word:length/2), word:length-floor(word:length/2) ) ).
        } else {
            outList:add( word ).
        }
    }

    return outList.
}

local function createIfRails {
    parameter _depth.
    local str is "".
    from {} until _depth = 0 step { set _depth to _depth - 1. } do 
        set str to str + STRING_IF_RAIL + " ".
    return str.
}
local function createLines {
    parameter object, action, depth.

    // spaces:
    // 49 - total length available
    // 4  - length required for the marker
    // 2  - accounts for the two spaces required between the words and the dots
    local spaceLeft is 49 - 4 - 2 - MIN_DOTS_PER_ITEM - depthOffset( depth ).
    local splitIndex is floor( SPLIT_RATIO * spaceLeft ).
    
    local outList is list().

    local objList is wordwrapping( object, splitIndex ).
    local actList is wordwrapping( action, spaceLeft - splitIndex ).

    outlist:add( resizeTo( createIfRails( depth ) + "[ ] " + objList[0] + STRING_EMPTY, 49 ) ).
    objList:remove(0).

    if objList <> 0
        for objLine in objList {
            outList:add( resizeTo( createIfRails( depth ) + "    " + objLine + STRING_EMPTY , 49 ) ).
        }

    local dots is 49 - ( outList[ outList:length - 1 ]:trimend:length + actList[0]:trimend:length + 2 ).
    set outList[ outList:length - 1 ] to outList[ outList:length - 1 ]:trimend + " " + STRING_DOTS:subString( 0, dots ) + " " + actList[0]:trimend.

    actList:remove(0).
    if actList <> 0
        for actLine in actList {
            outList:add( overlay( actLine:padLeft(49), createIfRails( depth ), 0 ) ).
        }

    return outList.
}
local function createIfLine {
    parameter str, depth.
    local outStr is createIfRails( depth ) + STRING_IF_BEGIN + " [ ] if ( " + resizeTo( str, 38 - depthOffset(depth+1) ):trim + " ) ".
    return list( resizeTo( outStr, 49 ) ). // essentially pading right with whitespaces
}
local function createEndOfChecklistLine {
    parameter depth.
    return list( overlay( STRING_END_OF_CHECKLIST, createIfRails(depth), 0 ) ).
}
local function createPlaceHolder {
    return lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true, "lines", list( STRING_NOOP ) ).
}

local accumulator is list().

deletePath( CHECKLIST_DEBUG_PATH ).
create( CHECKLIST_DEBUG_PATH ).

local content is open( CHECKLIST_TEXT_PATH ):readall():string().

local checklists is content:trim:split("#").
checklists:remove(0). // first entry is allways an empty string

for checklist in checklists {
    local checkLex is lex().
    local logicDepth is 0.
    local totalLines is 0.

    local items is checklist:split(".").
    
    checkLex:add( "name", resizeTo( items[0]:trim:split(",")[0]:trim, 34 ) ).
    checkLex:add( "runmode", items[0]:trim:split(",")[1]:tonumber(0) ).
    items:remove(0).
    
    local itemList is list().

    for item in items {
        local itemLex is lex().
        set item to item:trim.

        if item:startswith( "endif" ) { // is not in json
            set logicDepth to logicDepth - 1.
            // add END-IF-MARKER to the last line
            local prevItem is itemList[ itemList:length - 1 ].
            local lines is prevItem:lines.
            
            set lines[ lines:length - 1 ] to overlay( lines[ lines:length - 1 ], STRING_IF_END, depthOffset(logicDepth) ).

            set prevItem:lines to lines.
            set itemList[ itemList:length - 1 ] to prevItem.
        } else {
            if item:startswith( "if" ) {
                itemLex:add( "type", 3 ). // == Type: MD
                itemLex:add( "checkCoordinate", calcCheckCoord(logicDepth+1) ).
                itemLex:add( "logicDepth", logicDepth ).
                itemLex:add( "isEndOfChecklist", false ).
                itemLex:add( "lines", createIfLine( item:split("|")[1]:trim, logicDepth ) ).
                set logicDepth to logicDepth + 1.
            } 
            else if item:startswith( "**" ) {
                itemLex:add( "type", 0 ).
                itemLex:add( "checkCoordinate", calcCheckCoord(logicDepth) ).
                itemLex:add( "logicDepth", logicDepth ).
                itemLex:add( "isEndOfChecklist", true ).
                itemLex:add( "lines", createEndOfChecklistLine(logicDepth) ).
            } 
            else {
                local params is item:split("|").
                itemLex:add( "type", convertType( params[0]:trim ) ).
                itemLex:add( "checkCoordinate", calcCheckCoord(logicDepth) ).
                itemLex:add( "logicDepth", logicDepth ).
                itemLex:add( "isEndOfChecklist", false ).
                itemLex:add( "lines", createLines( params[1]:trim, params[2]:trim, logicDepth ) ).                
            }
            set totalLines to totalLines + itemLex:lines:length.

            itemList:add( itemLex ).
        }
    }

    local pageList is list().
    until itemList:empty {
        from { local i is 1. pageList:add( list() ). } until i >= MAX_LINES_PER_PAGE step { set i to i + 1. } do {
            if itemList:empty {
                pageList[ pageList:length - 1 ]:add( createPlaceHolder() ). 
            } else {
                pageList[ pageList:length - 1 ]:add( itemList[0] ). 
                itemList:remove(0).
            }
        }
    }

    checkLex:add( "items", pageList ).
    checkLex:add( "linesPerPage", MAX_LINES_PER_PAGE ).
    checkLex:add( "pages", ceiling( totalLines / MAX_LINES_PER_PAGE ) ).
    
    log "" to CHECKLIST_DEBUG_PATH.
    log ">>> " + checkLex:name + ", pages: " + checkLex:pages to CHECKLIST_DEBUG_PATH.
    log "-------------------------------------------------" to CHECKLIST_DEBUG_PATH.
    for page in pageList {
        for item in page
            for line in item:lines
                log line to CHECKLIST_DEBUG_PATH.
        log "------------------- page flip -------------------" to CHECKLIST_DEBUG_PATH.
    }

    accumulator:add( checkLex ).
}

local jsonContent is writeJson( accumulator, CHECKLIST_JSON_PATH ):readall():string().

// now lossless compressing the JSON

local function compress {
    parameter str, char.

    local splitList is str:split(char).
    local str_out is splitList[0].
    splitList:remove(0).

    for splitLine in splitList
        set str_out to str_out:trim + char + " " + splitLine:trim.

    return str_out.
}

local out is jsonContent.
set out to compress( out, "}" ).
set out to compress( out, "," ).
set out to compress( out, "{" ).

deletePath( CHECKLIST_JSON_PATH ).
create( CHECKLIST_JSON_PATH ).

local outFile is open( CHECKLIST_JSON_PATH ).
outFile:write( out ).

log "JSON-FILE SIZE: " + outFile:size + " [bytes]" to CHECKLIST_DEBUG_PATH.