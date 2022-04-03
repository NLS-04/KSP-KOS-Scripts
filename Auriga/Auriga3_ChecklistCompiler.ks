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
// │ ┎ : : IF ( |<-------------- 36 -------------->| ) │  
// │ ┋ [ ] ABCDEFG ........................... ABCDEFG │
// │ ┋ [ ] ABCDEFG ........................... ABCDEFG │
// │ ┖ [ ] ABCDEFG ........................... ABCDEFG │
// >>> OR WITH END OF CHECKLIST
// │ ┖                  █  █  █  █                     │


local example_checklist_format is list(
    lex( 
        "name", "PLANNING RENDEZVOUS", 
        "runmode", 15,
        "pages", 2,
        "linesPerPage", 12,
        "items", list( // this list holds the specified pages
            list( // this list holds the items for the first page
                lex( "type", 1, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] SAS ...................................... ON") ),
                lex( "type", 1, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] RCS ...................................... ON") ),
                lex( "type", 2, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] TARGET ........................ CONFIRM & SET") ),
                lex( "type", 3, "checkCoordinate", 5, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("┎ [ ] IF ( TARGET ORBITS OTHER BODY )            ") ),
                lex( "type", 0, "checkCoordinate", 5, "logicDepth", 1, "isEndOfChecklist", false, "lines", list("┋ [ ] RUNMODE ......................... SET TO 31") ),
                lex( "type", 0, "checkCoordinate", 0, "logicDepth", 1, "isEndOfChecklist", true,  "lines", list("┖                  █  █  █  █                    ") ),
                lex( "type", 0, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] RUNMODE ........................... SET TO 15") ),
                lex( "type", 3, "checkCoordinate", 5, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("┎ [ ] IF ( DELTA-V IS NOT SUFFICIENT )           ") ),
                lex( "type", 0, "checkCoordinate", 5, "logicDepth", 1, "isEndOfChecklist", false, "lines", list("┋ [ ] RUNMODE ......................... SET TO 11") ),
                lex( "type", 0, "checkCoordinate", 0, "logicDepth", 1, "isEndOfChecklist", true,  "lines", list("┖                  █  █  █  █                    ") ),
                lex( "type", 2, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] DELTA-V MAIN                                 ", "    RESSOURCE ............ CONFIRM SUFFICIENT QTY") )
            ),
            list( // this list holds the items for the first page
                lex( "type", 3, "checkCoordinate", 5, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("┎ [ ] IF ( TARGET ORBITS OTHER BODY )            ") ),
                lex( "type", 0, "checkCoordinate", 5, "logicDepth", 1, "isEndOfChecklist", false, "lines", list("┋ [ ] RUNMODE ......................... SET TO 31") ),
                lex( "type", 0, "checkCoordinate", 0, "logicDepth", 1, "isEndOfChecklist", true,  "lines", list("┖                  █  █  █  █                    ") ),
                lex( "type", 1, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] SAS ...................................... ON") ),
                lex( "type", 1, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] RCS ...................................... ON") ),
                lex( "type", 2, "checkCoordinate", 3, "logicDepth", 0, "isEndOfChecklist", false, "lines", list("[ ] DELTA-V MAIN                                 ", "    RESSOURCE ............ CONFIRM SUFFICIENT QTY") ),
                lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true,  "lines", list("                   █  █  █  █                    ") ),
                lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true,  "lines", list("                       .                         ") ),
                lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true,  "lines", list("                       .                         ") ),
                lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true,  "lines", list("                       .                         ") ),
                lex( "type", 0, "checkCoordinate", 0, "logicDepth", 0, "isEndOfChecklist", true,  "lines", list("                       .                         ") )
            )
        ) 
    )
).

writeJson( example_checklist_format, "0:/Auriga/Auriga3_Checklist.json" ).
// log readJson("0:/Auriga/Auriga3_Checklist.json"):dump to "0:/Auriga/_.txt".