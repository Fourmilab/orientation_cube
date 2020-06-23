    /*

                   Fourmilab Orientation Cube

                         by John Walker
                    https://www.fourmilab.ch/
                    fourmilab in Second Life

        This cube is intended to aid in debugging rotation code.

        The cube is rezzed aligned with the world X, Y, and Z axes
        with its faces colour coded as follows.

                 +        -
            X   Red     Cyan
            Y   Green   Magenta
            Z   Blue    Yellow

        Note the opposite faces on each axis bear complementary
        colours as an aid to memory.

        The cube listens to Nearby Chat on the channel defined by
        commandChannel below, which it communicates to the owner
        when the script is started.

        This program is licensed under a Creative Commons
        Attribution-ShareAlike 4.0 International License.
            http://creativecommons.org/licenses/by-sa/4.0/
        Please see the License section in the "Fourmilab
        Orientation Cube User Guide" notecard included in
        the object for details.  */

    integer commandChannel = 1707;      // Command channel in chat (Euler's birth year)
    integer commandH;                   // Handle for command channel

    integer showText = TRUE;            // Show floating text legend ?
    integer showChildText = FALSE;      // Show floating text legend for child cube ?

    integer echo = TRUE;                // Echo command to sender ?

    //  Link indices within the object

    integer lProbeX;                    // X axis probe
    integer lProbeY;                    // Y axis probe
    integer lProbeZ;                    // Z axis probe
    integer lProbeXG;                   // Global X axis probe
    integer lProbeYG;                   // Global Y axis probe
    integer lProbeZG;                   // Global Z axis probe
    integer lChildCube;                 // Child orientation cube

    key whoDat = NULL_KEY;              // User to whom we're talking
    integer restrictAccess = 2;         // Access restriction: 0 none, 1 group, 2 owner
    float ncRate = 1;                   // Rate at which notecard lines are run, seconds

    vector targetSet = ZERO_VECTOR;     // Target selected for pointing experiments
    vector refPos = ZERO_VECTOR;        // Reference position at start
    integer firstCommand = FALSE;       // Have we received the first command ?

    vector globalXPos;                  // Standard location of global axes
    vector globalYPos;
    vector globalZPos;

    rotation globalXRot;                // Standard rotation of global axes
    rotation globalYRot;
    rotation globalZRot;
    integer globalAxisVis = 0;          // Global axis visibility x = 1, y = 2, z = 4
    float gAoff;                        // Half global axis length

    integer childVis = FALSE;           // Child cube visibility

    integer global = FALSE;             // If true, following operation is global
    integer region = FALSE;             /* If true, following child operation is
                                           in region co-ordinates */
    integer child = FALSE;              // If true, following operation is on child
    float angleScale = DEG_TO_RAD;      // Scale factor for angles

    string helpFileName = "Fourmilab Orientation Cube User Guide"; // Help notecard name

    list undo = [];                     /* Undo list (link, <rotation>, <position>,
                                             <omega axis>, <omega spin>, <omega gain>) */

    list constants = [                  // Symbolic constants for vectors and rotations
        "pi_by_two", "1.57079632679490",
        "two_pi", "6.28318530717959",
        "pi", "3.14159265358979",
        "rang", "?",
        "rvec", "?",
        "rpos", "?"
    ];

    //  Script processing

    integer scriptActive = FALSE;   // Are we reading from a script ?
    integer scriptSuspend = FALSE;  // Suspend script execution for asynchronous event

    //  Auxiliary Messages
//  integer LM_AX_INIT = 10;        // Initialise
//  integer LM_AX_RESET = 11;       // Reset script
    integer LM_AX_STAT = 12;        // Print status
    integer LM_AX_LEGEND = 13;      // Update floating text legend(s)
    integer LM_AX_AXES = 14;        // Show axes orientation
    integer LM_AX_TARGET = 15;      // Show target location
    integer LM_AX_CAST = 16;        // Cast ray and report objects hit

    //  Script Processor messages
    integer LM_SP_INIT = 50;        // Initialise
//  integer LM_SP_RESET = 51;       // Reset script
//  integer LM_SP_STAT = 52;        // Print status
    integer LM_SP_RUN = 53;         // Add script to queue
    integer LM_SP_GET = 54;         // Request next line from script
    integer LM_SP_INPUT = 55;       // Input line from script
    integer LM_SP_EOF = 56;         // Script input at end of file
    integer LM_SP_READY = 57;       // New script ready
    integer LM_SP_ERROR = 58;       // Requested operation failed

    /*  Find a linked prim from its name.  Avoids having to slavishly
        link prims in order in complex builds to reference them later
        by link number.  You should only call this once, in state_entry(),
        and then save the link numbers in global variables.  Returns the
        prim number or -1 if no such prim was found.  Caution: if there
        are more than one prim with the given name, the first will be
        returned without warning of the duplication.  */

    integer findLinkNumber(string pname) {
        integer i = llGetLinkNumber() != 0;
        integer n = llGetNumberOfPrims() + i;

        for (; i < n; i++) {
            if (llGetLinkName(i) == pname) {
                return i;
            }
        }
        llOwnerSay("Could not find link number for \"" + pname + "\".");
        return -1;
    }

    //  tawk  --  Send a message to the interacting user in chat

    tawk(string msg) {
        if (whoDat == NULL_KEY) {
            //  No known sender.  Say in nearby chat.
            llSay(PUBLIC_CHANNEL, msg);
        } else {
            llRegionSayTo(whoDat, PUBLIC_CHANNEL, msg);
        }
    }

    //  resetState  -- Reset state to starting point

    resetState() {
        list omg = llGetLinkPrimitiveParams(LINK_ROOT, [ PRIM_OMEGA ]);
        if (llVecMag(llList2Vector(omg, 0) * llList2Float(omg, 1) *
                     llList2Float(omg, 2)) != 0) {
            llSetLinkPrimitiveParamsFast(LINK_ROOT,
                [ PRIM_OMEGA, ZERO_VECTOR, 0, 0 ]);
            killOmega(FALSE);
        }
        updatePosition(refPos);
        updateRotation(ZERO_ROTATION);
        //  Reset position of child cube whether it's visible or not
        child = TRUE;
        omg = llGetLinkPrimitiveParams(lChildCube, [ PRIM_OMEGA ]);
        if (llVecMag(llList2Vector(omg, 0) * llList2Float(omg, 1) *
                     llList2Float(omg, 2)) != 0) {
            llSetLinkPrimitiveParamsFast(lChildCube,
                [ PRIM_OMEGA, ZERO_VECTOR, 0, 0 ]);
            killOmega(TRUE);
        }
        updatePosition(<gAoff, gAoff, gAoff>);
        updateRotation(ZERO_ROTATION);
        child = FALSE;
        undo = [ ];
    }

    // undoSave  --  Push rotation, position, and omega on undo stack

    undoSave() {
        if (child) {
            list omg = llGetLinkPrimitiveParams(lChildCube, [ PRIM_OMEGA ]);
            //  For child, undo is relative to the root prim
            undo = [ lChildCube,
                        llList2Rot(llGetLinkPrimitiveParams(lChildCube,
                            [ PRIM_ROT_LOCAL ]), 0),
                        llList2Vector(llGetLinkPrimitiveParams(lChildCube,
                            [ PRIM_POS_LOCAL ]), 0),
                        llList2Vector(omg, 0), llList2Float(omg, 1), llList2Float(omg, 2)
                 ] + undo;
        } else {
            list omg = llGetLinkPrimitiveParams(LINK_ROOT, [ PRIM_OMEGA ]);
            //  For the root prim, undo is in global co-ordinates
            undo = [ LINK_ROOT, llGetRot(), llGetPos(),
                llList2Vector(omg, 0), llList2Float(omg, 1), llList2Float(omg, 2) ] + undo;
        }
    }

    //  updateLegend  --  Update floating text legend

    updateLegend() {
        llMessageLinked(LINK_THIS, LM_AX_LEGEND,
            llList2Json(JSON_ARRAY, [ showText, showChildText && childVis,
                                      refPos, angleScale
                                    ]),
            whoDat);
    }

    //  updateRotation  --  Update rotation and legend, if shown

    updateRotation(rotation r) {
        undoSave();
        if (child) {
            llSetLinkPrimitiveParamsFast(lChildCube, [ PRIM_ROT_LOCAL, r ]);
        } else {
            hideGlobalAxes();
            llSetRot(r);
            restoreGlobalAxes();
            showGlobalAxes();
        }
        updateLegend();
    }

    //  updatePosition  --  Update position in region co-ordinates

    updatePosition(vector p) {
        undoSave();
        if (child) {
            llSetLinkPrimitiveParamsFast(lChildCube, [ PRIM_POS_LOCAL, p ]);
        } else {
            hideGlobalAxes();
            llSetPos(p);
            restoreGlobalAxes();
            showGlobalAxes();
        }
        updateLegend();
    }

    //  hideGlobalAxes  --  Hide global axes during rotation or translate

    hideGlobalAxes() {
        llSetLinkAlpha(lProbeXG, 0, ALL_SIDES);
        llSetLinkAlpha(lProbeYG, 0, ALL_SIDES);
        llSetLinkAlpha(lProbeZG, 0, ALL_SIDES);
    }

    //  showGlobalAxes  --  Restore visible global axes after rotate or translate

    showGlobalAxes() {
        llSetLinkAlpha(lProbeXG, (globalAxisVis & 1) != 0, ALL_SIDES);
        llSetLinkAlpha(lProbeYG, (globalAxisVis & 2) != 0, ALL_SIDES);
        llSetLinkAlpha(lProbeZG, (globalAxisVis & 4) != 0, ALL_SIDES);
    }

    /*  The following two functions, saveGlobalAxes() and
        restoreGlobalAxes(), are the price we pay for one of the most
        serious shortcomings in the design of Second Life: the lack of
        hierarchy in linked objects.  In almost any other 3D modeling
        system, it is possible to assemble mechanisms from
        sub-assemblies each of which has its own part, some of which
        may, in turn, be composites.  A sub-assembly is treated as
        atomic at higher levels, but may move its own components
        relative to its own position and orientation.

        Second Life has none of this.  A linked object is a flat
        collections of prims with a single root prim, and just the
        single level of hierarchy: the root and its children.  This
        means that any operation which moves or rotates the root also
        rotates all children in their rigid orientations, and that
        there is no way to move a group of children independently of
        the root.

        This makes even relatively simple mechanisms with internal
        moving parts hideously complicated and ugly to program, since
        any change to the root requires individually reversing, by
        inverse transforms, any parts of the link set which should not
        move with the root.

        This bites us savagely when we want to provide a global set of
        axes that provides an invariant reference as the local axes of
        the cube are transformed.  When we move the cube (which is the
        root prim), it also moves our global axes (which are child
        prims of it), and the only way to compensate for this is, for
        each operation, to put them back where they belong by
        transforming the global (region) position and rotation before
        the operation on the cube back into local co-ordinates relative
        to the root prim (to which they are linked) and then adjusting
        the position of the axes.  Even this is made more painful by
        the fact that there isn't any way to set the region
        co-ordinates of a child prim (even though you can get them with
        PRIM_POSITION and PRIM_ROTATION), and hence you're forced to
        transform them to local yourself.

        This results in the silly little two-step every time you
        perform a transformation with global axes displayed.  First the
        axes move to the wrong place, and then we bounce them back
        where they belong.  We try to hide much of this by hiding the
        global axes and then only making them visible after the final
        reposition, but due to server/viewer latency, you'll still see
        a little bounce.  */

    //  saveGlobalAxes  --  Save global axes position and rotation in region co-ordinates

    vector sgXp;                // Saved global axis positions
    vector sgYp;
    vector sgZp;

    rotation sgXr;              // Saved global axis rotations
    rotation sgYr;
    rotation sgZr;

    saveGlobalAxes() {
        sgXp = llList2Vector(llGetLinkPrimitiveParams(lProbeXG,
                [ PRIM_POSITION ]), 0);
        sgYp = llList2Vector(llGetLinkPrimitiveParams(lProbeYG,
                [ PRIM_POSITION ]), 0);
        sgZp = llList2Vector(llGetLinkPrimitiveParams(lProbeZG,
                [ PRIM_POSITION ]), 0);

        sgXr = llList2Rot(llGetLinkPrimitiveParams(lProbeXG,
                [ PRIM_ROTATION ]), 0);
        sgYr = llList2Rot(llGetLinkPrimitiveParams(lProbeYG,
                [ PRIM_ROTATION ]), 0);
        sgZr = llList2Rot(llGetLinkPrimitiveParams(lProbeZG,
                [ PRIM_ROTATION ]), 0);
    }

    //  restoreGLobalAxes  --  Restore global axes after rotation or translation

    restoreGlobalAxes() {
        vector p = llGetPos();
        rotation r = llGetRot();

        //  Translate to position in local co-ordinate system
        llSetLinkPrimitiveParamsFast(lProbeXG, [ PRIM_POS_LOCAL, (sgXp - p) / r ]);
        llSetLinkPrimitiveParamsFast(lProbeYG, [ PRIM_POS_LOCAL, (sgYp - p) / r ]);
        llSetLinkPrimitiveParamsFast(lProbeZG, [ PRIM_POS_LOCAL, (sgZp - p) / r ]);

        //  Rotate to correct orientation in local co-ordinate system
        llSetLinkPrimitiveParamsFast(lProbeXG, [ PRIM_ROT_LOCAL, sgXr / r ]);
        llSetLinkPrimitiveParamsFast(lProbeYG, [ PRIM_ROT_LOCAL, sgYr / r ]);
        llSetLinkPrimitiveParamsFast(lProbeZG, [ PRIM_ROT_LOCAL, sgZr / r ]);
    }

    /*  axes  --  Parse specification of one or more axes.  Returns
                  a bit mask of axes set: x = 1, y = 2, z = 4.  In
                  case of error, -1 is returned.  */

    integer axes(string s) {
        integer i;
        integer axb = 0;

        for (i = 0; i < llStringLength(s); i++) {
            string c = llGetSubString(s, i, i);
            if (c == "x") {
                axb = axb | 1;
            } else if (c == "y") {
                axb = axb | 2;
            } else if (c == "z") {
                axb = axb | 4;
            } else {
                return -1;
            }
        }
        return axb;
    }

    //  checkAccess  --  Check if user has permission to send commands

    integer checkAccess(key id) {
        return (restrictAccess == 0) ||
               ((restrictAccess == 1) && llSameGroup(id)) ||
               (id == llGetOwner());
    }

    //  randomValue  --  Generate random values of different kinds

    string randomValue(string kname) {
        integer rpos = FALSE;
        if (kname == "rang") {
            return (string) llFrand(TWO_PI / angleScale);
        } else if ((kname == "rvec") || ((rpos = (kname == "rpos")))) {
            /*  Random unit vector by Marsaglia's method:
                Marsaglia, G. "Choosing a Point from the Surface
                of a Sphere." Ann. Math. Stat. 43, 645-646, 1972.  */
            integer outside = TRUE;

            while (outside) {
                float x1 = 1 - llFrand(2);
                float x2 = 1 - llFrand(2);
                if (((x1 * x1) + (x2 * x2)) < 1) {
                    outside = FALSE;
                    float x = 2 * x1 * llSqrt(1 - (x1 * x1) - (x2 * x2));
                    float y = 2 * x2 * llSqrt(1 - (x1 * x1) - (x2 * x2));
                    float z = 1 - 2 * ((x1 * x1) + (x2 * x2));
//tawk("Rvec " + (string) <x, y, z> + " mag " + (string) llVecMag(<x, y, z>));
                    if (rpos) {
                        vector pos;
                        if (child) {
                            pos = llList2Vector(llGetLinkPrimitiveParams(lChildCube,
                                                [ PRIM_POSITION ]), 0);
                        } else {
                            pos = llGetPos();
                        }
                        x += pos.x;
                        y += pos.y;
                        z += pos.z;
                    }
                    //  Must do it this way to avoid spaces within vector
                    return "<" + (string) x + "," +
                                 (string) y + "," +
                                 (string) z + ">";
                }
            }
        }
        return kname;
    }

    //  expandArgs  --  Expand symbolic constants and macros in arguments.

    string expandArgs(string args) {
        integer i;

        for (i = 0; i < llGetListLength(constants); i += 2) {
            integer n;
            string kname = llList2String(constants, i);
            while ((n = llSubStringIndex(args, kname)) >= 0) {
                string nargs = "";
                if (n > 0) {
                    nargs = llGetSubString(args, 0, n - 1);
                }
                string krep = llList2String(constants, i + 1);
                if (krep == "?") {
                    krep = randomValue(kname);
                }
                nargs += krep;
                integer e = n + llStringLength(llList2String(constants, i));
                if (e < llStringLength(args)) {
                    nargs += llGetSubString(args, e, -1);
                }
                args = nargs;
            }
        }
        return args;
    }

    /*  fixArgs  --  Transform command arguments into canonical form.
                     All white space within vector and rotation brackets
                     is elided so they will be parsed as single arguments.  */

    string fixArgs(string cmd) {
        cmd = llToLower(llStringTrim(cmd, STRING_TRIM));
        integer l = llStringLength(cmd);
        integer inbrack = FALSE;
        integer i;
        string fcmd = "";

        for (i = 0; i < l; i++) {
            string c = llGetSubString(cmd, i, i);
            if (inbrack && (c == ">")) {
                inbrack = FALSE;
            }
            if (c == "<") {
                inbrack = TRUE;
            }
            if (!((c == " ") && inbrack)) {
                fcmd += c;
            }
        }
        return expandArgs(fcmd);
    }

    /*  compLG  --  Compose new rotation with current rotation
                    according to the setting of the "global"
                    and "region" modifiers.  */

    rotation compLG(rotation r) {
        if (child) {
            if (region) {
                rotation rot = r;
                //  Child in region co-ordinates
                rotation gRot = llList2Rot(llGetLinkPrimitiveParams(lChildCube,
                    [ PRIM_ROTATION ]), 0);
                //  Displaced child orientation in region co-ordinates
                rotation nRot = gRot * rot;
                //  Root in region co-ordinates
                rotation rRot = llGetRot();
                //  Displaced child position in local (root-relative) co-ordinates
                rotation wRot = nRot / rRot;
                return wRot;
            } else {
                rotation lrot = llList2Rot(llGetLinkPrimitiveParams(lChildCube, [ PRIM_ROT_LOCAL ]), 0);
                if (global) {
                    return lrot * r;
                }
                return r * lrot;
            }
        } else {
            if (global || region) {
                return llGetRot() * r;
            }
            return r * llGetRot();
        }
    }

    //  killOmega  -- Cancel any intrinsic rotation of parent or child

    killOmega(integer isChild) {
        rotation r = llGetRot();
        integer linque = LINK_ROOT;
        if (isChild) {
            linque = lChildCube;
        }

        /*  What's all this, you ask?  Well, you see, when you
            Omega rotate a non-physical prim, the operation is
            performed entirely locally, in the viewer.
            Apparently, then, after stopping the rotation, if
            you want to explicitly rotate the prim (or in this
            case, a linked object) to a fixed location, such as
            the starting point, the rotation is ignored (my
            guess is because the server doesn't know the prim
            has been rotated by the viewer).  So, what we have
            to do is a little jiggle of a local rotation to
            persuade the server that it has moved, and then do
            the actual rotation to put it where we want it.  Oh,
            and one more thing: that little jiggle can't be a
            llSetLinkPrimitiveParamsFast()--it has to use the full
            one that waits 200 milliseconds because apparently
            the fast variant is too fast for the server to twig
            to the fact that you've rotated it with Omega.  */

        if (isChild) {
            r = llList2Rot(llGetLinkPrimitiveParams(lChildCube,
                [ PRIM_ROT_LOCAL ]), 0);
            llSetLinkPrimitiveParams(linque,
                [ PRIM_ROT_LOCAL, r * llEuler2Rot(<0, 0, 0.001>) ]);
            llSetLinkPrimitiveParamsFast(linque,
                [ PRIM_ROT_LOCAL, r ]);
        } else {
            llSetLinkPrimitiveParams(linque,
                [ PRIM_ROTATION, r * llEuler2Rot(<0, 0, 0.001>) ]);
            llSetLinkPrimitiveParamsFast(linque,
                [ PRIM_ROTATION, r ]);
        }
    }

    //  abbrP  --  Test if string matches abbreviation

    integer abbrP(string str, string abbr) {
        return abbr == llGetSubString(str, 0, llStringLength(abbr) - 1);
    }

    //  onOff  --  Parse an on/off parameter

    integer onOff(string param) {
        if (abbrP(param, "on")) {
            return TRUE;
        } else if (abbrP(param, "of")) {
            return FALSE;
        } else {
            tawk("Error: please specify on or off.");
            return -1;
        }
    }

    /*  scriptName  --  Extract script name from Run command.
                        This is a horrific kludge which allows script
                        names to be upper and lower case.  It finds the
                        command in the lower case command string then
                        extracts the text that follows, trimming leading
                        and trailing blanks, from the upper and lower
                        case original command.  */

    string scriptName(string cmd, string lmessage, string message) {
        //  Find command in lower case command string ...
        integer dindex = llSubStringIndex(lmessage, cmd);
        //  Advance past space after cmd
        integer spindex = llSubStringIndex(llGetSubString(lmessage, dindex, -1), " ");
        if (spindex < 0) {
            return "";
        }
        dindex += spindex + 1;
        //  Note that STRING_TRIM elides any leading and trailing spaces
        return llStringTrim(llGetSubString(message, dindex, -1), STRING_TRIM);
    }

    /*  scriptResume  --  Resume script execution when asynchronous
                          command completes.  */

    scriptResume() {
        if (scriptActive) {
            if (scriptSuspend) {
                scriptSuspend = FALSE;
                llMessageLinked(LINK_THIS, LM_SP_GET, "", NULL_KEY);
            }
        }
    }

    //  processCommand  --  Process command from local chat or dialogue

    integer processCommand(key id, string message, integer fromScript) {

        if (!checkAccess(id)) {
            llRegionSayTo(id, PUBLIC_CHANNEL,
                "You do not have permission to control this object.");
            return FALSE;
        }

        whoDat = id;                                // Direct chat output to sender of command

        /*  Update the reference position when we receive the
            first command from the user.  This avoids confusioin
            in the common case where the user rezzes the cube, then
            moves it to the desired position before starting to use
            it.  If refPos remained at the position saved in stateEntry,
            the cube would then appear displaced from the origin
            when processing commands unless Restarted.  */

        if (!firstCommand) {
            refPos = llGetPos();
            firstCommand = TRUE;
        }

        //  Suppress command echo if prefixed with "@"
        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }

        string lmessage = fixArgs(message);
        list args = llParseString2List(lmessage, [" "], []);    // Command and arguments

        //  Process modifiers that precede the command

        integer mods = TRUE;

        global = FALSE;
        region = FALSE;
        child = FALSE;
        while (mods) {
            string arg0 = llList2String(args, 0);

            if (abbrP(arg0, "gl")) {
                global = TRUE;
                args = llDeleteSubList(args, 0, 0);
            } else if (abbrP(arg0,  "reg")) {
                region = TRUE;
                args = llDeleteSubList(args, 0, 0);
            } else if (abbrP(arg0, "ch")) {
                child = TRUE;
                args = llDeleteSubList(args, 0, 0);
            } else {
                mods = FALSE;
            }
        }

        integer argc = llGetListLength(args);       // Command and argument count
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First parameter for convenience

        /*  Hack: allow "ll" as optional prefix on commands so
            user can enter original function names.  */
        if (llGetSubString(command, 0, 1) == "ll") {
            command = llGetSubString(command, 2, -1);
        }

        if (echo && echoCmd) {
            string prefix = ">> ";
            if (fromScript) {
                prefix = "++ ";
            }
            tawk(prefix + message);                 // Echo command to sender
        }

        //  Aim [<X, Y Z>]              Aim at point or target

        if (abbrP(command, "ai")) {
            vector aimPoint;
            if (argc > 1) {
                aimPoint = (vector) sparam;
            } else {
                aimPoint = targetSet;
            }
//tawk(lmessage + "  --  " + (string) aimPoint + " : " + sparam);
            if (aimPoint != ZERO_VECTOR) {
                if (child) {
                    //  Compute normalized vector from child to target
                    vector ourPos = llList2Vector(llGetLinkPrimitiveParams(lChildCube,
                        [ PRIM_POSITION ]), 0);
                    vector nvec = llVecNorm(aimPoint - ourPos);

                    //  Compute angle to tilt around X to point at target's Z
                    float xang = llSin(nvec.z);

                    //  Compute angle to rotate about Z to point at target
                    float zang = llAtan2(nvec.y, nvec.x);
                    zang += PI + PI_BY_TWO;
                    rotation zrot = llEuler2Rot(<0, 0, zang>);
                    //  Force region mode and rotate in region co-ordinates
                    region = TRUE;
                    updateRotation((llAxisAngle2Rot(<1, 0, 0>, xang) * zrot) / llGetRot());
                } else {
                    //  Compute normalized vector from object to target
                    vector ourPos = llList2Vector(llGetLinkPrimitiveParams(LINK_THIS,
                        [ PRIM_POSITION ]), 0);
                    vector nvec = llVecNorm(aimPoint - ourPos);

                    //  Compute angle to tilt around X to point at target's Z
                    float xang = llSin(nvec.z);

                    //  Compute angle to rotate about Z to point at target
                    float zang = llAtan2(nvec.y, nvec.x);
                    zang += PI + PI_BY_TWO;
                    rotation zrot = llEuler2Rot(<0, 0, zang>);
                    updateRotation(llAxisAngle2Rot(<1, 0, 0>, xang) * zrot);
//tawk("xang " + (string) xang + " zrot " + (string) zrot);
                }
            } else {
                tawk("No target set.  Use the Target command to specify one.");
            }

        //  Axes                        Show local axis vectors in global space

        } else if (command == "axes") {
            llMessageLinked(LINK_THIS, LM_AX_AXES,
                llList2Json(JSON_ARRAY, [ child ]), whoDat);

        //  [ll]Axes2Rot <forward> <left> <up>  Rotate to align orthogonal normal vectors

        } else if (abbrP(command, "axes2")) {
            updateRotation(compLG(llAxes2Rot(
                llVecNorm((vector) sparam),
                llVecNorm((vector) llList2String(args, 2)),
                llVecNorm((vector) llList2String(args, 3)))));

        //  [ll]AxisAngle2Rot <X, Y, Z> ang Rotate around axis specified by vector

        } else if (abbrP(command, "axi")) {
            vector raxis = (vector) sparam;
            float rang = ((float) llList2String(args, 2)) * angleScale;
            updateRotation(compLG(llAxisAngle2Rot(raxis, rang)));

        //  [ll]CastRay <X, Y, Z> len   Report objects along ray of len along <X, Y, Z>

        } else if (abbrP(command, "ca")) {
            vector dir = llVecNorm((vector) sparam);
            float dist = llList2Float(args, 2);
            llMessageLinked(LINK_THIS, LM_AX_CAST,
                llList2Json(JSON_ARRAY, [ child, global, region, dir, dist ]), whoDat);

        //  Clear                       Clear chat window

        } else if (abbrP(command, "cl")) {
            tawk("\n\n\n\n\n\n\n\n\n\n\n\n");

        //  Echo message                Display message

        } else if (abbrP(command, "ec")) {
            string msg = scriptName("ec", lmessage, message);
            if (msg == "") {
                msg = " ";
            }
            tawk(msg);

        //  Help                        Give help information

        } else if (abbrP(command, "he")) {
            llGiveInventory(id, helpFileName);      // Give requester the User Guide notecard

        //  Omega <X, Y, Z> spinrate gain   Set local rotation

        } else if (abbrP(command, "om") || abbrP(command, "targeto")) {
            vector axis = ZERO_VECTOR;
            float spinrate = 0;
            float gain = 0;
            integer linque = LINK_ROOT;
            if (child) {
                linque = lChildCube;
            }
            if (argc > 1) {
                axis = (vector) sparam;
                spinrate = PI / 4;
                gain = 1;
                if (argc > 2) {
                    spinrate = ((float) llList2String(args, 2)) * angleScale;
                    if (argc > 3) {
                        gain = (float) llList2String(args, 3);
                    }
                }
            }
            rotation r = llGetRot();
            if (child) {
                //  Child prim rotates around its local axis
                rotation cr = llList2Rot(llGetLinkPrimitiveParams(lChildCube,
                                        [ PRIM_ROT_LOCAL ]), 0);

                if (global) {
                    //  For child, axis is already parent's co-ordinates
                } else if (region) {
                    //  Rotation is in region co-ordinates
                    axis = axis / r;
                } else {
                    //  Rotation is in the child's local co-ordinates
                    axis = axis * cr;
                }

            } else {
                //  Root prim rotates around the region axis
                if (!(global || region)) {
                    //  If local, apply root prim's rotation
                    axis = axis * r;
                }
            }
            undoSave();
            llSetLinkPrimitiveParamsFast(linque,
                [ PRIM_OMEGA, axis, spinrate, gain ]);
            if ((spinrate * gain) == 0) {
                killOmega(child);
            }
            updateLegend();

        //  Pause                       Suspend script until touched

        } else if (abbrP(command, "pa")) {
            if (argc > 1) {
                llSleep((float) sparam);
            } else {
                if (scriptActive) {
                    scriptSuspend = TRUE;
                    tawk("Paused: touch to resume.");
                }
            }

        //  Probe [X/Y/Z] [on/off]      Display/hide axis orientation probe

        } else if (abbrP(command, "probe")) {
            integer which;
            string onoff;
            if (llGetSubString(command, 5, 5) == "s") {
                which = 7;
                onoff = llList2String(args, 1);
            } else {
                which = axes(sparam);
                onoff = llList2String(args, 2);
            }
            if (which <= 0) {
                tawk("Invalid probe axes: " + sparam + ".");
            } else {
                /*  Yes, it's tacky to use a vector to store integer
                    link numbers, but it's also kind of cool.  */
                vector probes = <lProbeX, lProbeY, lProbeZ>;
                if (global || region) {
                    probes = <lProbeXG, lProbeYG, lProbeZG>;
                }
                integer palpha = -1;
                if (onoff == "on") {
                    palpha = 1;
                } else if (onoff == "off") {
                    palpha = 0;
                } else {
                    tawk("Invalid probe state " + onoff + ".");
                }
                if (palpha >= 0) {
                    integer axVis = globalAxisVis;
                    if (which & 1) {
                        llSetLinkAlpha((integer) probes.x, palpha, ALL_SIDES);
                        axVis = (axVis & ~1) | palpha;
                    }
                    if (which & 2) {
                        llSetLinkAlpha((integer) probes.y, palpha, ALL_SIDES);
                        axVis = (axVis & ~2) | (palpha << 1);
                    }
                    if (which & 4) {
                        llSetLinkAlpha((integer) probes.z, palpha, ALL_SIDES);
                        axVis = (axVis & ~4) | (palpha << 2);
                    }
                    if (global || region) {
                        globalAxisVis = axVis;
                    }
                }
            }

        //  Qrot <X, Y, Z, S>           Rotate to quaternion <X, Y, Z, S>

        } else if (abbrP(command, "qr")) {
            rotation nrot = (rotation) sparam;
            updateRotation(compLG(nrot));

        //  Reset                       Reset to initial state

        } else if (abbrP(command, "rese")) {
            resetState();

        //  Restart                     Restart script, restoring initial conditions

        } else if (abbrP(command, "rest")) {
//            refPos = llGetPos();
//            resetState();
            llResetScript();

        //  Rot <X, Y, Z>               Rotate to Euler angles <X, Y, Z>
        //  [ll]Euler2Rot <X, Y, Z>

        } else if ((command == "rot") || abbrP(command, "eu")) {
            vector nrot = ((vector) sparam) * angleScale;
            updateRotation(compLG(llEuler2Rot(nrot)));

        //  [ll]RotBetween <X, Y, Z> <X, Y, Z>  Rotate to point first vector in second direction

        } else if (abbrP(command, "rotb")) {
            updateRotation(compLG(llRotBetween((vector) sparam,
                (vector) llList2String(args, 2))));

        //  RotX ang                    Rotate ang around X

        } else if (abbrP(command, "rotx")) {
            updateRotation(compLG(llAxisAngle2Rot(<1, 0, 0>,
                angleScale * ((float) sparam))));

        //  RotY ang                    Rotate ang around Y

        } else if (abbrP(command, "roty")) {
            updateRotation(compLG(llAxisAngle2Rot(<0, 1, 0>,
                angleScale * ((float) sparam))));

        //  RotZ ang                    Rotate ang around Z

        } else if (abbrP(command, "rotz")) {
            updateRotation(compLG(llAxisAngle2Rot(<0, 0, 1>,
                angleScale * ((float) sparam))));

        //  Script run name             Run script with given name

        } else if (abbrP(command, "sc") && (argc >= 2) &
                   abbrP(llList2String(args, 1), "ru")) {
            if (argc == 2) {
                scriptActive = scriptSuspend = FALSE;
                llMessageLinked(LINK_THIS, LM_SP_INIT, "", whoDat); // Reset Script Processor
            } else {
                llMessageLinked(LINK_THIS, LM_SP_RUN,
                    scriptName("ru", lmessage, message), whoDat);
            }

        //  Set                         Set parameter

        } else if (command == "set") {
            string param = llList2String(args, 1);
            string svalue = llList2String(args, 2);

            //  Set Access owner/group/public   Restrict chat command access to public/group/owner

            if (abbrP(param, "ac")) {
                if (abbrP(svalue, "p")) {
                    restrictAccess = 0;
                } else if (abbrP(svalue, "g")) {
                    restrictAccess = 1;
                } else if (abbrP(svalue, "o")) {
                    restrictAccess = 2;
                } else {
                    tawk("Invalid access.  Valid: owner, group, public.");
                }

            //  Set Angles degrees/radians  Set angle input to degrees or radians

            } else if (abbrP(param, "an")) {
                if (abbrP(svalue, "d")) {
                    angleScale = DEG_TO_RAD;
                    updateLegend();
                } else if (abbrP(svalue, "r")) {
                    angleScale = 1;
                    updateLegend();
                } else {
                    tawk("Invalid set angle.  Valid: degree, radian.");
                }

            /*  Set Channel n                   Change command channel.  Note that
                                                the channel change is lost on a
                                                script reset.  */

            } else if (abbrP(param, "cha")) {
                integer newch = (integer) svalue;
                if ((newch < 2)) {
                    tawk("Invalid channel number.  Must be 2 or greater.");
                } else {
                    llListenRemove(commandH);
                    commandChannel = newch;
                    commandH = llListen(commandChannel, "", NULL_KEY, "");
                    tawk("Listening on chat /" + (string) commandChannel + ".");
                }

            //  Set Child on/off            Display/hide child cube

            } else if (abbrP(param, "chi")) {
                childVis = onOff(svalue);
                llSetLinkAlpha(lChildCube, childVis, ALL_SIDES);
                if (childVis) {
                    updateLegend();
                } else {
                    llSetLinkPrimitiveParamsFast(lChildCube, [ PRIM_TEXT, "", <0, 0, 0>, 0 ]);
                }

            //  Set Echo on/off             Control echo of commands to sender

            } else if (abbrP(param, "ec")) {
                echo = onOff(svalue);

            //  Set Legend on/off           Display/hide floating text legend

            } else if (abbrP(param, "le")) {
                if (!onOff(svalue)) {
                    if (child) {
                        showChildText = FALSE;
                        llSetLinkPrimitiveParamsFast(lChildCube, [ PRIM_TEXT, "", <0, 0, 0>, 0 ]);
                    } else {
                        showText = FALSE;
                        llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEXT, "", <0, 0, 0>, 0 ]);
                    }
                } else {
                    if (child) {
                        showChildText = TRUE;
                    } else {
                        showText = TRUE;
                    }
                    updateLegend();
                }

            //  Set Runrate t               Execute script commands every t seconds

            } else if (abbrP(param, "ru")) {
                ncRate = (float) svalue;

            } else {
                tawk("Unknown variable.  Valid: access, angles, channel, child, echo, legend, runrate.");
            }

        //  [ll]SetPos/Move <X, Y, Z>   Move relative in specified direction

        } else if (abbrP(command, "setp") || abbrP(command, "mo")) {
            vector disp = (vector) sparam;
            if (child) {
                if (region) {
                    //  Child in region co-ordinates
                    vector gPos = llList2Vector(llGetLinkPrimitiveParams(lChildCube,
                        [ PRIM_POSITION ]), 0);
                    //  Displaced child position in region co-ordinates
                    vector nPos = gPos + disp;
                    //  Root in region co-ordinates
                    rotation rRot = llGetRot();
                    vector rPos = llGetPos();
                    //  Displaced child position in local (root-relative) co-ordinates
                    vector wPos = (nPos - rPos) / rRot;
                    updatePosition(wPos);
                } else {
                vector pos = llList2Vector(llGetLinkPrimitiveParams(lChildCube, [ PRIM_POS_LOCAL ]), 0);
                    if (!global) {
                        rotation rot = llList2Rot(llGetLinkPrimitiveParams(lChildCube,
                            [ PRIM_ROT_LOCAL ]), 0);
                        disp = disp * rot;
                    }
                    updatePosition(pos + disp);
                }
            } else {
                vector pos = llGetPos();    // Position in region co-ordinates
                if (!(global || region)) {
                    disp = disp * llGetRot();
                }
                updatePosition(pos + disp);
            }

        //  [ll]SetRot                  Set absolute rotation

        } else if (abbrP(command, "setr")) {
            //  Note that this function always sets global rotation
            updateRotation(llEuler2Rot(((vector) sparam) * angleScale));

        //  Status                      Print current orientation status

        } else if (abbrP(command, "st")) {
            llMessageLinked(LINK_THIS, LM_AX_STAT,
                llList2Json(JSON_ARRAY, [ angleScale, refPos, childVis,
                                          llGetListLength(undo) / 6,
                                          llGetFreeMemory(), llGetUsedMemory(),
                                          targetSet
                                        ]),
                whoDat);

        /*  Target <X, Y, Z> / me       Set point-to target to <X, Y, Z> or
                                        me (sender's position)  */

        } else if (command == "target") {
            if (sparam == "me") {
                targetSet = llList2Vector(llGetObjectDetails(whoDat, [ OBJECT_POS ]), 0);
            } else {
                targetSet = (vector) sparam;
            }
            llMessageLinked(LINK_THIS, LM_AX_TARGET,
                llList2Json(JSON_ARRAY, [ targetSet ]), whoDat);

        //  Test n                      Run built-in test n

//      } else if (abbrP(command, "te")) {
//          integer n = (integer) sparam;

        //  Undo                        Undo last command

        } else if (abbrP(command, "un")) {
            if (llGetListLength(undo) > 0) {
                integer link = llList2Integer(undo, 0);
                if (link == lChildCube) {
                    //  Undo of child is done in link set-local coordinates
                    llSetLinkPrimitiveParamsFast(lChildCube, [ PRIM_POS_LOCAL, llList2Vector(undo, 2) ]);
                    llSetLinkPrimitiveParamsFast(lChildCube, [ PRIM_ROT_LOCAL, llList2Rot(undo, 1) ]);
                } else {
                    //  Undo of root prim is in global co-ordinates
                    hideGlobalAxes();
                    llSetPos(llList2Vector(undo, 2));
                    llSetRot(llList2Rot(undo, 1));
                    restoreGlobalAxes();
                }
                //  Restore omega, invoking killOmega() if we're turning it off
                list omg = llGetLinkPrimitiveParams(link, [ PRIM_OMEGA ]);
                integer oldOmega = llVecMag(llList2Vector(omg, 0) * llList2Float(omg, 1) *
                                            llList2Float(omg, 2)) != 0;
                llSetLinkPrimitiveParamsFast(link,
                    [ PRIM_OMEGA, llList2Vector(undo, 3),
                      llList2Float(undo, 4), llList2Float(undo, 5)]);
                integer newOmega = llVecMag(llList2Vector(undo, 3) * llList2Float(undo, 4) *
                                            llList2Float(undo, 5)) != 0;
                if (oldOmega && (!newOmega)) {
                    killOmega(link == lChildCube);
                }

                updateLegend();
                showGlobalAxes();
                undo = llDeleteSubList(undo, 0, 5);     // Pop undo list
        } else {
            tawk("Nothing to undo.");
        }

        } else {
            tawk("Huh?  \"" + message + "\" undefined.  Chat /" +
                (string) commandChannel + " help for instructions.");
            return FALSE;
        }
        return TRUE;
    }

    //  Default state event handler

    default {

        on_rez(integer start_param) {
            llResetScript();
        }

        state_entry() {

            //  Find link numbers for linked components

            lProbeX = findLinkNumber("X Probe");
            lProbeY = findLinkNumber("Y Probe");
            lProbeZ = findLinkNumber("Z Probe");

            lProbeXG = findLinkNumber("Global X Probe");
            lProbeYG = findLinkNumber("Global Y Probe");
            lProbeZG = findLinkNumber("Global Z Probe");

            lChildCube = findLinkNumber("Child Orientation Cube");

            llOwnerSay("Listening on /" + (string) commandChannel);
            commandH = llListen(commandChannel, "", NULL_KEY, ""); // Listen on command chat channel

            //  Hide the axis probes
            llSetLinkAlpha(lProbeX, 0, ALL_SIDES);
            llSetLinkAlpha(lProbeY, 0, ALL_SIDES);
            llSetLinkAlpha(lProbeZ, 0, ALL_SIDES);

            llSetLinkAlpha(lProbeXG, 0, ALL_SIDES);
            llSetLinkAlpha(lProbeYG, 0, ALL_SIDES);
            llSetLinkAlpha(lProbeZG, 0, ALL_SIDES);

            //  Hide the child cube and its legend
            llSetLinkAlpha(lChildCube, 0, ALL_SIDES);
            llSetLinkPrimitiveParamsFast(lChildCube,
                [ PRIM_TEXT, "", <0, 0, 0>, 0 ]);

            refPos = llGetPos();                // Save reference position

            vector globalAxisSize = llList2Vector(llGetLinkPrimitiveParams(lProbeXG,
                [ PRIM_SIZE ]), 0);
            gAoff = globalAxisSize.z / 2;

            resetState();

            /*  Restore position of global axes in case they've been
                mangled by an incomplete update.  We assume they're
                all the same size.  */

            llSetLinkPrimitiveParamsFast(lProbeXG,
                [ PRIM_POS_LOCAL, globalXPos = <gAoff, 0, 0>,
                  PRIM_ROT_LOCAL, globalXRot = llEuler2Rot(<0, PI_BY_TWO, 0>) ]);
            llSetLinkPrimitiveParamsFast(lProbeYG,
                [ PRIM_POS_LOCAL, globalYPos = <0, gAoff, 0>,
                  PRIM_ROT_LOCAL, globalYRot = llEuler2Rot(<-PI_BY_TWO, 0, 0>) ]);
            llSetLinkPrimitiveParamsFast(lProbeZG,
                [ PRIM_POS_LOCAL, globalZPos = <0, 0, gAoff>,
                  PRIM_ROT_LOCAL, globalZRot = llEuler2Rot(<0, 0, 0>) ]);

            saveGlobalAxes();

            llMessageLinked(LINK_THIS, LM_SP_INIT, "", llGetOwner());
        }

        listen(integer channel, string name, key id, string message) {
            processCommand(id, message, FALSE);
        }

        //  On touch, set aim target to toucher's position

        touch_start(integer total_number) {
            key toucher = llDetectedKey(0);         // Get ID of who touched us
            whoDat = toucher;

            if (scriptSuspend) {
                scriptResume();
            } else {
                list tpos = llGetObjectDetails(toucher, [ OBJECT_POS ]);
                targetSet = llList2Vector(tpos, 0);
                llMessageLinked(LINK_THIS, LM_AX_TARGET,
                    llList2Json(JSON_ARRAY, [ targetSet ]), whoDat);
            }
        }

        //  Receipt of messages from scripts in this link set

        link_message(integer sender, integer num, string str, key id) {
//llOwnerSay("Main link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  Script Processor Messages

            //  LM_SP_READY (57): Script ready to read

            if (num == LM_SP_READY) {
                scriptActive = TRUE;
                llMessageLinked(LINK_THIS, LM_SP_GET, "", id);  // Get the first line

            //  LM_SP_INPUT (55): Next executable line from script

            } else if (num == LM_SP_INPUT) {
                if (str != "") {                // Process only if not hard EOF
                    integer stat = processCommand(id, str, TRUE); // Some commands set scriptSuspend
                    if (stat) {
                        if (!scriptSuspend) {
                            llSetTimerEvent(ncRate);        // Set timer to get next command
                        }
                    } else {
                        //  Error in script command.  Abort script input.
                        scriptActive = scriptSuspend = FALSE;
                        llMessageLinked(LINK_THIS, LM_SP_INIT, "", id);
                        tawk("Script terminated.");
                    }
                }

            //  LM_SP_EOF (56): End of file reading from script

            } else if (num == LM_SP_EOF) {
                scriptActive = FALSE;           // Mark script input complete

            //  LM_SP_ERROR (58): Error processing script request

            } else if (num == LM_SP_ERROR) {
                llRegionSayTo(id, PUBLIC_CHANNEL, "Script error: " + str);
                scriptActive = scriptSuspend = FALSE;
                llMessageLinked(LINK_THIS, LM_SP_INIT, "", id);
            }
        }

        //  The timer event is used to obtain lines from scripts and execute them

        timer() {
            if (scriptActive) {
                llMessageLinked(LINK_THIS, LM_SP_GET, "", whoDat);
            }
            llSetTimerEvent(0);
        }

    }
