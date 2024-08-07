!............................................................
!...                      Subroutine energy               ...
!............................................................

!
! In order to have actualized arrays. It is very convient
! that before to call this subroutine calls the POTEN
! subroutine (for delj4)  and derden (for derivadores of 
! the helium4 density)subroutines


subroutine energy()

Use Para_DerivnD
use alphasterm
use deriva
use energies
use field
use impur
use lenard4
use grid
use gridk
use he4
use rho
use util1
use work1
use constraint

implicit none

real (kind=8)              ::  aux1,aux2,aux3,aux4,aux5,zcom,ycom,xcom ! Auxiliar variables

integer (kind=4) :: ix,iy,iz,iN



!................................ Use derivatives for (grad(den))**2
!
!  icon   =  0 ! Take the derivative.
!  icon   = 20 ! Take the derivative. Use Wigner-Seitz conditions.
!  icon   =  8 ! Take the derivative. Use periodic conditions.

!call pderg(1,npd,nn,hx,psi,sto1,3,1,mmx,iw,icon)   ! derivative respect X
!call pderg(1,npd,nn,hy,psi,sto2,3,2,mmx,iw,icon)   ! derivative respect Y
!call pderg(1,npd,nn,hz,psi,sto3,3,3,mmx,iw,icon)   ! derivative respect Z

  Call derivnD(1,nn,hx,1,psi,sto1,Icon)
  Call derivnD(1,nn,hy,2,psi,sto2,Icon)
  Call derivnD(1,nn,hz,3,psi,sto3,Icon)

aux1   = 0.5d0*cp4
aux2   = (1.0d0/3.0d0)*cpp4

!..................................................................
!... Calculate the density of energy (kinetic, and correlation) ...
!..................................................................

ekin4 = 0.0d0
elj4  = 0.0d0
ecor4 = 0.0d0

eimpu = 0.0d0             
do iz=1,nz
   do iy=1,ny
      do ix=1,nx
          aux3  = den(ix,iy,iz)
          aux4  = dencg(ix,iy,iz)
          aux5  = aux3*aux4**2*(aux1+aux2*aux4)
          ekin4 = ekin4 + sto1(ix,iy,iz)**2+sto2(ix,iy,iz)**2+sto3(ix,iy,iz)**2
          elj4  = elj4  + delj4(ix,iy,iz)*aux3   
          ecor4 = ecor4 + aux5
      end do
   end do
end do

if(limp) then
!   call pderg(1,npd,nn,hx,psix,sto1,3,1,mmx,iw,icon)   ! derivative respect X
!   call pderg(1,npd,nn,hy,psix,sto2,3,2,mmx,iw,icon)   ! derivative respect Y
!   call pderg(1,npd,nn,hz,psix,sto3,3,3,mmx,iw,icon)   ! derivative respect Z

   Call derivnD(1,nn,hx,1,psix,sto1,Icon)
   Call derivnD(1,nn,hy,2,psix,sto2,Icon)
   Call derivnD(1,nn,hz,3,psix,sto3,Icon)

   eimpu = 0.0d0             
   ekinx = 0.0d0
   do iz=1,nz
      do iy=1,ny
         do ix=1,nx
          ekinx = ekinx + sto1(ix,iy,iz)**2+sto2(ix,iy,iz)**2+sto3(ix,iy,iz)**2
          eimpu = eimpu + potx4(ix,iy,iz)*den(ix,iy,iz)
         end do
      end do
   end do
ElseIf(lexternal)Then
   eimpu = 0.0d0             
   ekinx = 0.0d0
   do iz=1,nz
      do iy=1,ny
         do ix=1,nx
          eimpu = eimpu + uext(ix,iy,iz)*den(ix,iy,iz)
         end do
      end do
   end do
end if

!......................................................
!... Calculate the density of energy (alpha_s term) ...
!......................................................

select case(core4)
   case('OTE','OTC')
     ealphas = sum(falfs*( dxden*intxalf + dyden*intyalf + dzden*intzalf) )
     ealphas = -h2o2m4*0.5d0*alphas*ealphas*dxyz
   case default
     continue
end select

esolid=0.0d0
if(lsolid)esolid = C*sum(den*(1.d0+dtanh(beta*(den-den_m))))*dxyz


ekin4 = h2o2m4*ekin4*dxyz           ! TOTAL Kinetic energy for 4He
elj4  = 0.5d0 *elj4 *dxyz           ! TOTAL Lennard-Jones energy
ecor4 =        ecor4*dxyz           ! TOTAL Correlation energy for 4He
etot4 = ekin4 + elj4 + ecor4 + esolid   ! TOTAL ENERGY without impurity

 
select case(core4)
   case('OTE','OTC')
     etot4 = etot4+ealphas          ! TOTAL ENERGY including Alpha_s term
   case default
     continue
end select


eimpu = eimpu*dxyz                  ! TOTAL energy due to the impurity  Or the Potential term

if(limp) then                       ! ..... Term due to impurities
  ekinx = h2o2mx*ekinx*dxyz         ! TOTAL Kinetic energy for the impurity
  etot  = etot4 + ekinx
  eso   = 0.0d0                     ! L'energia de spin-orbita no te sentit (de moment)
Else
  Etot = Etot4
end if


etot4   =  etot4
etot    =  etot  + eimpu  + eso

If(lconstraint)Then
  If(limp)Then
    zimp = 0.d0
    do iz=1,nz
      zimp = zimp + sum(denx(:,:,iz))*z(iz)
    enddo
    zimp = zimp*dxyz
  Endif
  zcom = 0.d0
  do iz=1,nz
   zcom = zcom + sum(den(:,:,iz))*z(iz)
  enddo
  zcom = zcom*dxyz/n4real

 enercons = 0.5d0*Intens*(zimp-zcom-zdist)**2
Else
 enercons = 0.d0
Endif


If(lconstraint_y)Then
  If(limp)Then
    yimp = 0.d0
    do iy=1,ny
      yimp = yimp + sum(denx(:,iy,:))*y(iy)
    enddo
    yimp = yimp*dxyz
 
  Endif
  ycom = 0.d0
  do iy=1,ny
   ycom = ycom + sum(den(:,iy,:))*y(iy)
  enddo
  ycom = ycom*dxyz/n4real
   ! print*,'energy.f90-> ycom=',ycom,rimp(1,2),ydist(1)
  enercons=0d0
  ! do iN=1,N_imp
     enercons =enercons +0.5d0*Intens*(yimp-ycom-ydist)**2
  !   enddo

Else
 enercons = 0.d0
Endif

If(lconstraint_x)Then
  If(limp)Then
    ximp = 0.d0
    do ix=1,nx
      ximp = ximp + sum(denx(ix,:,:))*x(ix)
    enddo
    ximp = ximp*dxyz
  Endif
  xcom = 0.d0
  do ix=1,nx
   xcom = xcom + sum(den(ix,:,:))*x(ix)
  enddo
  xcom = xcom*dxyz/n4real
    
  enercons=0d0
   !do iN=1,N_imp
     enercons =enercons +0.5d0*Intens*(ximp-xcom-xdist)**2
     !enddo

Else
 enercons = 0.d0
Endif





return

end
