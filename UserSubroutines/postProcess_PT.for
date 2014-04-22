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
c     Last Modified 2014-04-14                                         |
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
      character*256    jobOutDir, jobNames(10), jobName, outputFile
      character*256    subjects(3), subject
      character*3      iStr
      logical          fileExists
      double precision cycleTime
      double precision r_tibia_inf(3), r_tibia_med(3), r_tibia_lat(3)
      double precision r_tibia_origin(3) 
      double precision r_femur_origin(3),r_femur_med(3),r_femur_lat(3)
      double precision r_patella_inf(3), r_patella_sup(3)
      double precision r_patella_lat(3), r_patella_med(3)
      double precision r_patella_post(3), r_patella_ant(3)
      double precision r_patella_origin(3)
      double precision u_tibia_inf(3), u_tibia_med(3), u_tibia_lat(3)
      double precision u_tibia_origin(3)
      double precision u_patella_inf(3), u_patella_sup(3)
      double precision u_patella_lat(3), u_patella_med(3)
      double precision u_patella_post(3), u_patella_ant(3)
      double precision tibia_inf(3), tibia_med(3), tibia_lat(3)
      double precision tibia_origin(3)
      double precision patella_inf(3), patella_sup(3), patella_med(3)
      double precision patella_lat(3), patella_post(3), patella_ant(3)
      double precision patella_origin(3)
      double precision tibia_translation(3), patella_translation(3)
      double precision tibia_x(3),tibia_xtemp(3),tibia_y(3),tibia_z(3)
      double precision tibia_ex(3), tibia_ey(3), tibia_ez(3)
      double precision femur_x(3),femur_xtemp(3),femur_y(3),femur_z(3)
      double precision femur_ex(3), femur_ey(3), femur_ez(3)
      double precision patella_x(3), patella_xtemp(3), patella_y(3)
      double precision patella_z(3)
      double precision patella_ex(3), patella_ey(3), patella_ez(3)
      double precision tf_e1(3), tf_e2(3), tf_e3(3)
      double precision pf_e1(3), pf_e2(3), pf_e3(3)
      double precision tf_flexion_deg, tf_adduction_deg
      double precision tf_external_deg, pf_flexion_deg
      double precision pf_rotMed_deg, pf_tiltMed_deg
      double precision tf_lateral, tf_anterior, tf_superior
      double precision pf_lateral, pf_anterior, pf_superior
      integer*4        prevKEY, perCycle
c     ------------------------------------------------------------------
c     Subjects
      subjects(1) = '20120919APLF'
      subjects(2) = '20120920APRM'      
      subjects(3) = '20121204APRM'      
c     Loop over subjects      
      do d = 1, 3
      subject = subjects(d)
c     Directory and file names
      jobOutDir = 'H:/Northwestern-RIC/Modeling/Abaqus/'//
     &            'Subjects/'//trim(subject)//'/'
      do j = 1,5
        write (iStr,"(I1.1)") j
        jobNames(j) = trim(subject)//'_A_Walk_0'//trim(iStr)
        jobNames(j+5) = trim(subject)//'_A_SD2S_0'//trim(iStr)
      end do
c     ------------------------------------------------------------------ 
c     Loop over trials     
      do f = 1, 10
      jobName = jobNames(f)
      inquire(file=trim(jobOutDir)//'/'//trim(jobName)//'.fil', 
     &        exist=fileExists)
      if (fileExists) then
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
      outputFile = trim(FNAME)//'_KIN.data'
c     Open output file
      open(unit=105, file=outputFile, status='UNKNOWN')
      write(105,1100)
 1100 format('PerCycle',2X,'TF_Flexion',2X,'TF_Adduction',2X,
     &       'TF_External',2X,'TF_Lateral',2X,'TF_Anterior',2X,
     &       'TF_Superior',2X,'PF_Flexion',2X,'PF_RotationM',2X,
     &       'PF_TiltM',2X,'PF_Lateral',2X,'PF_Anterior',2X,
     &       'PF_Superior')
c     ------------------------------------------------------------------
c     Reference undeformed nodal coordinates
c     --tibia instance node number 25676
      r_tibia_inf = (/ 1.610121965408325D+00, 6.101490020751953D+01,
     &                 7.588565063476563D+01 /)
c     --tibia instance node number 67597
      r_tibia_med = (/ 5.333547210693359D+01, 4.847691345214844D+01,
     &                 5.456002044677734D+01 /)
c     --tibia instance node number 69023
      r_tibia_lat = (/ 5.776553726196289D+01, 5.868466186523438D+01,
     &                 9.272709655761719D+01 /)
c     --tibia instance node number 71361
      r_tibia_origin = (/ 6.171390914916992D+01, 6.018209075927734D+01,
     &                    7.195396423339844D+01 /)
c     --femur instance node number 48092
      r_femur_origin = (/ 8.764195251464844D+01, 6.181004714965820D+01,
     &                    6.685361480712891D+01 /)
c     --femur instance node number 1671
      r_femur_med = (/ 7.719332885742188D+01, 7.072183990478516D+01,
     &                 4.251929473876953D+01 /)
c     --femur instance node number 2
      r_femur_lat = (/ 7.975641632080078D+01, 8.333438110351563D+01,
     &                 8.377447509765625D+01 /)
c     --patella instance node number 4457
      r_patella_inf = (/ 7.60122299D+01, 1.23632708D+01,
     &                   8.33992157D+01 /)
c     --patella instance node number 53231
      r_patella_sup = (/ 1.14405914D+02, 1.26245155D+01, 
     &                   8.08967972D+01 /)
c     --patella instance node number 43011
      r_patella_lat = (/ 9.20576401D+01, 1.71576023D+01, 
     &                   1.01126472D+02 /)
c     --patella instance node number 53245
      r_patella_med = (/ 8.99378128D+01, 7.58192873D+00,
     &                   6.4861145D+01 /)
c     --patella instance node number 4241
      r_patella_post = (/ 9.44332962D+01, 2.09962273D+01,
     &                    7.4311058D+01 /)
c     --patella instance node number 45648
      r_patella_ant = (/ 9.75204239D+01, 2.44025111D+00,
     &                   8.42418213D+01 /)
c     Patella translation reference
      do i = 1,3
        r_patella_origin(i) = r_patella_post(i)+
     &                     0.5d0*(r_patella_ant(i)-r_patella_post(i))
      end do
c     Determine femur coordinate system vectors
      do i = 1,3
c       Assume femur z is equal to tibia z in undeformed state
        femur_z(i) = r_tibia_origin(i)-r_tibia_inf(i)
        femur_xtemp(i) = r_femur_lat(i)-r_femur_med(i)
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
          cycleTime = totalTime-0.025d0
          perCycle = int(cycleTime*1.0d3)
c       Nodal Displacements
        else if (KEY .eq. 101) then
          nodeNum = JRRAY(1,3)
c         ORIGIN_TIBIA
          if (nodeNum .eq. 82131) then
            u_tibia_origin(1) = ARRAY(4)
            u_tibia_origin(2) = ARRAY(5)
            u_tibia_origin(3) = ARRAY(6)
c         AXIS_TIBIA-ANKLE
          else if (nodeNum .eq. 80432) then
            u_tibia_inf(1) = ARRAY(4)
            u_tibia_inf(2) = ARRAY(5)
            u_tibia_inf(3) = ARRAY(6)
c         AXIS_TIBIA-LPLATEAU
          else if (nodeNum .eq. 80831) then
            u_tibia_lat(1) = ARRAY(4)
            u_tibia_lat(2) = ARRAY(5)
            u_tibia_lat(3) = ARRAY(6)
c         AXIS_TIBIA-MPLATEAU
          else if (nodeNum .eq. 81158) then
            u_tibia_med(1) = ARRAY(4)
            u_tibia_med(2) = ARRAY(5)
            u_tibia_med(3) = ARRAY(6)
c         AXIS_PATELLA-INFERIOR - node 4457
          else if (nodeNum .eq. 58451) then
            u_patella_inf(1) = ARRAY(4)
            u_patella_inf(2) = ARRAY(5)
            u_patella_inf(3) = ARRAY(6)
c         AXIS_PATELLA-SUPERIOR - node 53231
          else if (nodeNum .eq. 60686) then
            u_patella_sup(1) = ARRAY(4)
            u_patella_sup(2) = ARRAY(5)
            u_patella_sup(3) = ARRAY(6)
c         AXIS_PATELLA-LATERAL - node 43011
          else if (nodeNum .eq. 60040) then
            u_patella_lat(1) = ARRAY(4)
            u_patella_lat(2) = ARRAY(5)
            u_patella_lat(3) = ARRAY(6)
c         AXIS_PATELLA-MEDIAL - node 53245
          else if (nodeNum .eq. 60700) then
            u_patella_med(1) = ARRAY(4)
            u_patella_med(2) = ARRAY(5)
            u_patella_med(3) = ARRAY(6)
c         AXIS_PATELLA-POSTERIOR - node 4241
          else if (nodeNum .eq. 58254) then
            u_patella_post(1) = ARRAY(4)
            u_patella_post(2) = ARRAY(5)
            u_patella_post(3) = ARRAY(6)
c         AXIS_PATELLA-ANTERIOR - node 45648
          else if (nodeNum .eq. 60345) then
            u_patella_ant(1) = ARRAY(4)
            u_patella_ant(2) = ARRAY(5)
            u_patella_ant(3) = ARRAY(6)            
          end if
c       ----------------------------------------------------------------          
c       Increment stop record
        else if (KEY .eq. 2001) then
c         Determine deformed nodal coordinates
          do i = 1,3
            tibia_inf(i) = r_tibia_inf(i)+u_tibia_inf(i)
            tibia_med(i) = r_tibia_med(i)+u_tibia_med(i)
            tibia_lat(i) = r_tibia_lat(i)+u_tibia_lat(i)
            tibia_origin(i) = r_tibia_origin(i)+u_tibia_origin(i)
            patella_inf(i) = r_patella_inf(i)+u_patella_inf(i)
            patella_sup(i) = r_patella_sup(i)+u_patella_sup(i)
            patella_med(i) = r_patella_med(i)+u_patella_med(i)
            patella_lat(i) = r_patella_lat(i)+u_patella_lat(i)
            patella_post(i) = r_patella_post(i)+u_patella_post(i)
            patella_ant(i) = r_patella_ant(i)+u_patella_ant(i)
            patella_origin(i) = patella_post(i)+
     &                       0.5d0*(patella_ant(i)-patella_post(i))
          end do
c         Translation vectors
          do i = 1,3
            tibia_translation(i) = u_tibia_origin(i)
            patella_translation(i) = patella_origin(i)-
     &                               r_patella_origin(i)
          end do          
c         Establish tibia and patella coordinate system vectors
          do i = 1,3
            tibia_z(i) = tibia_origin(i)-tibia_inf(i)
            tibia_xtemp(i) = tibia_lat(i)-tibia_med(i)
            patella_z(i) = patella_sup(i)-patella_inf(i)
            patella_xtemp(i) = patella_lat(i)-patella_med(i)
          end do
          tibia_y = cross_product(tibia_z, tibia_xtemp)
          tibia_x = cross_product(tibia_y, tibia_z)
          patella_y = cross_product(patella_z, patella_xtemp)
          patella_x = cross_product(patella_y, patella_z)
c         Normalize vector to unit length
          do i = 1,3
            tibia_ex(i) = tibia_x(i)/(norm(tibia_x))
            tibia_ey(i) = tibia_y(i)/(norm(tibia_y))
            tibia_ez(i) = tibia_z(i)/(norm(tibia_z))
            patella_ex(i) = patella_x(i)/(norm(patella_x))
            patella_ey(i) = patella_y(i)/(norm(patella_y))
            patella_ez(i) = patella_z(i)/(norm(patella_z))
          end do
c         Grood & Suntay coordinate system
          tf_e1 = femur_ex
          tf_e3 = tibia_ez
          tf_e2 = cross_product(tf_e3, tf_e1)
          pf_e1 = femur_ex
          pf_e3 = patella_ez
          pf_e2 = cross_product(pf_e3, pf_e1)
c         Calculate knee angles
          tf_flexion_deg = asind(-1.d0*(dot_product(tf_e2, femur_ez)))
          tf_external_deg = asind(-1.d0*(dot_product(tf_e2, tibia_ex)))
     &                      +2.033
          tf_adduction_deg = -1.d0*(acosd(dot_product(tf_e1, tf_e3))
     &                       -90.d0)
          pf_flexion_deg = asind(-1.d0*(dot_product(pf_e2, femur_ez)))
     &                     +1.126
          pf_tiltMed_deg = asind(-1.d0*(dot_product(pf_e2, patella_ex)))
     &                     +2.192
          pf_rotMed_deg = -1.d0*(acosd(dot_product(pf_e1, pf_e3))
     &                    -90.d0)
     &                    -0.358
c         Calculate translation
          tf_lateral = dot_product(tibia_translation, tf_e1)
          tf_anterior = dot_product(tibia_translation, tf_e2)
          tf_superior = dot_product(tibia_translation, tf_e3)
          pf_lateral = dot_product(patella_translation, pf_e1)
          pf_anterior = dot_product(patella_translation, pf_e2)
          pf_superior = dot_product(patella_translation, pf_e3)
c         Print to file
          if (prevKEY .ne. 1922) then
c            if ((stepNum .eq. 1) .or. (stepTime .ne. 0.D0)) then
            if ((totalTime .ge. 0.025d0) .and. (stepTime .ne. 0.d0))
     &      then       
              write(105,1200) perCycle, tf_flexion_deg, 
     &                        tf_adduction_deg, tf_external_deg,
     &                        tf_lateral, tf_anterior, tf_superior,
     &                        pf_flexion_deg, pf_rotMed_deg,
     &                        pf_tiltMed_deg, pf_lateral, pf_anterior,
     &                        pf_superior
 1200         format(I2, F8.3, F8.3, F8.3, F8.3, F8.3, F8.3, 
     &                   F8.3, F8.3, F8.3, F8.3, F8.3, F8.3)
            end if
          end if
        end if
c       Update previous record key
        prevKEY = KEY       
      end do
      end do
 1001 continue
      close(unit=105)
      end if
      end do
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
