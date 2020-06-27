
#   Orientation Cube Regression Test

@echo Regression test

reset

@echo Aim

    probe y on
    script loop 3
        Aim Rpos
    script end
    probe y off

    set child on
    child set legend on
    script loop 3
        Child Aim Rpos
    script end

@echo Axes

    axes
    child axes

@echo Axes2Rot

    reset

    script loop 4
        #   Rotate 90 degrees CCW around Z
        axes2rot <0,1,0> <-1,0,0> <0,0,1>
    script end

    script loop 4
        child axes2rot <0,1,0> <-1,0,0> <0,0,1>
    script end
    reset

@echo AxisAngle2Rot

    axisangle2rot <0,1,1> 45
    global axisangle2rot <0,0,1> 90
    child axisangle2rot <0,1,1> 45
    global child axisangle2rot <0,0,1> 90
    region child axisangle2rot <0,0,1> 90
    reset

@echo CastRay

    castray <0,0,-1> 20
    rotx 180
    castray <0,0,1> 20
    rotx 180
    child roty 180
    child castray <0,0,1> 20
    global child castray <0,0,-1> 20
    child rotx 45
    region child castray <0,0,-1> 20
    reset

@echo Clear
    clear

@echo Move

    global probes on
    move <0.25,0.25,0.25>
    rotx 45
    move <0,0,0.1>
    region move <0,0,0.1>

    roty -30
    child move <0,0,0.2>
    global child move <0,0,0.2>
    region child move <0,0,0.2>

    global probes off
    reset

@echo Pause

    pause 2

@echo Probes

    Probe X on
    Probe YZ on
    global probe XZ on
    global probe Y on
    roty -45
    rotx 30
    probes off
    global probe xyz off
    reset

@echo Qrot

    #   Equivalent to roty -45; rotx 45
    Qrot <0.35355, -0.35355, 0.14645, 0.85355>
    child Qrot <0.35355, -0.35355, 0.14645, -0.85355>
    reset

@echo Rot

    Rot <0,-45,-45>
    child rot <0,0,45>
    child rot <0,45,0>
    child rot <30,30,30>
    reset

@echo RotBetween

    script loop 4
        llRotBetween <1,0,0> <0,-1,0>
    script end

    script loop 4
        child RotBetween <1,0,0> <0,-1,0>
    script end
    reset

@echo RotX, RotY, RotZ

    roty -45
    rotz -45
    rotx -45

    child rotx 45
    child rotz 45
    child roty 45

    global child rotx 30
    region child rotz 90
    reset

@echo Set

    set access public
    set access group
    set access owner

    set angles radians
    rotz pi_by_two
    rotz pi
    rot <0,0,pi_by_two>
    set angles degrees

    set channel 999999
    set channel 1707

    set child off
    set child on

    set echo off
    echo No ">>" echo on this command.
    set echo on

    set legend off
    child set legend off
    set legend on
    child set legend on

    reset

@echo SetRot

    SetRot <45,45,60>
    SetRot <45,45,60>
    child SetRot <0,0,90>
    child SetRot <0,0,90>
    reset

@echo Status

    Status

@echo Target

    Target me
    Probe Y on
    Aim
    script loop 3
        Target Rpos
        Aim
    script end
    Probe Y off
    script loop 3
        Target Rpos
        child Aim
    script end
    reset

@echo TargetOmega

    TargetOmega <0,0,1> 90 1
    TargetOmega
    child TargetOmega <0,0,-1>
    TargetOmega <0,0,1> 90 0.5
    child TargetOmega
    TargetOmega
    TargetOmega Rvec
    child TargetOmega Rvec
    pause 2
    child TargetOmega
    TargetOmega
    reset

@echo Undo

    move <0,0,.25>
    child move <0,0,-.25>
    roty -45
    child roty 45
    targetomega <0,0,1>
    child targetomega <0,1,0>
    script loop 6
        undo
    script end


reset

