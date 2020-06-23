                    Fourmilab Orientation Cube

                              User Guide

Rotation and translation of objects in Second Life are often confusing
to developers of scripts, who must deal with multiple co-ordinate
systems, concepts such as vectors, axes, Euler angles, and quaternions,
and operations such as vector products and rotation of vectors, and
composition of rotations which do not behave like arithmetic with
numbers.

Fourmilab's Orientation Cube is an object intended to aid in mastery
of these concepts.  It displays orientation in a simple and obvious way,
compatible with the nomenclature and colour code used by the editing
facilities in Second Life, and responds to commands sent on local chat
which allow experimenting with and demonstrating a wide variety of
transformations (rotations and translations [moves]) with immediate
feedback from the cube.

Co-ordinate Systems

Further complicating matters, script developers in Second Life may find
themselves working in multiple co-ordinate systems and needing to
convert among them.  The principal co-ordinate systems used by the
Orientation Cube are as follows.

    Grid co-ordinates
        The Second Life metaverse is composed of regions, each 256
        metres square, with edges aligned with the X and Y axes of the
        “grid” containing all regions.  The grid co-ordinates of the
        current region may be obtained with the llGetRegionCorner() API
        function and the grid co-ordinates of a region retrieved with
        the llRequestSimulatorData() function's DATA_SIM_POS query.
        Grid co-ordinates are usually returned multiplied by 256 so
        they may be added to co-ordinates within a region to obtain a
        grid-global address.  The Orientation Cube, like almost all
        objects within Second Life, operates entirely within a single
        region, and is unaffected by Grid co-ordinates.  The Status
        command displays the name and grid co-ordinates of the current
        region.

    Region (Global) co-ordinates
        These co-ordinates are absolute within a given region.  Regions
        in Second Life are 256 by 256 metres in size, and have absolute
        X and Y co-ordinates which in the range from 0 to 255.9999....
        The Z co-ordinate indicates altitude, and ranges from 0 to
        around 5000 metres.  Objects placed at very high altitudes may
        run into positioning problems due to truncation in Second
        Life's single-precision floating point numbers.  Grid
        co-ordinates are sometimes used to identify the location of a
        region in the world of Second Life, but as objects cannot span
        region boundaries, they may be ignored in almost all scripting
        operations.  The X, Y, and Z axes within a region are at
        uniform directions within the region and may be displayed by
        editing any object.  The axes are conventionally colour coded:
        red for X, green for Y, and blue for Z.

    Object co-ordinates
        Object co-ordinates refer to an object's native co-ordinates.
        When a new object is created with the Build tool, for example a
        cube, its local axes are aligned with those of the region, with
        their origin (zero point) at the “centre of mass” of the
        object, which is defined differently for various shapes.  Note
        that (0,0,0) in the object co-ordinate system corresponds to
        the object's location within the region, which may change if
        the object is moved.  The object's local axes initially align
        with those of the region, but if the object is rotated, they
        will be rotated with respect to those of the region.  When you
        move an object in its object co-ordinates, motion will be along
        its object axes, not those of the region.

    Link (Local) co-ordinates
        If you assemble a composite object by linking together two or
        more prims (primitive objects), the composite will have a set
        of co-ordinates defined by the position and rotation of its
        “root prim” (link number 1), which is, when linking a series of
        objects together, the last you select before performing the
        Link operation.  Operations which move and rotate prims will
        move all linked objects together, as a unit, along with their
        root prim.  Links within the composite objects (sometimes
        called “child prims”, as opposed to the root, or “parent prim”)
        may be moved or rotated independently of their parent by
        functions such as llSetLinkPrimitiveParamsFast().  These
        functions take positions relative to root prim; if you wish to
        transform them in Region co-ordinates, you must transform those
        co-ordinates into Local co-ordinates first.

When you initially create an Orientation Cube, its object axes will be
aligned with those of the Region.  If you display the Orientation
Cube's Child Cube, its axes will also be aligned with those of the
region and parent cube, but offset by <+0.75,+0.75,+0.75> metres from
its centre. You can restore this initial orientaton at any time with
the chat command “Reset”.

Chat Commands

The Orientation Cube listens, by default, for commands on local chat
channel 1707 (the birth year of mathematician Leonhard Euler).  You can
change this channel with the “Set channel” command.  Commands consist
of one or more modifiers, followed by a verb indicating what command to
perform, followed by nouns (parameters) specifying the operation
desired.  Some verbs correspond directly to Linden Scripting Language
(LSL) function names; you may optionally prefix these with "ll" to
correspond directly to the functions.  Commands and most parameters are
case-insensitive: “Rot”, “rot”, and “ROT” are equivalent.

    Modifiers

        Global
            Parameters to the following verb specify global
            co-ordinates.  For the main cube, this means region
            co-ordinates.  For the child cube, it means in the
            co-ordinate system of the root (parent) prim as opposed to
            those of the child itself.

        Region
            Parameters to the following verb specify region
            co-ordinates, relative to the position of the main cube.
            For the main cube, Region and Global are synonyms.  For the
            child cube, Global refers to co-ordinates relative to the
            root prim, while Region refers to those of the region.

        Child
            Operate on the child cube, as opposed to the main cube.

    Parameters
        Parameters follow verbs with their number and type depending
        upon the verb.  White space is ignored between parameters and
        within angle brackets denoting vectors and rotations.  The
        symbolic constants “pi” (π), “two_pi” (2π), and “pi_by_two"
        (π/2) may be specified wherever a number may appear.  You can
        specify a random angle with “Rang”, a random unit vector with
        “Rvec”, and a random position relative to the selected cube
        with “Rpos”.  Random values can be used in demonstration
        scripts to show non-repeating behaviour.  You can specify a
        random rotation as Euler angles <Rang,Rang,Rang>.

    Verbs
        Many verbs accept modifiers preceding them.  The notation [C]
        indicates the Child modifier may be used, while [G/R] indicates
        the Global or Region modifiers may be applied.  Modifiers may
        be specified in any order.

        [C] Aim [<X, Y, Z>]
            Aim the positive Y axis of the cube at the point specified
            by <X, Y, Z> in region co-ordinates or, if no point is
            given, a target previously specified by the “Target”
            command.  Because the Aim command always points at a
            location in region co-ordinates, the only modifier which
            applies to it is Child.

        [C] Axes
            Show the direction vectors of the cube's local X, Y, and Z
            axes in Region co-ordinates.

        [C] [G/R] [ll]Axes2Rot <forward> <left> <up>
            Rotate to align the local axes with the vectors specified
            for the forward (X), left (Y), and up (Z) axes.  This is
            the operation performed by the llAxes2Rot() API function.

        [C] [G/R] [ll]AxisAngle2Rot <X, Y, Z> ang
            Rotate ang around the axis specified by the vector.  This
            is the operation performed by the llAxisAngle2Rot() API
            function.

        [C] [G/R] [ll]CastRay <X, Y, Z> dist
            Use the llCastRay() API function to project a ray from the
            centre of the selected (main or child) cube in the
            direction specified by the <X, Y, Z> vector, which may be
            in any of the co-ordinate systems specified by modifiers,
            and report all (up to 50) hits on objects other than the
            Orientation Cube itself.  For each hit, the object's name,
            location in region co-ordinates, and distance is shown.  A
            hit on land shows an object name of "(Terrain)".

        Clear
            Send twelve blank lines to local chat, making a space to
            separate sections in output from demonstration and tutorial
            scripts.

        Echo message
            Display the message in local chat.  The message may be any
            number of words and in upper and lower case characters.
            This is mostly used in scripts which want to explain what
            they're doing,

        Help
            Give this notecard to the requester.

        [C] [G/R] Omega <X, Y, Z> spinrate gain
        [C] [G/R] [ll]TargetOmega <X, Y, Z> spinrate gain
            Set a local rotation of the main or child cube around the
            axis specified by the vector <X, Y, Z>, with a rotation
            rate in degrees or radians (according to “Set Angles”) per
            second multiplied by the gain. Note that the magnitudes of
            the components of the vector also determine the spin rate:
            see the documentation for the llTargetOmega() API function
            for details.  If the vector, spinrate, and gain are
            omitted, any existing rotation is cancelled.  If just a
            vector is specified, spinrate defaults to 45 degrees per
            second and gain to 1.  This “omega rotation" is performed
            locally in the viewer and occurs independently of changes
            in orientation performed by rotate commands.

        Pause [time]
            Suspend the running script for the number of seconds given
            by time.  If time is omitted, the script is paused until
            the object is touched.

        [G/R] Probe[s] [X/Y/Z] [on/off]
            Display or hide the axis orientation probe(s).  Long probes
            can be extended from the main cube to test or demonstrate
            alignment with other objects.  You can specify the axes to
            be turned on or off, or act on all axes with the “Probes”
            command.  The Global or Region modifiers select probes
            which remain aligned with the region axes.  The child cube
            has no probes.

        [C] [G/R] Qrot <X, Y, Z, S>
            Rotate to quaternion <X, Y, Z, S>.  Perform the rotation
            specified by the quaternion with the given four components.

        Reset
            Reset to the initial state.  The main and child cubes are
            returned to their original alignment with the region axes.
            Settings, such as visibility of the child cube, probes, and
            floating text legends are unaffected.

        Restart
            Restart script, restoring initial conditions.  If you
            manually move the cube with the viewer's object editor, you
            should restart the script to update its reference position
            to the new location.  Note that if you've changed the
            channel upon which the script listens with “Set channel”,
            this will restore it to the original setting of 1707.

        [C] [G/R] Rot <X, Y, Z>
        [C] [G/R] [ll]Euler2Rot <X, Y, Z>
            Rotate by Euler angles <X, Y, Z>.  A rotation is performed
            as specified by the given Euler angles.  The rotations are
            performed in the order used by the llEuler2Rot() API
            function: Z, Y, then X.

        [C] [G/R] [ll]RotBetween <X, Y, Z> <X, Y, Z>
            Rotate to align the direction specified by the first vector
            to that of the second vector.  This is the operation
            performed by the llRotBetween() API function.  This API
            function is famously quirky and prone to misbehave due to
            floating point round-off errors.  It is best avoided in
            script programming, or replaced with the more accurate
            implementation provided in the API documentation.

        [C] [G/R] RotX ang
            Rotate ang around X axis.

        [C] [G/R] RotY ang
            Rotate ang around Y axis.

        [C] [G/R] RotZ ang
            Rotate ang around Z axis.

        Script                              Commands related to scripts
            Script run [script]
                Run a script containing commands from a notecard named
                “script” in the object's inventory.  Script names,
                unlike other command parameters, are case sensitive and
                may contain spaces.  Entering the “Script run” command
                from chat with no script name cancels any running
                script.  Scripts can be nested (a Script run command
                may appear in a script).
            Script loop [n]
                Start a loop within script which will run n times.  If
                n is omitted, the loop will run until the script is
                cancelled with the “Script run” command or the object
                is restarted.  Script loops may be nested.
            Script end
                Mark the end of a loop defined by the most recent
                Script loop command.

        Set                                 Set parameter
            Set Access owner/group/public
                Restrict chat command access to public/group/owner.
                The default is owner.
            Set Angles degrees/radians
                Set angle input and display to degrees or radians:
                default degrees.
            Set Channel n
                Change the chat channel on which the object listens for
                commands: default 1707.
            Set Child on/off
                Display or hide the child cube: off by default.
            Set Echo on/off
                Set whether commands from chat or scripts are echoed to
                the sender: on by default.
            [C] Set Legend on/off
                Display or hide the floating text legend above either
                the main or child cubes.  This is on by default for the
                main cube, and off for the child cube.
            Set Runrate t
                Set scripts to execute one command every t seconds.
                Default is one command per second.

        [C] [G/R] [ll]SetPos <X, Y, Z>
        [C] [G/R] Move <X, Y, Z>
            Move in the direction specified by the vector.

        [C] [ll]SetRot <X, Y, Z>
            Set the rotation to that specified by the given Euler
            angles.  This is the operation performed by the llSetRot()
            API function.  This differs from the Rot/EulerRot command
            in that it does not compose the new rotation with the
            existing orientation of the cube but rather sets it
            directly.  Since this command sets the rotation of the root
            or child cube without regard to its current orientation,
            the only modifier which applies to it is Child.

        Status
            Show current status in local chat.

        Target <X, Y, Z> / me
            Set the target for the “Aim” command to <X, Y, Z> or me for
            the position of the avatar that sent the command.  You can
            also set the target to the position of your avatar by
            touching the object.

        Undo
            Undo the last motion (translation, rotation, or omega)
            command. State-changing commands such as “Set” or “Target”
            cannot be undone.

Scripts

Commands, identical to those submitted via chat, may be executed from
scripts stored as notecards in the Orientation Cube's inventory and
started with the “Run” command in chat.  In scripts, blank lines and
those with “#” as the first character are ignored.  Lines which begin
with a double quote character are messages which are echoed in local
chat as the script runs.  Prefixing a script command with “@” causes it
not to be echoed in local chat even if Set Echo is on. Scripts may be
nested (the “Run” command can appear in a script).  A running script
may be cancelled by entering the Run command from chat with no script
name.

License

This product (software, documents, images, and models) is licensed
under a Creative Commons Attribution-ShareAlike 4.0 International
License.
    http://creativecommons.org/licenses/by-sa/4.0/
    https://creativecommons.org/licenses/by-sa/4.0/legalcode
You are free to copy and redistribute this material in any medium or
format, and to remix, transform, and build upon the material for any
purpose, including commercially.  You must give credit, provide a link
to the license, and indicate if changes were made.  If you remix,
transform, or build upon this material, you must distribute your
contributions under the same license as the original.
