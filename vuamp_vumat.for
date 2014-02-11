c ***********************************************************************
c
c         VUAMP - User Subroutine for Amplitudes (Abaqus/Explicit)
c
c   Created by Megan Schroeder
c   Last Modified 2014-02-11
c ***********************************************************************
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
c     -------------------------------------------------------------------
      character*256  jobOutDir, jobName, outputFile
      integer*4  lenJobOutDir, lenJobName
      parameter (pi=4.d0*ATAN(1.d0))
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
      double precision knee_flexion_deg, tHalfStep
      character*3  iStr, startStr, stopStr
      integer wUnits(10), wUnit, incNum, stepNum
      double precision startAngles(10), stopAngles(10)
      double precision startAngle, stopAngle
c ***********************************************************************
      lFlagsDefine(iComputeDeriv)    = 1
      lFlagsDefine(iComputeSecDeriv) = 1
c ***********************************************************************
c     SENSORS (Nodal Displacements)
c ***********************************************************************
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
c ***********************************************************************
c     KNEE FLEXION ANGLE
c ***********************************************************************
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
c       femur z is equal to tibia z in undeformed state
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
c     set up function variables
      incNum = lFlagsInfo(iInitialization)
      stepNum = lFlagsInfo(ikStep)
      curStepTime = time(iStepTime)
      curTotalTime = time(iTotalTime)
c ***********************************************************************
c     Amplitude: SEMIMEMBRANOSUS_WRAP
c ***********************************************************************
      if (ampName .eq. 'SEMIMEMBRANOSUS_WRAP') then
        ampValueNew = getAmpValueNew(ampName, knee_flexion_deg,
     &                       -10.d0, 25.d0, 105, incNum, stepNum,
     &                       curStepTime, curTotalTime, ampValueOld)
c ***********************************************************************
c     Amplitude: SEMIMEMBRANOSUS
c ***********************************************************************
      else if (ampName .eq. 'SEMIMEMBRANOSUS') then
        ampValueNew = getAmpValueNew(ampName, knee_flexion_deg,
     &                       25.d0, 120.d0, 106, incNum, stepNum,
     &                       curStepTime, curTotalTime, ampValueOld)
c ***********************************************************************
c     Amplitude: SEMITENDINOSUS_WRAP
c ***********************************************************************
      else if (ampName .eq. 'SEMITENDINOSUS_WRAP') then
        ampValueNew = getAmpValueNew(ampName, knee_flexion_deg,
     &                       -10.d0, 25.d0, 107, incNum, stepNum,
     &                       curStepTime, curTotalTime, ampValueOld)
c ***********************************************************************
c     Amplitude: SEMITENDINOSUS
c ***********************************************************************
      else if (ampName .eq. 'SEMITENDINOSUS') then
        ampValueNew = getAmpValueNew(ampName, knee_flexion_deg,
     &                       25.d0, 120.d0, 108, incNum, stepNum,
     &                       curStepTime, curTotalTime, ampValueOld)     
c ***********************************************************************
c     Amplitude: MGASTROCNEMIUS_WRAP
c ***********************************************************************
      else if (ampName(1:19) .eq. 'MGASTROCNEMIUS_WRAP') then
        startAngles = (/ -10.d0, 5.d0, 10.d0, 15.d0, 20.d0, 25.d0,
     &                   30.d0, 35.d0, 40.d0, 45.d0 /)
        stopAngles = (/ 5.d0, 10.d0, 15.d0, 20.d0, 25.d0, 30.d0, 35.d0,
     &                  40.d0, 45.d0, 50.d0 /)
        wUnits = (/ (I, I = 109, 118) /)
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
            ampValueNew = getAmpValueNew(ampName, knee_flexion_deg,
     &                         startAngle, stopAngle, wUnit, incNum, 
     &                         stepNum, curStepTime, curTotalTime, 
     &                         ampValueOld)
          end if
        end do
c ***********************************************************************
c     Amplitude: MGASTROCNEMIUS
c ***********************************************************************
      else if (ampName .eq. 'MGASTROCNEMIUS') then
        ampValueNew = getAmpValueNew(ampName, knee_flexion_deg,
     &                       50.d0, 120.d0, 119, incNum, stepNum,
     &                       curStepTime, curTotalTime, ampValueOld)        
c ***********************************************************************
c     Amplitude: LGASTROCNEMIUS_WRAP
c ***********************************************************************
      else if (ampName(1:19) .eq. 'LGASTROCNEMIUS_WRAP') then
        startAngles = (/ -10.d0, 5.d0, 10.d0, 15.d0, 20.d0, 25.d0,
     &                   30.d0, 35.d0, 40.d0, 45.d0 /)
        stopAngles = (/ 5.d0, 10.d0, 15.d0, 20.d0, 25.d0, 30.d0, 35.d0,
     &                  40.d0, 45.d0, 50.d0 /)
        wUnits = (/ (I, I = 120, 129) /)
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
            ampValueNew = getAmpValueNew(ampName, knee_flexion_deg,
     &                         startAngle, stopAngle, wUnit, incNum, 
     &                         stepNum, curStepTime, curTotalTime, 
     &                         ampValueOld)
          end if
        end do
c ***********************************************************************
c     Amplitude: LGASTROCNEMIUS
c ***********************************************************************
      else if (ampName .eq. 'LGASTROCNEMIUS') then
        ampValueNew = getAmpValueNew(ampName, knee_flexion_deg,
     &                       50.d0, 120.d0, 130, incNum, stepNum,
     &                       curStepTime, curTotalTime, ampValueOld)
c     *******************************************************************    
      end if
c ***********************************************************************
      return
c ***********************************************************************
c     FUNCTION DEFINITIONS
c ***********************************************************************
      contains
c       *****************************************************************
        function cross_product(a, b)
          double precision cross_product(3)
          double precision a(3), b(3)
          cross_product(1) = a(2)*b(3) - a(3)*b(2)
          cross_product(2) = a(3)*b(1) - a(1)*b(3)
          cross_product(3) = a(1)*b(2) - a(2)*b(1)
        end function cross_product
c       *****************************************************************
        function norm(a)
          double precision norm
          double precision a(3)
          norm = sqrt(a(1)**2 + a(2)**2 + a(3)**2)
        end function norm
c       *****************************************************************
        function getAmpValueNew(ampName, kneeFlexAngle, startAngle,
     &                          stopAngle, wUnit, incNum, stepNum,
     &                          curStepTime, curTotalTime, ampValueOld)
          real              getAmpValueNew
          double precision  kneeFlexAngle, startAngle, stopAngle
          real              curStepTime, curTotalTime, ampValueOld
          integer*4         wUnit, incNum, stepNum
          character*80      ampName
c         first time increment
          if ((incNum .eq. 1) .and. (stepNum .eq. 1)) then
            getAmpValueNew = ampValueOld
c           \/---------------------------------------------------------\/
            if (.TRUE.) then
              call vgetjobname(jobName, lenJobName)
              call vgetoutdir(jobOutDir, lenJobOutDir)
              outputFile = jobOutDir(1:lenJobOutDir) //'/'//
     &              jobName(1:lenJobName)//'_'//trim(ampName)//'.out'
              open(unit=wUnit, file=outputFile, status='UNKNOWN')
              write(wUnit,'(:,10A16)') 'time','kneeFlex','ampValue'
            end if
c           /\---------------------------------------------------------/\
c         later time increments
          else
            tStep = props(1)
            if ((kneeFlexAngle .ge. startAngle) .and.
     &          (kneeFlexAngle .lt. stopAngle)) then
              getAmpValueNew = curStepTime/tStep
            else
              getAmpValueNew = 0.0
            end if
c           \/---------------------------------------------------------\/
            if (.TRUE.) then
              write(wUnit,'(EN16.4, :,10F16.6)')
     &              curTotalTime, kneeFlexAngle, getAmpValueNew
            end if
c           /\---------------------------------------------------------/\
          end if
        end function
c ***********************************************************************
      end subroutine vuamp



c #######################################################################
c #######################################################################
c #######################################################################



****************************************************************
*    VUMAT for neo hookean with initial stretch
*    -C10 and D1 are material parameters for neo hookean model
*    -strech is a parameter for initial stretch
*
*    Tae-Hyun Kwon(01/2010), SMPP Lab in RIC
****************************************************************
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
