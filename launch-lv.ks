//
// LV launch script - uses the PEG library to launch a F9-inspired rocket
// to orbit. Can either be called, or ran as the main script
//


// Load the main library
copypath("0:/peg_lib", "").
run once peg_lib.

// Default parameters
declare parameter pe to 130.            // target periapsis
declare parameter ap to 200.            // target apoapsis
declare parameter inc to 45.            // target inclination
declare parameter u to 0.               // target anomaly (0 = insertion at Pe)
declare parameter kick_start is 18.     // pitch program start time
declare parameter kick_end is 50.       // pitch program end time
declare parameter kick is 18.           // pitch program pitch
declare parameter burn is 200.          // Second stage burn time, refined by algorithm
declare parameter hdg to -1.            // -1 to pick optimal launch azimuth.
                                        // you can force an azimuth, and the second
                                        // stage will correct to reach the target
                                        // inclination (allows dogleg manoeuvres)

set peg_launchcap to 0.95.              // Throttle setting for launch to Max-Q
set peg_maxqdip to 0.8.                 // Throttle setting during Max-Q

set peg_eps to 8.                       // Time to SECO when terminal guidance
                                        // engages
set peg_meco_ap to 85.                  // Apoapsis value that triggers MECO
set peg_gcap to 2.4.                    // Maximum G load during boost stage
set fairing to true.                    // There is a fairing to ditch
set s_T to burn.                        // Set the PEG burn duration

// Start the launch sequence
peg_ascent(pe, ap, u, inc, kick_start, kick_end, kick, hdg).
