#
#       Orientation cube demonstration
#

@Reset
@Set child off
@Child Set legend off
@Set angles degrees
@Probes off
@Global Probes off
@Echo - - - - Fourmilab Orientation Cube - - -
@Echo -                  Demonstration              -
@Set runrate 2
@Pause 3
@Echo

@Echo Single axis rotations and composition of rotations

RotY -30
RotX 45
RotZ 45

@Echo @Rotations are relative to cube's current orientation

@Pause 4

@Echo Region modifier rotates in region (global) co-ordinates

script loop 2
    Region RotZ 90
    Region RotZ -90
script end
script loop 2
    Region RotY -45
    Region RotY 45
script end

@Pause 4

@Echo Move (translation) relative to cube's local axes
Global Probes on
@Echo Global probes show region axes

script loop 2
    Move <0.5, 0, 0>
    Move <-0.5, 0, 0>
script end

script loop 2
    Move <0, 0, 0.5>
    Move <0, 0, -0.5>
script end

@Pause 4

@Echo Move in region co-ordinates

script loop 2
    Region Move <0.5, 0, 0>
    Region Move <-0.5, 0, 0>
script end

script loop 2
    Region Move <0, 0, 0.5>
    Region Move <0, 0, -0.5>
script end

@Pause 4

@ Echo Commands can be undone, back to the start

Undo
Undo
Undo
Undo

@Echo Enable child cube, linked to main cube

Reset
Set child on
Child set legend on

@Pause 4

@Echo Move/rotate main cube moves/rotates child

RotZ 30
RotX 30
Region Move <0, 0, 0.5>

@Pause 4

@Echo Rotate and move child in its local co-ordinates

script loop 2
    Child RotZ 45
    Child RotX 30
    Child RotX -30
    Child RotZ -45
script end
script loop 2
    Child Move <0.25, 0, 0>
    Child Move <0, 0, -0.25>
script end
#   Make axes distinct to demonstrate Global and Region
Child RotX -50
Child RotZ 30

@Pause 4

@Echo Rotate and move child in parent co-ordinates

Script loop 2
    Child Global RotZ 45
    Child Global RotZ -45
Script end
Script loop 2
    Child Global Move <0.25, 0, 0>
    Child Global Move <-0.25, 0, 0>
Script end

@Pause 4

@Echo Rotate and move child in region co-ordinates

Script loop 2
    Child Region Rotz 45
    Child Region Rotz -45
Script end
Script loop 2
    Child Region Move <0.25, 0, 0>
    Child Region Move <-0.25, 0, 0>
Script end

@Pause 4

@Reset
@Child Set legend off
@Set child off
@Global Probes off

@Echo Many ways to specify rotations.  Let's
@Echo switch from degrees to radians.

Set angles radians
RotZ PI_BY_TWO
Axes2Rot <0,1,0> <-1,0,0> <0,0,1>
AxisAngle2Rot <0,0,1> 1.570796
Qrot <0, 0, 0.70711, 0.70711>
Rot <0, 0, PI_BY_TWO>
RotBetween <1, 0, 0> <0, 1, 0>

@Pause 4

@Echo Local (Omega) rotation

Reset
Set angles degrees
Set child on
Child Set legend on

@Echo Rotate main cube around Z axis

TargetOmega <0, 0, 1> 45 1

@Pause 3

@Echo Rotate child cube around its Y axis

Child TargetOmega <0,1,0> 30 1

@Pause 4

@Echo Display status

Status

#   Wait to allow resize chat window to show status
@Pause

Child TargetOmega
TargetOmega
Reset

@Pause 4

@Echo Aim main cube's +Y axis in random directions

Probe Y on
Script loop 3
    Aim Rpos
Script end

@Pause 3

@Echo Aim child +Y axis in random directions

Script loop 3
    Child Aim Rpos
Script end

@Pause 3

@Echo Aim main cube at avatar
@Pause 5

Target me
Aim

@Pause 3

@Echo Aim child cube at avatar

Child Aim

@Pause 4

@Echo Cast ray to find objects along +Y axis

CastRay <0, 1, 0> 10

@Pause 4

@Echo There's more!  See the Help file (send Help in chat) for details.

@Probes off
@Set child off
@Child Set legend off
@Reset
