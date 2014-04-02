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
