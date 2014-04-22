c ======================================================================
c                                                                      |
c                                                                      |
c     VUAMP - User Subroutine to Specify Amplitudes                    |
c                       (Abaqus/Explicit)                              |
c                                                                      |
c                                                                      |
c     Written for Abaqus 6.12-1                                        |
c                                                                      |
c     Created by Megan Schroeder                                       |
c     Last Modified 2014-03-07                                         |
c                                                                      |
c ======================================================================
c     user amplitude subroutine
      subroutine vuamp(
c          passed in for information and state variables
     &     ampName, time, ampValueOld, dt, nprops, props, nSvars, svars,
     &     lFlagsInfo, nSensor, sensorValues, sensorNames,
     &     jSensorLookUpTable,
c          to be defined
     &     ampValueNew,
     &     lFlagsDefine,
     &     AmpDerivative, AmpSecDerivative, AmpIncIntegral)
      include 'vaba_param.inc'
c     time indices
      parameter (iStepTime        = 1,
     &           iTotalTime       = 2,
     &           nTime            = 2)
c     flags passed in for information
      parameter (iInitialization   = 1,
     &           iRegularInc       = 2,
     &           ikStep            = 3,
     &           nFlagsInfo        = 3)
c     optional flags to be defined
      parameter (iComputeDeriv     = 1,
     &           iComputeSecDeriv  = 2,
     &           iComputeInteg     = 3,
     &           iStopAnalysis     = 4,
     &           iConcludeStep     = 5,
     &           nFlagsDefine      = 5)
      dimension time(nTime), lFlagsInfo(nFlagsInfo),
     &          lFlagsDefine(nFlagsDefine), sensorValues(nSensor),
     &          props(nprops), sVars(nSvars)
      character*80 sensorNames(nSensor)
      character*80 ampName
      dimension jSensorLookUpTable(*)
c     ------------------------------------------------------------------
      character*256    jobOutDir, jobName, outputFile
      integer*4        lenJobOutDir, lenJobName
      double precision uAnkle(3), uMPlateau(3), uLPlateau(3), uOrigin(3)
      double precision rAnkle(3), rMPlateau(3), rLPlateau(3), rOrigin(3)
      double precision tibia_origin(3), tibia_med(3), tibia_lat(3)
      double precision tibia_ankle(3)
      double precision tibia_x(3),tibia_xtemp(3),tibia_y(3),tibia_z(3)
      double precision tibia_ex(3), tibia_ey(3), tibia_ez(3)
      double precision femur_origin(3), femur_med(3), femur_lat(3)
      double precision femur_x(3),femur_xtemp(3),femur_y(3),femur_z(3)
      double precision femur_ex(3), femur_ey(3), femur_ez(3)
      double precision e1(3), e2(3), e3(3)
      double precision knee_flexion_deg
      character*3      iStr, startStr, stopStr
      integer          isInitial, stepNum, numSteps
      integer          lowFrameNum, highFrameNum
      integer          wUnits(10), wUnit
      double precision stepTime, frameTime
      double precision ampFrameValues(1:6,0:20), ampIncValue, eta
      double precision amp3FrameValues(1:6,0:20,1:3)
      double precision amp3IncValue_local(3), amp3IncValue_global(3)
      double precision curTime_step, curTime_total
      double precision lowFrameTime_total, highFrameTime_total
      double precision startAngles(10), stopAngles(10)
      double precision startAngle, stopAngle
      double precision localToGlobal(3,3)
c **********************************************************************
      lFlagsDefine(iComputeDeriv)    = 1
      lFlagsDefine(iComputeSecDeriv) = 1
c **********************************************************************
c     PROPERTIES (Step Time, Amplitude Magnitudes)
c **********************************************************************
c     time for one step
      stepTime = props(1)
c     time for one frame (20 frames per step)
      frameTime = stepTime/20.d0
c     properties are different for ground reactions
      if (ampName(1:6) .eq. 'KNEEJC') then
c       total number of steps in the simulation, based on the number of
c       properties in the user amplitude
        numSteps = (nprops-4)/(3*20)+1
c       amplitude for starting and ending frames in step 1
        do i = 1,3
          amp3FrameValues(1,0,i) = 0.d0
          amp3FrameValues(1,20,i) = props(i+1)
        end do
c       amplitude for all frames in steps 2 to end
        m = 5
        do i = 2,numSteps
          do k = 1,3
            amp3FrameValues(i,0,k) = amp3FrameValues((i-1),20,k)
          end do
          do j = 1,20
            do k = 1,3
              amp3FrameValues(i,j,k) = props(m)
              m = m+1
            end do
          end do
        end do
c     properties for muscles
      else
c       total number of steps in the simulation, based on the number of
c       properties in the user amplitude
        numSteps = (nprops-2)/20+1
c       amplitude for starting and ending frames in step 1
        ampFrameValues(1,0) = 0.d0
        ampFrameValues(1,20) = props(2)
c       amplitude for all frames in steps 2 to end
        k = 3
        do i = 2,numSteps
          ampFrameValues(i,0) = ampFrameValues((i-1),20)
          do j = 1,20
            ampFrameValues(i,j) = props(k)
            k = k+1
          end do
        end do
      end if
c **********************************************************************
c     CURRENT TIME INCREMENT
c **********************************************************************
c     flag equals 1 if called from initialization phase of each step
      isInitial = lFlagsInfo(iInitialization)
c     step number
      stepNum = lFlagsInfo(ikStep)
c     current value of step time
      curTime_step = time(iStepTime)
c     current value of total time
      curTime_total = time(iTotalTime)
c     previous frame of step for current time increment (lower bound)
      lowFrameNum = int(floor(curTime_step/frameTime))
c     next frame of step for current time increment (upper bound)
      highFrameNum = int(ceiling(curTime_step/frameTime))
c     previous frame time (out of total time)
      lowFrameTime_total = (stepNum-1)*stepTime+lowFrameNum*frameTime
c     next frame time (out of total time)
      highFrameTime_total = (stepNum-1)*stepTime+highFrameNum*frameTime
      if (ampName(1:6) .ne. 'KNEEJC') then
c       amplitude for current increment
c       (based on SMOOTH profile in Abaqus)
c       step 1
        if (stepNum .eq. 1) then
          eta = curTime_total/stepTime
          ampIncValue = ampFrameValues(1,20)*(eta**3)*
     &                (10-15*eta+6*eta**2)
c       steps 2-end, on frame increments
        else if (lowFrameNum .eq. highFrameNum) then
          ampIncValue = ampFrameValues(stepNum,lowFrameNum)
c       steps 2-end, off frame increments
        else
          eta = (curTime_total-lowFrameTime_total)/
     &          (highFrameTime_total-lowFrameTime_total)
          ampIncValue = ampFrameValues(stepNum,lowFrameNum)+
     &                  (ampFrameValues(stepNum,highFrameNum)-
     &                   ampFrameValues(stepNum,lowFrameNum))*
     &                  (eta**3)*(10-15*eta+6*eta**2)
        end if
      end if
c **********************************************************************
c     SENSORS (Nodal Displacements)
c **********************************************************************
      do i = 1,3
         write (iStr,"(I1.1)") i
         uAnkle(i) = vGetSensorValue('TIBIA_TO_ANKLE_U'//trim(iStr),
     &                               jSensorLookUpTable,
     &                               sensorValues)
         uMPlateau(i) = vGetSensorValue('TIBIA_MPLATEAU_U'//trim(iStr),
     &                                  jSensorLookUpTable,
     &                                  sensorValues)
         uLPlateau(i) = vGetSensorValue('TIBIA_LPLATEAU_U'//trim(iStr),
     &                                  jSensorLookUpTable,
     &                                  sensorValues)
         uOrigin(i) = vGetSensorValue('TIBIA_ORIGIN_U'//trim(iStr),
     &                                jSensorLookUpTable,
     &                                sensorValues)
      end do
c **********************************************************************
c     KNEE FLEXION ANGLE
c **********************************************************************
c     reference undeformed nodal coordinates
c     --node number 25676
      rAnkle = (/ 1.61012197, 61.0149002, 75.8856506 /)
c     --node number 67597
      rMPlateau = (/ 53.3354721, 48.4769135, 54.5600204 /)
c     --node number 69023
      rLPlateau = (/ 57.7655373, 58.6846619, 92.7270966 /)
c     --node number 71361
      rOrigin = (/ 61.7139091, 60.1820908, 71.9539642 /)
c     determine deformed nodal coordinates
      do i = 1,3
        tibia_ankle(i) = rAnkle(i)+uAnkle(i)
        tibia_med(i) = rMPlateau(i)+uMPlateau(i)
        tibia_lat(i) = rLPlateau(i)+uLPlateau(i)
        tibia_origin(i) = rOrigin(i)+uOrigin(i)
      end do
c     establish tibia coordinate system vectors
      do i = 1,3
        tibia_z(i) = tibia_origin(i)-tibia_ankle(i)
        tibia_xtemp(i) = tibia_lat(i)-tibia_med(i)
      end do
      tibia_y = cross_product(tibia_z, tibia_xtemp)
      tibia_x = cross_product(tibia_y, tibia_z)
c     normalize vector to unit length
      do i = 1,3
        tibia_ex(i) = tibia_x(i)/(norm(tibia_x))
        tibia_ey(i) = tibia_y(i)/(norm(tibia_y))
        tibia_ez(i) = tibia_z(i)/(norm(tibia_z))
      end do
c     femur reference nodes (no deformation because of encastre BC)
c     --node number 48092
      femur_origin = (/ 87.6419525, 61.8100471, 66.8536148 /)
c     --node number 1671
      femur_med = (/ 77.1933289, 70.7218399, 42.5192947 /)
c     --node number 2
      femur_lat = (/ 79.7564163, 83.3343811, 83.7744751 /)
c     determine femur coordinate system vectors
      do i = 1,3
c       assume femur z is equal to tibia z in undeformed state
        femur_z(i) = rOrigin(i)-rAnkle(i)
        femur_xtemp(i) = femur_lat(i)-femur_med(i)
      end do
      femur_y = cross_product(femur_z, femur_xtemp)
      femur_x = cross_product(femur_y, femur_z)
c     normalize vector to unit length
      do i = 1,3
        femur_ex(i) = femur_x(i)/(norm(femur_x))
        femur_ey(i) = femur_y(i)/(norm(femur_y))
        femur_ez(i) = femur_z(i)/(norm(femur_z))
      end do
c     Grood & Suntay coordinate system
      e1 = femur_ex
      e3 = tibia_ez
      e2 = cross_product(e3, e1)
c     calculate knee flexion angle
      knee_flexion_deg = asind(-1.d0*(dot_product(e2, femur_ez)))
c **********************************************************************
c     Amplitude: KNEEJC_**
c **********************************************************************
      if (ampName(1:6) .eq. 'KNEEJC') then
c       amplitude for current increment
c       (based on SMOOTH profile in Abaqus)
c       step 1
        if (stepNum .eq. 1) then
          eta = curTime_total/stepTime
          do i = 1,3
            amp3IncValue_local(i) = amp3FrameValues(1,20,i)*
     &                               (eta**3)*(10-15*eta+6*eta**2)
          end do
c       steps 2-end, on frame increments
        else if (lowFrameNum .eq. highFrameNum) then
          do i = 1,3
            amp3IncValue_local(i) = amp3FrameValues(
     &                                 stepNum,lowFrameNum,i)
          end do
c       steps 2-end, off frame increments
        else
          eta = (curTime_total-lowFrameTime_total)/
     &          (highFrameTime_total-lowFrameTime_total)
          do i = 1,3
            amp3IncValue_local(i) = amp3FrameValues(
     &                                   stepNum,lowFrameNum,i)+
     &                      (amp3FrameValues(stepNum,highFrameNum,i)-
     &                       amp3FrameValues(stepNum,lowFrameNum,i))*
     &                      (eta**3)*(10-15*eta+6*eta**2)
          end do
        end if
c       transformation matrix (local to global); e's in columns
        do i = 1,3
          localToGlobal(i,1) = e1(i)
          localToGlobal(i,2) = e2(i)
          localToGlobal(i,3) = e3(i)
        end do
c       convert to global coordinate system
        do i = 1,3
          amp3IncValue_global(i) =
     &           localToGlobal(i,1)*amp3IncValue_local(1)+
     &           localToGlobal(i,2)*amp3IncValue_local(2)+
     &           localToGlobal(i,3)*amp3IncValue_local(3)
        end do
c **********************************************************************
c       Amplitude: KNEEJC_UR1
c **********************************************************************
        if (ampName(8:10) .eq. 'UR1') then
          ampIncValue = amp3IncValue_global(1)
          ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                       isInitial, stepNum, curTime_total,
     &                       knee_flexion_deg, ampIncValue,
     &                       -10.d0, 120.d0, 105)
c **********************************************************************
c       Amplitude: KNEEJC_UR2
c **********************************************************************
        else if (ampName(8:10) .eq. 'UR2') then
          ampIncValue = amp3IncValue_global(2)
          ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                       isInitial, stepNum, curTime_total,
     &                       knee_flexion_deg, ampIncValue,
     &                       -10.d0, 120.d0, 106)
c **********************************************************************
c       Amplitude: KNEEJC_UR3
c **********************************************************************
        else if (ampName(8:10) .eq. 'UR3') then
          ampIncValue = amp3IncValue_global(3)
          ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                       isInitial, stepNum, curTime_total,
     &                       knee_flexion_deg, ampIncValue,
     &                       -10.d0, 120.d0, 107)        
c **********************************************************************
c       Amplitude: KNEEJC_F1
c **********************************************************************
        else if (ampName(8:9) .eq. 'F1') then
          ampIncValue = amp3IncValue_global(1)
          ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                       isInitial, stepNum, curTime_total,
     &                       knee_flexion_deg, ampIncValue,
     &                       -10.d0, 120.d0, 108)
c **********************************************************************
c       Amplitude: KNEEJC_F2
c **********************************************************************
        else if (ampName(8:9) .eq. 'F2') then
          ampIncValue = amp3IncValue_global(2)
          ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                       isInitial, stepNum, curTime_total,
     &                       knee_flexion_deg, ampIncValue,
     &                       -10.d0, 120.d0, 109)
c **********************************************************************
c       Amplitude: KNEEJC_F3
c **********************************************************************
        else if (ampName(8:9) .eq. 'F3') then
          ampIncValue = amp3IncValue_global(3)
          ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                       isInitial, stepNum, curTime_total,
     &                       knee_flexion_deg, ampIncValue,
     &                       -10.d0, 120.d0, 115)
c **********************************************************************
c       Amplitude: KNEEJC_M1
c **********************************************************************
        else if (ampName(8:9) .eq. 'M1') then
          ampIncValue = amp3IncValue_global(1)
          ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                       isInitial, stepNum, curTime_total,
     &                       knee_flexion_deg, ampIncValue,
     &                       -10.d0, 120.d0, 116)
c **********************************************************************
c       Amplitude: KNEEJC_M2
c **********************************************************************
        else if (ampName(8:9) .eq. 'M2') then
          ampIncValue = amp3IncValue_global(2)
          ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                       isInitial, stepNum, curTime_total,
     &                       knee_flexion_deg, ampIncValue,
     &                       -10.d0, 120.d0, 117)
c **********************************************************************
c       Amplitude: KNEEJC_M3
c **********************************************************************
        else if (ampName(8:9) .eq. 'M3') then
          ampIncValue = amp3IncValue_global(3)
          ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                       isInitial, stepNum, curTime_total,
     &                       knee_flexion_deg, ampIncValue,
     &                       -10.d0, 120.d0, 118)
        end if
c **********************************************************************
c     Amplitude: SEMIMEMBRANOSUS_WRAP
c **********************************************************************
      else if (ampName .eq. 'SEMIMEMBRANOSUS_WRAP') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, -10.d0, 25.d0, 119)
c **********************************************************************
c     Amplitude: SEMIMEMBRANOSUS
c **********************************************************************
      else if (ampName .eq. 'SEMIMEMBRANOSUS') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, 25.d0, 120.d0, 125)
c **********************************************************************
c     Amplitude: SEMITENDINOSUS_WRAP
c **********************************************************************
      else if (ampName .eq. 'SEMITENDINOSUS_WRAP') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, -10.d0, 25.d0, 126)
c **********************************************************************
c     Amplitude: SEMITENDINOSUS
c **********************************************************************
      else if (ampName .eq. 'SEMITENDINOSUS') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, 25.d0, 120.d0, 127)
c **********************************************************************
c     Amplitude: MGASTROCNEMIUS_WRAP
c **********************************************************************
      else if (ampName(1:19) .eq. 'MGASTROCNEMIUS_WRAP') then
        startAngles = (/ -10.d0, 5.d0, 10.d0, 15.d0, 20.d0, 25.d0,
     &                   30.d0, 35.d0, 40.d0, 45.d0 /)
        stopAngles = (/ 5.d0, 10.d0, 15.d0, 20.d0, 25.d0, 30.d0, 35.d0,
     &                  40.d0, 45.d0, 50.d0 /)
        wUnits = (/ 128, 129, 135, 136, 137, 138, 139, 145, 146, 147 /)
        do i = 1,10
          startAngle = startAngles(i)
          stopAngle = stopAngles(i)
          wUnit = wUnits(i)
          if (startAngle .eq. -10.d0) then
            startStr = '0'
          else if (startAngle .lt. 10.d0) then
            write(startStr,"(I1.1)") int(startAngle)
          else
            write(startStr,"(I2.2)") int(startAngle)
          end if
          if (stopAngle .lt. 10.d0) then
            write(stopStr,"(I1.1)") int(stopAngle)
          else
            write(stopStr,"(I2.2)") int(stopAngle)
          end if
          if (ampName .eq. 'MGASTROCNEMIUS_WRAP_'//trim(startStr)//
     &                     '-'//trim(stopStr)) then
            ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                        isInitial, stepNum, curTime_total,
     &                        knee_flexion_deg, ampIncValue,
     &                        startAngle, stopAngle, wUnit)
          end if
        end do
c **********************************************************************
c     Amplitude: MGASTROCNEMIUS
c **********************************************************************
      else if (ampName .eq. 'MGASTROCNEMIUS') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, 50.d0, 120.d0, 148)
c **********************************************************************
c     Amplitude: LGASTROCNEMIUS_WRAP
c **********************************************************************
      else if (ampName(1:19) .eq. 'LGASTROCNEMIUS_WRAP') then
        startAngles = (/ -10.d0, 5.d0, 10.d0, 15.d0, 20.d0, 25.d0,
     &                   30.d0, 35.d0, 40.d0, 45.d0 /)
        stopAngles = (/ 5.d0, 10.d0, 15.d0, 20.d0, 25.d0, 30.d0, 35.d0,
     &                  40.d0, 45.d0, 50.d0 /)
        wUnits = (/ 149, 155, 156, 157, 158, 159, 165, 166, 167, 168 /)
        do i = 1,10
          startAngle = startAngles(i)
          stopAngle = stopAngles(i)
          wUnit = wUnits(i)
          if (startAngle .eq. -10.d0) then
            startStr = '0'
          else if (startAngle .lt. 10.d0) then
            write(startStr,"(I1.1)") int(startAngle)
          else
            write(startStr,"(I2.2)") int(startAngle)
          end if
          if (stopAngle .lt. 10.d0) then
            write(stopStr,"(I1.1)") int(stopAngle)
          else
            write(stopStr,"(I2.2)") int(stopAngle)
          end if
          if (ampName .eq. 'LGASTROCNEMIUS_WRAP_'//trim(startStr)//
     &                     '-'//trim(stopStr)) then
            ampValueNew = getAmpValueNew(ampName, ampValueOld,
     &                        isInitial, stepNum, curTime_total,
     &                        knee_flexion_deg, ampIncValue,
     &                        startAngle, stopAngle, wUnit)
          end if
        end do
c **********************************************************************
c     Amplitude: LGASTROCNEMIUS
c **********************************************************************
      else if (ampName .eq. 'LGASTROCNEMIUS') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, 50.d0, 120.d0, 169)
c **********************************************************************
c     Amplitude: VASTUSMED
c **********************************************************************
      else if (ampName .eq. 'VASTUSMED') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, -10.d0, 120.d0, 175)
c **********************************************************************
c     Amplitude: VASTUSLAT
c **********************************************************************
      else if (ampName .eq. 'VASTUSLAT') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, -10.d0, 120.d0, 176)
c **********************************************************************
c     Amplitude: VASTUSINT
c **********************************************************************
      else if (ampName .eq. 'VASTUSINT') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, -10.d0, 120.d0, 177)
c **********************************************************************
c     Amplitude: RECTUSFEM
c **********************************************************************
      else if (ampName .eq. 'RECTUSFEM') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, -10.d0, 120.d0, 178)
c **********************************************************************
c     Amplitude: BICEPSFEMORISLH
c **********************************************************************
      else if (ampName .eq. 'BICEPSFEMORISLH') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, -10.d0, 120.d0, 179)
c **********************************************************************
c     Amplitude: BICEPSFEMORISSH
c **********************************************************************
      else if (ampName .eq. 'BICEPSFEMORISSH') then
        ampValueNew = getAmpValueNew(ampName, ampValueOld, isInitial,
     &                       stepNum, curTime_total, knee_flexion_deg,
     &                       ampIncValue, -10.d0, 120.d0, 185)
c     ******************************************************************
      end if
c **********************************************************************
      return
c ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c     FUNCTION DEFINITIONS
c ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
c ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      contains
c **********************************************************************
c       CROSS_PRODUCT
c **********************************************************************
        function cross_product(a, b)
c         --------------------------------------------------------------
          double precision cross_product(3)
          double precision a(3), b(3)
c         --------------------------------------------------------------
          cross_product(1) = a(2)*b(3) - a(3)*b(2)
          cross_product(2) = a(3)*b(1) - a(1)*b(3)
          cross_product(3) = a(1)*b(2) - a(2)*b(1)
c         --------------------------------------------------------------
        end function cross_product
c **********************************************************************
c       NORM
c **********************************************************************
        function norm(a)
c         --------------------------------------------------------------
          double precision norm
          double precision a(3)
c         --------------------------------------------------------------
          norm = sqrt(a(1)**2 + a(2)**2 + a(3)**2)
c         --------------------------------------------------------------
        end function norm
c **********************************************************************
c       GETAMPVALUENEW
c **********************************************************************
        function getAmpValueNew(ampName, ampValueOld, isInitial,
     &                          stepNum, curTime_total,
     &                          knee_flexion_deg, ampIncValue,
     &                          startAngle, stopAngle, wUnit)
c         --------------------------------------------------------------
          real              getAmpValueNew
          character*80      ampName
          real              ampValueOld
          integer*4         isInitial, stepNum, wUnit
          double precision  curTime_total
          double precision  knee_flexion_deg, ampIncValue
          double precision  startAngle, stopAngle
c         --------------------------------------------------------------
c         first time increment
          if ((stepNum .eq. 1) .and. (isInitial .eq. 1)) then
            getAmpValueNew = ampValueOld
ccc           set up log file
cc            if (.TRUE.) then
cc              call vgetjobname(jobName, lenJobName)
cc              call vgetoutdir(jobOutDir, lenJobOutDir)
cc              outputFile = jobOutDir(1:lenJobOutDir) //'/'//
cc     &              jobName(1:lenJobName)//'_'//trim(ampName)//'.out'
cc              open(unit=wUnit, file=outputFile, status='UNKNOWN')
cc              write(wUnit,'(:,10A16)') 'time','kneeFlex','ampValue'
cc            end if
c         later time increments
          else
            if ((knee_flexion_deg .ge. startAngle) .and.
     &          (knee_flexion_deg .lt. stopAngle)) then
              getAmpValueNew = ampIncValue
            else
              getAmpValueNew = 0.d0
            end if
          end if
ccc         write outcomes to log file
cc          if (.TRUE.) then
cc            write(wUnit,'(EN16.4,:,10F16.6)')
cc     &            curTime_total, knee_flexion_deg, getAmpValueNew
cc          end if
c         --------------------------------------------------------------
        end function
c **********************************************************************
      end subroutine vuamp



c ######################################################################
c ######################################################################
c ######################################################################


c ======================================================================
c                                                                      |
c                                                                      |
c     VUMAT - User Subroutine to Define Material Behavior              |
c                        (Abaqus/Explicit)                             |
c                                                                      |
c                                                                      |
c     Written for Abaqus 6.9EF  / tested up to Abaqus 6.12-1           |
c                                                                      |
c     Created by Tae-Hyun Kwon                                         |
c     2010-01                                                          |
c                                                                      |
c ======================================================================
*    VUMAT for neo hookean with initial stretch
*    -C10 and D1 are material parameters for neo hookean model
*    -strech is a parameter for initial stretch
************************************************************************
       subroutine vumat(
!          Read only -
     &     nblock, ndir, nshr, nstatev, nfieldv, nprops, lanneal,
     &     stepTime, totalTime, dt, cmname, coordMp, charLength,
     &     props, density, strainInc, relSpinInc,
     &     tempOld, stretchOld, defgradOld, fieldOld,
     &     stressOld, stateOld, enerInternOld, enerInelasOld,
     &     tempNew, stretchNew, defgradNew, fieldNew,
!          Write only
     &     stressNew, stateNew, enerInternNew, enerInelasNew )
!
      include 'vaba_param.inc'
      character*80 cmname
!
!     All arrays dimensioned by (*) are not used in this algorithm
!
      dimension props(nprops), density(nblock),coordMp(nblock,*)
      dimension charLength(*), strainInc(nblock,ndir+nshr)
      dimension relSpinInc(*), tempOld(*), stretchOld(*), defgradOld(*)
      dimension fieldOld(*), stressOld(nblock,ndir+nshr)
      dimension stateOld(nblock,nstatev), enerInternOld(*)
      dimension enerInelasOld(*), tempNew(*), fieldnew(*)
      dimension stretchNew(nblock,ndir+nshr)
      dimension defgradNew(nblock,ndir+2*nshr)
      dimension stressNew(nblock,ndir+nshr), stateNew(nblock,nstatev)
      dimension enerInternNew(*), enerInelasNew(*)

      double precision F(3,3),distgr(3,3),stress(6),bbar(6),n0(3),n(3)
      double precision maa(3,3), ss(3,3)
      double precision c1,d1,c2,c3,tr,stretch,I4
c
      parameter (zero=0.d0, one=1.d0, two=2.d0, three=3.d0, four=4.d0,
     &           six=6.d0)

!     user properties
!     only 7 parameters are allowed in ABAQUS input line
      c1=props(1)
      d1=props(2)
      c2=props(3)
      c3=props(4)

!     read the initial fiber orientation vector n0 for fiber n
      n0(1)=props(5)
      n0(2)=props(6)
      n0(3)=props(7)
      stretch=props(8)

!      d1=(one-two*enu)/(two*(one+enu)*c10)
!      mu = 2.d0*c10
!      emod=2.d0*mu*(1.d0+enu)
!      kappa = emod/(3.0*(1.0-2.0*enu))


!
!     if steptime equals to zero, assume the material pure isotropic elastic
!
      enu=(one-two*d1*c1)/(two*(d1*c1+one))

      if (stepTime.eq.0.0) then
         G = two*c1
         EMOD = two*(one+enu)*G
         AK = EMOD/(three*(one-two*enu))
         AL = G*(EMOD-two*G)/(three*G-EMOD)
         do k=1, nblock
            trace = strainInc(k,1) + strainInc(k,2) + strainInc(k,3)
            stressNew(k,1) = stressOld(k,1)+two*G*strainInc(k,1)+
     &                       AL*trace
            stressNew(k,2) = stressOld(k,2)+two*G*strainInc(k,2)+
     &                       AL*trace
            stressNew(k,3) = stressOld(k,3)+two*G*strainInc(k,3)+
     &                       AL*trace
            stressNew(k,4)=stressOld(k,4)+two*G*strainInc(k,4)
            stressNew(k,5)=stressOld(k,5)+two*G*strainInc(k,5)
            stressNew(k,6)=stressOld(k,6)+two*G*strainInc(k,6)
         end do

!     normal increment
      else
!
!        iteration over material points
!
         do iblock=1,nblock

!           calculate deformation gradient with intial stress
!           F0 was assumed by Weiss, F0(1,1)=stretch, F0(2,2)=1.0, F0(3,3)=1.0
!           F0 also was assumed by Pena, F0(1,1)=stretch, F0(2,2)=stretch^-0.5, F0(3,3)=stretch^-0.5

            F(1,1) = stretchNew(iblock,1)
            F(2,2) = stretchNew(iblock,2)
            F(3,3) = stretchNew(iblock,3)
            F(1,2) = stretchNew(iblock,4)
            if (nshr .eq. 1) then
               F(2,3) = 0.0
               F(1,3) = 0.0
            else
               F(2,3) = stretchNew(iblock,5)
               F(1,3) = stretchNew(iblock,6)
            end if

            F(2,1)=F(1,2)
            F(3,2)=F(2,3)
            F(3,1)=F(1,3)

!           update for initial stress
            F(1,1)=F(1,1)*stretch
            F(2,1)=F(2,1)*stretch
            F(3,1)=F(3,1)*stretch

            F(1,2)=F(1,2)*stretch**-0.5
            F(2,2)=F(2,2)*stretch**-0.5
            F(3,2)=F(3,2)*stretch**-0.5
            F(1,3)=F(1,3)*stretch**-0.5
            F(2,3)=F(2,3)*stretch**-0.5
            F(3,3)=F(3,3)*stretch**-0.5

c           JACOBIAN AND DISTORTION TENSOR at the end of the increment
            det = F(1,1)*F(2,2)*F(3,3)-F(1,2)*F(2,1)*F(3,3)

            if (nshr .eq. 3) then
               det = det + F(1,2)*F(2,3)*F(3,1) + F(1,3)*F(2,1)*F(3,2)
     &                   - F(1,3)*F(2,2)*F(3,1) - F(1,1)*F(2,3)*F(3,2)
            end if

            scale = det ** (-one/three)
            do k1 = 1, 3
               do k2 = 1, 3
                  distgr(k2,k1) = scale*F(k2,k1)
               end do
            end do

c           calculate devitoric left cauchy-green deformation tensor
            bbar(1)=distgr(1,1)**2+distgr(1,2)**2+distgr(1,3)**2
            bbar(2)=distgr(2,1)**2+distgr(2,2)**2+distgr(2,3)**2
            bbar(3)=distgr(3,1)**2+distgr(3,2)**2+distgr(3,3)**2
            bbar(4)=distgr(1,1)*distgr(2,1)+distgr(1,2)*distgr(2,2)
     &              +distgr(1,3)*distgr(2,3)
            if(nshr .eq. 3) then
               bbar(5)=distgr(2,1)*distgr(3,1)+distgr(2,2)*distgr(3,2)
     &                 +distgr(2,3)*distgr(3,3)
               bbar(6)=distgr(1,1)*distgr(3,1)+distgr(1,2)*distgr(3,2)
     &                 +distgr(1,3)*distgr(3,3)
            end if


c           calculate stress
            trbbar=(bbar(1)+bbar(2)+bbar(3))/three
            eg=two*c1/det
            ek=two/d1*(two*det-one)
            pr=two/d1*(det-one)
            do k1=1, ndir
               stress(k1)=eg*(bbar(k1)-trbbar)+pr
            end do

            do k1=ndir+1, ndir+nshr
               stress(k1)=eg*bbar(k1)
            end do

!           n=Fn0
            do i=1,3
               n(i)=zero
               do j=1,3
                  n(i)=n(i)+distgr(i,j)*n0(j)
               end do
            end do

!           n@n
            do i=1,3
               do j=1,3
                  maa(i,j)=n(i)*n(j)
               end do
            end do

            I4=maa(1,1)+maa(2,2)+maa(3,3)

!           fiber stress
            ss(1,1)=stress(1)
            ss(2,2)=stress(2)
            ss(3,3)=stress(3)
            ss(1,2)=stress(4)
            ss(2,3)=stress(5)
            ss(1,3)=stress(6)
            ss(2,1)=ss(1,2)
            ss(3,2)=ss(2,3)
            ss(3,1)=ss(1,3)

            if(I4 > one) then   !if tension, add fiber stress
               do i=1,3
                  do j=1,3
                     tr=0.d0
                     if(i .eq. j) then
                        tr=maa(1,1)+maa(2,2)+maa(3,3)
                     end if

                     ss(i,j)=ss(i,j)+two/det
     &                       *c2*(I4-one)*exp(c3*(I4-one)**2)*(maa(i,j)
     &                       -tr/three)
                  end do
               end do
            end if

            stressNew(iblock, 1) = ss(1,1)
            stressNew(iblock, 2) = ss(2,2)
            stressNew(iblock, 3) = ss(3,3)
            stressNew(iblock, 4) = ss(1,2)
            stressNew(iblock, 5) = ss(2,3)
            stressNew(iblock, 6) = ss(1,3)

         end do

      end if

      return
      end subroutine vumat
