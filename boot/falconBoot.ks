clearscreen.

////// VERY IMPORTANT FOR OTHERS SCRIPTS
declare function import {
    parameter pathFrom, pathTo is "".

    local code is "0:/" + pathFrom + ".ks".
    copypath(code, pathTo).
    runOncePath(code).
}

switch to 0.

list files in scripts.
local scriptsListl        is list().
local scriptsListlBooster is list().
local scriptsListlOrbiter is list().
local script is "NaN".

for k in core:volume:files:keys {
    core:volume:delete(k).
}

for i in scripts {
    if i:name:matchespattern("_orbiter.ks$") {
        scriptsListlOrbiter:add(i).
        scriptsListl:add(i).
    } else if i:name:matchespattern("falcon") {
        scriptsListlBooster:add(i).
        scriptsListl:add(i).
    } 
}

until false {
    core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
    
    if not (script = "NaN") {
        print "Choose a falcon script to boot:" at (1,1).
        print ">>_<<" at (13,2).

        print "Processor: " + core:volume:name + ", Size: " + core:volume:freespace + " max " + core:volume:capacity at (1, 5).

        local ch is "".
        local ent is "".

        if core:tag:matchespattern("cpu2") {
            // for testing purposes it will be manualy setable
            // Gives all available scripts for this ORBITER of the falcon rocket 
            print "Following Scripts are available [1-"+scriptsListlOrbiter:length+"]: " at (1,7).

            for j in range(scriptsListlOrbiter:length) {
                print "                                " + scriptsListlOrbiter[j]:size at (2, j+8).
                print "["+(j+1)+"] "+ scriptsListlOrbiter[j]:name at (2, j+8).
            }

            set ent to terminal:input:getchar().
            set ch to mod(max(0, ent:tonumber(1) - 1), scriptsListlOrbiter:length).
            set script to scriptsListlOrbiter[ch].
        } else {
            core:part:getmodule("kOSProcessor"):doevent("Close Terminal").
            core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
            
            // Gives all available scripts for this BOOSTER of the falcon rocket 
            print "Following Scripts are available [1-"+scriptsListlBooster:length+"]: " at (1,7).

            for j in range(scriptsListlBooster:length) {
                print "                                " + scriptsListlBooster[j]:size at (2, j+8).
                print "["+(j+1)+"] "+ scriptsListlBooster[j]:name at (2, j+8).
            }

            set ent to terminal:input:getchar().
            set ch to mod(max(0, ent:tonumber(1) - 1), scriptsListlBooster:length).
            set script to scriptsListlBooster[ch].
        }        

        if ent:tonumber(0) = 0 {
            // Gives all available scripts of the falcon rocket 
            print "Following Scripts are available [1-"+scriptsListl:length+"]: " at (1,7).

            for j in range(scriptsListl:length) {
                print "                                " + scriptsListl[j]:size at (2, j+8).
                print "["+(j+1)+"] "+ scriptsListl[j]:name at (2, j+8).
            }

            set ent to terminal:input:getchar().
            set ch to mod(max(0, ent:tonumber(1) - 1), scriptsListl:length).
            set script to scriptsListl[ch].
        }

        print ch + 1 at (15,2).

        wait .25.

        clearScreen.
    } else {
        local sname is ship:shipname:tolower(). 
        
        // manipulates our sname: 
        //  > removes(KSP_ENDINGS)  // eg. Trümmer, Relais, ...
        //  > removes(every_WHITESPACES)
        //  > toLower()
        if sname:endswith("trümmer") {
            set sname to sname:remove(sname:length - 8, 8).
        } else if sname:endswith("relais") {
            set sname to sname:remove(sname:length - 7, 7).
        }

        for j in range(0, sname:length - 1) {
            if sname:find(" ") > 0 {
                set sname to sname:remove(sname:find(" "), 1).
            } else { 
                set sname to sname:tolower().
                break. 
            }
        }


        if core:tag:matchespattern("cpu2") {
            for i in scriptsListlOrbiter {
                // removes the '.ks' fileType from the name
                local name is i:name:remove(i:name:length - 3, 3).

                // ONLY scripts which ends ("$") with our sname 
                if name:matchespattern(sname + "_orbiter$") {
                    set script to i.
                    break.
                }
            }
        } else {
            for i in scriptsListlBooster {
                // removes the '.ks' fileType from the name
                local name is i:name:remove(i:name:length - 3, 3).

                // ONLY scripts which ends ("$") with our sname 
                if name:matchespattern(sname + "$") {
                    set script to i.
                    break.
                }
            }
        }         
    }        

    print "Are you sure to boot: > " + script:toString() + " <" at (1,1).
    print "YES = ENTER" at (13,2).
    print "NO = BACKSPACE" at (12,3).

    local check is terminal:input:getchar().

    if check = terminal:input:enter {
        clearScreen.

        set terminal:width to 100.
        set terminal:height to 35.

    // needs special indents beacause of case sensetive printing
    print "                                                                                                    
                                                                                                
.                                                                                               
(                                                                                              
*.                                                                                            
    #                                                                                           
    (#.                                                                                        
    ##,                                                                                      
        ###                                                                                    
        .###/   /(.                                                                           
            ####(    ###%,                                                                     
            ######    .########*                                                             
                ,######/    *##############(/,.                                                
                    (#######*    .##################################*                           
                    ##########      %###%/              #**(###( ##*                         
                        /##########.                            ./#######*                    
                            (/                                   .,*/((######*                
                                                                            *##               
                                                                                ,               
                            @@@@@@@@@@@@@@@@@@@@. (@@@@/         &&&&&#                      
                            @@@@@.                (@@@@/         @@@@@#                      
                            @@@@@.                (@@@@/         @@@@@#                      
                            @@@@@@@@@@@@@@@,      (@@@@@@@@@@#   @@@@@#                      
                            @@@@@.                (@@@@/         @@@@@#                      
                            @@@@@.                (@@@@/         @@@@@#                      
                            @@@@@                 (@@@@/         .@@@@#                      
                            @@@.                                   .@@#                      
                                                                                                ".
        
        print "Booting script: > " + script:name + " <"at (35,4).
        print "Load & Booting files" at (40,5).
        print script:name at (53 - script:name:length/2 , 16).

        if not (defined t) {
            set t to time:seconds.
        }

        until time:seconds - t > 2 or (defined getter) {
            if not terminal:input:haschar {
                if time:seconds - t < 1 {
                    set terminal:brightness to (1 - .1) / 1 * (time:seconds - t) + .1.
                } else {
                    set terminal:brightness to (.1 - 1) / 1 * (time:seconds - t - 1) + 1.
                } 
            } else {
                set getter to terminal:input:getchar(). // to prevent the bootloader to give an input over to the main script
            }                
        }

        set terminal:brightness to 1.
        clearScreen.

        if script:size < core:volume:freespace {
            copypath(script, core:volume).
            switch to core:volume.

            runpath(script).
        } else {
            runpath("0:/" + script).
        }
    } else { 
        clearScreen. 
        set script to "".    
    } 
}