clearscreen.
core:part:getmodule("kOSProcessor"):doevent("Open Terminal").
copyPath("0:/GlobeSatBaby.ks", "").

wait until not ship:messages:empty.
run GlobalSatBaby.ks(1).