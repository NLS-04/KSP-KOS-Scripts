// Terminal stuff and'print-elements'
    wait 5.
    function SecondsToClock {
        parameter secs, onlyUpToHour is false.

        local secs to ABS(secs).

        local sec is FLOOR(mod(secs        ,60     )).
        local min is FLOOR(mod(secs/60     ,60     )).
        local hr  is FLOOR(mod(secs/3600   ,24     )).
        local day is FLOOR(mod(secs/86400  ,365.25 )).
        local yr  is FLOOR(    secs/5184000         ).

        set sec to choose "0" + sec if sec < 10 else sec.
        set min to choose "0" + min if min < 10 else min.
        set hr  to choose "0" + hr  if hr  < 10 else hr.
        set day to choose (choose "00" + day if day < 10 else "0" + day) if day < 100 else day.

        if onlyUpToHour
            return hr+":"+min+":"+sec.

        if day:tonumber(-1) <= 0 and yr <= 0    return hr+":"+min+":"+sec.
        else if yr <= 0                         return "D"+day + "|" + hr+":"+min+":"+sec.
        else                                    return "Yr"+yr+" D"+day + "|" + hr+":"+min+":"+sec.
    }
    function color { // only works on print w/o at(x,y)
        parameter col, text.
        return "<color="+col+">"+text+"</color>".
    }
    function TerminalInput{
        parameter varName, verticalOffset is 2, useExtraLine is true.

        local line is terminal:height-verticalOffset.

        if useExtraLine {
            local ch_  is "".
            for i in range(0, terminal:width) {
                set ch_ to ch_ + "-".
            }
            print ch_ at (0, line - 1).
        }

        print varName + ": >> " at (0,line).

        return getInputs(varName:tostring():length + 5, line, true):tonumber(11).
    }
    function getInputs {
        parameter colume, line, clearAfterInput is false.
        
        local chars is list().
        local ch    is "".

        until false {
            local ch0 is terminal:input:getchar().
            print ch0 at (colume, line).

            if ch0 = terminal:input:enter {
                for a in chars {
                    set ch to ch + a.
                }  

                chars:clear().
                if clearAfterInput {print "                              " at (0,line).}
                
                local var is ch:tostring().

                return var.
            } else if ch0 = terminal:input:backspace {
                if chars:length = 0 {
                    return "".
                } else {
                    chars:remove(chars:length - 1).
                    set colume to colume - 1. 
                    print " " at (colume,line).
                }
            } else {
                chars:add(ch0).
                set colume to colume + 1.
                
                if chars:length = 1 {
                    local chwhite is " ".
                    for i in range(colume, terminal:width-2) {
                        set chwhite to chwhite + " ". 
                    }
                    print chwhite at (colume, line).
                }
            }
        }
    }
    function lexiprinter {
        parameter lexi, line is 0, row is 0. // print ... at (row, line).

        set count to 0.
        for key in lexi:keys {
            print key + ": " + (choose round(lexi[key],3) if lexi[key]:istype("scalar") else lexi[key]:tostring) + "        " at (row, line + count).
            set count to count +1.
        }
    }