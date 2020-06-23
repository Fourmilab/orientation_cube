    /*

                   Fourmilab Orientation Cube
                       Auxiliary Functions

        This script exists purely to get around the 1980s nostalgia
        of a 64 Kb limit on script memory size.

    */


    key owner;                      // Owner of object
    key whoDat;                     // User with which we're interacting

    integer lChildCube;             // Child orientation cube link number

    //  Auxiliary Messages
    integer LM_AX_INIT = 10;        // Initialise
    integer LM_AX_RESET = 11;       // Reset script
    integer LM_AX_STAT = 12;        // Print status
    integer LM_AX_LEGEND = 13;      // Update floating text legend(s)
    integer LM_AX_AXES = 14;        // Show axes orientation
    integer LM_AX_TARGET = 15;      // Show target location
    integer LM_AX_CAST = 16;        // Cast ray and report objects hit

    //  Script Processor messages
    integer LM_SP_STAT = 52;        // Print status

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

    /*  tawk  --  Send a message to the interacting user in chat.
                  The recipient of the message is defined as
                  follows.  If an agent is on the pilot's seat,
                  that avatar receives the message.  Otherwise,
                  the message goes to the owner of the object.
                  In either case, if the message is being sent to
                  the owner, it is sent with llOwnerSay(), which isn't
                  subject to the region rate gag, rather than
                  llRegionSayTo().  */

    tawk(string msg) {
        key whom = owner;
        if (whoDat != NULL_KEY) {
            whom = whoDat;
        }
        if (whom == owner) {
            llOwnerSay(msg);
        } else {
            llRegionSayTo(whom, PUBLIC_CHANNEL, msg);
        }
    }

    //  ef  --  Edit floats in string to parsimonious representation

    string eff(float f) {           // Helper that takes a float argument
        return ef((string) f);
    }

    string efv(vector v) {          // Helper that takes a vector argument
        return ef((string) v);
    }

    string ef(string s) {
        integer p = llStringLength(s) - 1;

        while (p >= 0) {
            //  Ignore non-digits after numbers
            while ((p >= 0) &&
                   (llSubStringIndex("0123456789", llGetSubString(s, p, p)) < 0)) {
                p--;
            }
            //  Verify we have a sequence of digits and one decimal point
            integer o = p - 1;
            integer digits = 1;
            integer decimals = 0;
            while ((o >= 0) &&
                   (llSubStringIndex("0123456789.", llGetSubString(s, o, o)) >= 0)) {
                o--;
                if (llGetSubString(s, o, o) == ".") {
                    decimals++;
                } else {
                    digits++;
                }
            }
            if ((digits > 1) && (decimals == 1)) {
                //  Elide trailing zeroes
                while ((p >= 0) && (llGetSubString(s, p, p) == "0")) {
                    s = llDeleteSubString(s, p, p);
                    p--;
                }
                //  If we've deleted all the way to the decimal point, remove it
                if ((p >= 0) && (llGetSubString(s, p, p) == ".")) {
                    s = llDeleteSubString(s, p, p);
                    p--;
                }
                //  Done with this number.  Skip to next non digit or decimal
                while ((p >= 0) &&
                       (llSubStringIndex("0123456789.", llGetSubString(s, p, p)) >= 0)) {
                    p--;
                }
            } else {
                //  This is not a floating point number
                p = o;
            }
        }
        return s;
    }

    default {

        on_rez(integer start_param) {
            llResetScript();
        }

        state_entry() {
            owner = llGetOwner();
            lChildCube = findLinkNumber("Child Orientation Cube");
        }

        /*  The link_message() event receives commands from the client
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {
//llOwnerSay("Auxiliary link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            whoDat = id;

            //  LM_AX_INIT (10): Initialise

            if (num == LM_AX_INIT) {

            //  LM_AX_RESET (11): Reset script

            } else if (num == LM_AX_RESET) {
                llResetScript();

            //  LM_AX_STAT (12): Report status

            } else if (num == LM_AX_STAT) {
                list arg = llJson2List(str);

                float angleScale = llList2Float(arg, 0);
                vector refPos = (vector) llList2String(arg, 1);
                integer childVis = llList2Integer(arg, 2);
                integer undoStack = llList2Integer(arg, 3);
                integer smFree = llList2Integer(arg, 4);
                integer smUsed = llList2Integer(arg, 5);
                vector targetSet = (vector) llList2String(arg, 6);

                string angu = "degree";
                if (angleScale == 1) {
                    angu = "radian";
                }
                string s = "Angles: " + angu;
                vector rp = llGetRegionCorner() / 256;
                s += "\nRegion: " + llGetRegionName() + "  Grid: <" +
                    eff(rp.x) + ", " + eff(rp.y) + ">";
                s += "\nPosition: " + efv(llGetPos() - refPos);
                rotation r = llGetRot();
                s += "\nRotation: " + efv(llRot2Euler(r) / angleScale);
                list omg = llGetLinkPrimitiveParams(LINK_ROOT, [ PRIM_OMEGA ]);
                if (llVecMag(llList2Vector(omg, 0) * llList2Float(omg, 1) *
                             llList2Float(omg, 2)) != 0) {
                    s += "\nOmega: " + efv(llList2Vector(omg, 0)) + " rate " +
                        eff(llList2Float(omg, 1) / angleScale) + " gain " +
                        eff(llList2Float(omg, 2));
                }
                if (childVis) {
                    s += "\nChild position: " +
                        efv(llList2Vector(llGetLinkPrimitiveParams(lChildCube,
                            [ PRIM_POS_LOCAL ]), 0));
                    rotation chrot = llList2Rot(llGetLinkPrimitiveParams(lChildCube,
                        [ PRIM_ROT_LOCAL ]), 0);
                    s += "\nChild rotation: Local " +
                       efv(llRot2Euler(chrot) / angleScale) + " Global " +
                       efv(llRot2Euler(chrot * r) / angleScale);
                    omg = llGetLinkPrimitiveParams(lChildCube, [ PRIM_OMEGA ]);
                    if (llVecMag(llList2Vector(omg, 0) * llList2Float(omg, 1) *
                                 llList2Float(omg, 2)) != 0) {
                        s += "\nChild omega: " + efv(llList2Vector(omg, 0)) + " rate " +
                            eff(llList2Float(omg, 1) / angleScale) + " gain " +
                            eff(llList2Float(omg, 2));
                    }
                }
                if (targetSet != ZERO_VECTOR) {
                    s += "\nTarget: " + efv(targetSet);
                }
                s += "\nUndo stack: " + (string) undoStack;
                if (llGetNumberOfPrims() > llGetObjectPrimCount(llGetKey())) {
                    integer j;
                    s += "\nSeated: ";

                    for (j = llGetObjectPrimCount(llGetKey()); j < llGetNumberOfPrims(); j++) {
                        s += llGetLinkName(j + 1) + ", ";
                    }
                    s = llGetSubString(s, 0, -3);
                }
                s += "\nMain script memory.  Free: " + (string) smFree +
                      "  Used: " + (string) smUsed + " (" +
                      (string) ((integer) llRound((smUsed * 100.0) / (smUsed + smFree))) + "%)";
                integer mFree = llGetFreeMemory();
                integer mUsed = llGetUsedMemory();
                s += "\nAuxiliary script memory.  Free: " + (string) mFree +
                      "  Used: " + (string) mUsed + " (" +
                      (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)";
                tawk(s);
                //  Request status from Script Processor
                llMessageLinked(LINK_THIS, LM_SP_STAT, "", whoDat);

            //  LM_AX_LEGEND (13): Update floating text legend(s)

            } else if (num == LM_AX_LEGEND) {
                list arg = llJson2List(str);

                integer showText = llList2Integer(arg, 0);
                integer showChildText = llList2Integer(arg, 1);
                vector refPos = (vector) llList2String(arg, 2);
                float angleScale = llList2Float(arg, 3);

                if (showText) {
                    vector p = llGetPos() - refPos;
                    rotation r = llGetRot();
                    vector er = llRot2Euler(r);
                    string s =  "Rotation " + ef((string) r) + "\n" +
                                "Euler " + efv(er / angleScale) + "\n" +
                                "Position " + efv(p);
                    list omg = llGetLinkPrimitiveParams(LINK_ROOT, [ PRIM_OMEGA ]);
                    if (llVecMag(llList2Vector(omg, 0) * llList2Float(omg, 1) *
                                 llList2Float(omg, 2)) != 0) {
                        s += "\nOmega: " + efv(llList2Vector(omg, 0)) + " rate " +
                            eff(llList2Float(omg, 1) / angleScale) + " gain " +
                            eff(llList2Float(omg, 2));
                    }
                    llSetLinkPrimitiveParamsFast(LINK_THIS,
                        [ PRIM_TEXT,s, <0, 1, 0>, 1 ]);
                }
                if (showChildText) {
                    vector p = llList2Vector(llGetLinkPrimitiveParams(lChildCube,
                        [ PRIM_POS_LOCAL ]), 0);
                    rotation r = llList2Rot(llGetLinkPrimitiveParams(lChildCube,
                        [ PRIM_ROT_LOCAL ]), 0);
                    vector er = llRot2Euler(r);                 // Local rotation
                    vector ger = llRot2Euler(r * llGetRot());   // Global rotation
                    string s = "Euler local " + efv(er / angleScale) +
                               "\nEuler global " + efv(ger / angleScale) +
                               "\nPosition local " + efv(p) +
                               "\nPosition global " + efv(p + (llGetPos() - refPos));
                    list omg = llGetLinkPrimitiveParams(lChildCube, [ PRIM_OMEGA ]);
                    if (llVecMag(llList2Vector(omg, 0) * llList2Float(omg, 1) *
                                 llList2Float(omg, 2)) != 0) {
                        s += "\nOmega: " + efv(llList2Vector(omg, 0)) + " rate " +
                            eff(llList2Float(omg, 1) / angleScale) + " gain " +
                            eff(llList2Float(omg, 2));
                    }
                    llSetLinkPrimitiveParamsFast(lChildCube,
                        [ PRIM_TEXT, s, <0.75, 0.75, 0>, 1 ]);
                }

            //  LM_AX_AXES (14): Show axes orientation

            } else if (num == LM_AX_AXES) {
                list arg = llJson2List(str);

                integer child = llList2Integer(arg, 0);

                rotation r;
                if (child) {
                    r = llList2Rot(llGetLinkPrimitiveParams(lChildCube,
                                   [ PRIM_ROT_LOCAL ]), 0) * r;
                } else {
                    r = llGetRot();
                }
                vector lX = <1, 0, 0> * r;
                vector lY = <0, 1, 0> * r;
                vector lZ = <0, 0, 1> * r;
                tawk("Local axis global vector:\n" +
                     "  X " + efv(lX) + "\n" +
                     "  Y " + efv(lY) + "\n" +
                     "  Z " + efv(lZ));

            //  LM_AX_TARGET (15): Show target location

            } else if (num == LM_AX_TARGET) {
                list arg = llJson2List(str);

                vector targetSet = (vector) llList2String(arg, 0);

                tawk("Target set to " + efv(targetSet));

            //  LM_AX_CAST (16): Cast ray and report objects hit

            } else if (num == LM_AX_CAST) {
                list arg = llJson2List(str);

                integer child = llList2Integer(arg, 0);
                integer global = llList2Integer(arg, 1);
                integer region = llList2Integer(arg, 2);
                vector dir = (vector) llList2String(arg, 3);
                float dist = llList2Float(arg, 4);

                key me;
                vector pos = llGetPos();
                if (dist <= 0) {
                    dist = 10;
                }
                if (child) {
                    me = llGetLinkKey(lChildCube);
                    pos += llList2Vector(llGetLinkPrimitiveParams(lChildCube,
                                            [ PRIM_POS_LOCAL ]), 0);
                    rotation cr = llList2Rot(llGetLinkPrimitiveParams(lChildCube,
                                            [ PRIM_ROT_LOCAL ]), 0);

                    if (global) {
                        //  Direction is in parent's co-ordinates
                        dir = dir * llGetRot();
                    } else if (region) {
                        //  Direction is in region co-ordinates
                    } else {
                        //  Direction is in the child's local co-ordinates
                        dir = dir * cr * llGetRot();
                    }
                } else {
                    me = llGetKey();
                    if (!(global || region)) {
                        dir = dir * llGetRot();
                    }
                }

                list hits = llCastRay(pos, pos + (dir * dist),
                    [ RC_MAX_HITS, 50, RC_DETECT_PHANTOM, TRUE,
                      RC_DATA_FLAGS, RC_GET_ROOT_KEY ]);
                integer nhits = llList2Integer(hits, -1);
                if (nhits > 0) {
                    integer i;
                    integer hiti = 0;

                    for (i = 0; i < nhits; i++) {
                        key k = llList2Key(hits, i * 2);

                        if (k != me) {
                            string kn;
                            if (k == NULL_KEY) {
                                kn = "(Terrain)";
//                          } else if (k == me) {
//                              kn = "(Myself)";
                            } else {
                                kn = llKey2Name(k);
                            }
                            vector hitp = llList2Vector(hits, (i * 2) + 1);
                            float d = llVecDist(pos, hitp);
                            hiti++;
                            tawk((string) hiti + ". " + kn + " " +
                                efv(hitp) + " " + eff(d));
                        }
                    }
                    if (hiti == 0) {
                        tawk("Nothing hit.");
                    }
                } else if (nhits == 0) {
                    tawk("Nothing hit.");
                } else {
                    string rcerr = "Unspecified reason";
                    if (nhits == RCERR_SIM_PERF_LOW) {
                        rcerr = "Simulator performance too low";
                    } else if (nhits == RCERR_CAST_TIME_EXCEEDED) {
                        rcerr = "Maximum time exceeded";
                    }
                    tawk("Ray cast error: code " + (string) nhits + " (" +
                        rcerr + ")");
                }
            }
        }
    }
