c ======================================================================
c                                                                      |
c                                                                      |
c     POST-PROCESS Results File (*.fil)                                |
c                                                                      |
c                                                                      |
c     Written for Abaqus 6.12-1                                        |
c                                                                      |
c                                                                      | 
c     Compile:                                                         |
c         abaqus make job=postProcess.for                              |
c     Run:                                                             |
c         abaqus postProcess                                           |
c                                                                      |
c                                                                      |
c     Created by Megan Schroeder                                       |
c     Last Modified 2014-03-12                                         |
c                                                                      |
c ======================================================================
      subroutine ABQMAIN
c     ------------------------------------------------------------------
c     The use of aba_param.inc eliminates the need to have different
c     versions of the code for single and double precision.
c     The file aba_param.inc defines an appropriate IMPLICIT REAL
c     statement and sets the value of NPRECD to 1 or 2, depending upon
c     whether the machine uses single or double precision.
      include 'aba_param.inc'
c     Root file name of results file (no extension)
      character*256 FNAME
c     To read both floating point and integer variables in the records
      dimension ARRAY(513), JRRAY(NPRECD,513)
      equivalence (ARRAY(1), JRRAY(1,1))
c     Fortran unit number of results file with binary flag
      dimension LRUNIT(2,1)
c     ------------------------------------------------------------------
      character*256    jobOutDir, jobNames(1), jobName, outputFile
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
      double precision tf_flexion_deg, tf_external_deg
      integer*4        prevKEY
c     ------------------------------------------------------------------
c     Directory and file names
      jobOutDir = 'H:/Northwestern-RIC/SVN/Working/'//
     &            'FiniteElement/Subjects/20130401CONM/'
c      do i = 1, 3
c        write(iStr,"(I1.1)") i
c        jobNames(i) = '20130401CONM_A_Walk_01__Step'//trim(iStr)
c      end do
      jobNames(1) = '20130401CONM_A_Walk_01'
c     ------------------------------------------------------------------      
      do f = 1, 1
      jobName = jobNames(f)
c     A character string defining the root file name
c     (that is, the name without an extension)
c     of the files being read or written
      FNAME = trim(jobOutDir)//'/'//trim(jobName)
c     An integer giving the number of results files
c     that the postprocessing program will read (normally 1)
      NRU = 1
c     LRUNIT(1,K1) is the FORTRAN unit number
c     on which the K1th results file will be read.
c     Valid unit numbers are 8 to read the .fil file, ...
      LRUNIT(1,1) = 8
c     LRUNIT(2,K1) is an integer that must be
c     set to 2 if the K1th results file was written as a binary file
c     or set to 1 if the K1th results file was written in ASCII format
      LRUNIT(2,1) = 2
c     Needs to be defined only if the program that is making the call
c     to INITPF will also write an output file in the Abaqus results
c     file format
      LOUTF = 0
c     Utility Routine: initialize a file
      call INITPF(FNAME,NRU,LRUNIT,LOUTF)
c     ------------------------------------------------------------------
c     Fortran unit number for the *.fil file
      JUNIT=8
c     Utility Routine: set a unit number for a file
      call DBRNU(JUNIT)
c     ------------------------------------------------------------------
c     Get file name
      outputFile = trim(FNAME)//'.out'
c     Open output file
      open(unit=105, file=outputFile, status='UNKNOWN')
      write(105,1100)
 1100 format('Time',3X,'Flexion',3X,'Adduction',3X,'External')
c     ------------------------------------------------------------------
c     Reference undeformed nodal coordinates
c     --tibia instance node number 25676 / global node number 78585
      rAnkle = (/ 1.610121965408325D+00, 6.101490020751953D+01,
     &            7.588565063476563D+01 /)
c     --tibia instance node number 67597 / global node number 82949
      rMPlateau = (/ 5.333547210693359D+01, 4.847691345214844D+01,
     &               5.456002044677734D+01 /)
c     --tibia instance node number 69023 / global node number 83348
      rLPlateau = (/ 5.776553726196289D+01, 5.868466186523438D+01,
     &               9.272709655761719D+01 /)
c     --tibia instance node number 71361 / global node number 84648
      rOrigin = (/ 6.171390914916992D+01, 6.018209075927734D+01,
     &             7.195396423339844D+01 /)
c     --femur instance node number 48092 / global node number ?
      femur_origin = (/ 8.764195251464844D+01, 6.181004714965820D+01,
     &                  6.685361480712891D+01 /)
c     --femur instance node number 1671 / global node number ?
      femur_med = (/ 7.719332885742188D+01, 7.072183990478516D+01,
     &               4.251929473876953D+01 /)
c     --femur instance node number 2 / global node number ?
      femur_lat = (/ 7.975641632080078D+01, 8.333438110351563D+01,
     &               8.377447509765625D+01 /)
c     Determine femur coordinate system vectors
      do i = 1,3
c       Assume femur z is equal to tibia z in undeformed state
        femur_z(i) = rOrigin(i)-rAnkle(i)
        femur_xtemp(i) = femur_lat(i)-femur_med(i)
      end do
      femur_y = cross_product(femur_z, femur_xtemp)
      femur_x = cross_product(femur_y, femur_z)
c     Normalize vector to unit length
      do i = 1,3
        femur_ex(i) = femur_x(i)/(norm(femur_x))
        femur_ey(i) = femur_y(i)/(norm(femur_y))
        femur_ez(i) = femur_z(i)/(norm(femur_z))
      end do
c     ------------------------------------------------------------------
c     Initialize previous record key
      prevKEY = 9999
c     Read records form the results (*.fil) file
c     Cover a maximum of 10 million records in that file
      do K100 = 1, 100
      do K1 = 1, 99999
c       Utility Routine: read from a file
c       CALL DBFILE(LOP,ARRAY,JRCD)
c       Variable to be provided to the utility routine:
c         LOP: A flag indicating the operation.
c              Set LOP=0 to read the next record in the file
c       Variables returned from the utility routine:
c         ARRAY: The array containing one record from the file
c         JRCD: Returned as nonzero if an end-of-file marker is read
c               when DBFILE is called with LOP=0.
        call DBFILE(0,ARRAY,JRCD)
c       Exit the loop if the end-of-file is reached
        if (JRCD .ne. 0) go to 1001
c       Record key
        KEY = JRRAY(1,2)
c       ----------------------------------------------------------------        
c       Increment start record
        if (KEY .eq. 2000) then
          totalTime = ARRAY(3)
          stepTime = ARRAY(4)
          stepNum = JRRAY(1,8)
c       Nodal Displacements
        else if (KEY .eq. 101) then
          nodeNum = JRRAY(1,3)
c         RP_TIBIA
          if (nodeNum .eq. 82875) then
            uOrigin(1) = ARRAY(4)
            uOrigin(2) = ARRAY(5)
            uOrigin(3) = ARRAY(6)
c         AXIS_TIBIA-ANKLE
          else if (nodeNum .eq. 76812) then
            uAnkle(1) = ARRAY(4)
            uAnkle(2) = ARRAY(5)
            uAnkle(3) = ARRAY(6)
c         AXIS_TIBIA-LPLATEAU
          else if (nodeNum .eq. 81575) then
            uLPlateau(1) = ARRAY(4)
            uLPlateau(2) = ARRAY(5)
            uLPlateau(3) = ARRAY(6)
c         AXIS_TIBIA-MPLATEAU
          else if (nodeNum .eq. 81176) then
            uMPlateau(1) = ARRAY(4)
            uMPlateau(2) = ARRAY(5)
            uMPlateau(3) = ARRAY(6)
          end if
c       ----------------------------------------------------------------          
c       Increment stop record
        else if (KEY .eq. 2001) then
c         Determine deformed nodal coordinates
          do i = 1,3
            tibia_ankle(i) = rAnkle(i)+uAnkle(i)
            tibia_med(i) = rMPlateau(i)+uMPlateau(i)
            tibia_lat(i) = rLPlateau(i)+uLPlateau(i)
            tibia_origin(i) = rOrigin(i)+uOrigin(i)
          end do
c         Establish tibia coordinate system vectors
          do i = 1,3
            tibia_z(i) = tibia_origin(i)-tibia_ankle(i)
            tibia_xtemp(i) = tibia_lat(i)-tibia_med(i)
          end do
          tibia_y = cross_product(tibia_z, tibia_xtemp)
          tibia_x = cross_product(tibia_y, tibia_z)
c         Normalize vector to unit length
          do i = 1,3
            tibia_ex(i) = tibia_x(i)/(norm(tibia_x))
            tibia_ey(i) = tibia_y(i)/(norm(tibia_y))
            tibia_ez(i) = tibia_z(i)/(norm(tibia_z))
          end do
c         Grood & Suntay coordinate system
          e1 = femur_ex
          e3 = tibia_ez
          e2 = cross_product(e3, e1)
c         Calculate knee angles
          tf_flexion_deg = asind(-1.d0*(dot_product(e2, femur_ez)))
          tf_external_deg = asind(-1.d0*(dot_product(e2, tibia_ex)))
     &                            +2.03
          tf_adduction_deg = acosd(dot_product(e1, e3))-90.d0;
c         Print to file
          if (prevKEY .ne. 1922) then
            if ((stepNum .eq. 1) .or. (stepTime .ne. 0.D0)) then
              write(105,1200) totalTime, tf_flexion_deg, 
     &                        tf_adduction_deg,  tf_external_deg
 1200         format(F5.3, F8.2, F8.2, F8.2)
            end if
          end if
        end if
c       Update previous record key
        prevKEY = KEY       
      end do
      end do
 1001 continue
      close(unit=105)
      end do
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
      end subroutine ABQMAIN
