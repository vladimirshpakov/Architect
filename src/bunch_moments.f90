!*****************************************************************************************************!
!             Copyright 2014-2016 Alberto Marocchino, Francesco Massimo                               !
!*****************************************************************************************************!

!*****************************************************************************************************!
!  This file is part of architect.                                                                    !
!                                                                                                     !
!  Architect is free software: you can redistribute it and/or modify                                  !
!  it under the terms of the GNU General Public License as published by                               !
!  the Free Software Foundation, either version 3 of the License, or                                  !
!  (at your option) any later version.                                                                !
!                                                                                                     !
!  Architect is distributed in the hope that it will be useful,                                       !
!  but WITHOUT ANY WARRANTY; without even the implied warranty of                                     !
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                                      !
!  GNU General Public License for more details.                                                       !
!                                                                                                     !
!  You should have received a copy of the GNU General Public License                                  !
!  along with architect.  If not, see <http://www.gnu.org/licenses/>.                                 !
!*****************************************************************************************************!

 module moments

 USE pstruct_data
 USE my_types
 USE use_my_types
 USE utilities
 USE random_numbers_functions
 USE shapiro_wilks

 implicit none

 !--- --- ---!
 contains
 !--- --- ---!

 FUNCTION count_particles(number_bunch,cutnocut)
 character*6, intent(in) :: cutnocut
 integer, intent(in) :: number_bunch
 integer             :: count_particles

 if ( trim(cutnocut)=="noocut" ) then
	 count_particles = SIZE( bunch(number_bunch)%part(:) )
 else if ( trim(cutnocut)=="yescut" ) then
	 count_particles = int( SUM( bunch(number_bunch)%part(:)%cmp(8) ) ) ! uses dcut parameter, computed in apply_Sigma_cut routine
 endif

 END FUNCTION count_particles


 !--- --- ---!
 real(8) FUNCTION calculate_nth_central_moment_bunch(number_bunch,nth,component)
 integer, intent(in) :: nth, component, number_bunch
 integer :: np
 real(8) :: mu_mean(1),moment(1)

 !--- mean calculation
 mu_mean  = sum( bunch(number_bunch)%part(:)%cmp(component) )
 mu_mean  = mu_mean / real( SIZE( bunch(number_bunch)%part(:) ) )

 !--- moment calculation
 moment   = sum( ( bunch(number_bunch)%part(:)%cmp(component) - mu_mean(1) )**nth )
 moment   = moment / real( SIZE( bunch(number_bunch)%part(:) ) )

 !---
 calculate_nth_central_moment_bunch = moment(1)
 END FUNCTION calculate_nth_central_moment_bunch



 !--- --- ---!
 real(8) FUNCTION calculate_nth_moment_bunch(number_bunch,nth,component)
 integer, intent(in) :: nth, component, number_bunch
 integer :: np
 real(8) :: moment(1)

 !--- moment calculation
 moment   = sum( ( bunch(number_bunch)%part(:)%cmp(component) )**nth )
 moment   = moment / real( SIZE( bunch(number_bunch)%part(:) ) )

 !---
 calculate_nth_moment_bunch = moment(1)
 END FUNCTION calculate_nth_moment_bunch




 !--- --- ---!
 real(8) FUNCTION calculate_central_correlation(number_bunch,component1,component2)
 integer, intent(in) :: number_bunch, component1, component2
 real(8) :: mu_component1(1),mu_component2(1)
 real(8) :: corr

 mu_component1(1) = calculate_nth_moment_bunch(number_bunch,1,component1)
 mu_component2(1) = calculate_nth_moment_bunch(number_bunch,1,component2)

 corr = &
		sum(       &
			(bunch(number_bunch)%part(:)%cmp(component1)-mu_component1(1)) &
          * (bunch(number_bunch)%part(:)%cmp(component2)-mu_component2(1)) )
 corr = corr / real ( count_particles(number_bunch,"noocut") )

 calculate_central_correlation = corr
 END FUNCTION calculate_central_correlation





 !--- --- ---!
 SUBROUTINE bunch_integrated_diagnostics(number_bunch)
 integer, intent(in) :: number_bunch
 real(8) :: mu_x(1),mu_y(1),mu_z(1)          !spatial meam
 real(8) :: mu_px(1),mu_py(1),mu_pz(1)       !momenta mean
 real(8) :: s_x(1),s_y(1),s_z(1)                         !spatial variance
 real(8) :: s_px(1),s_py(1), s_pz(1)                      !momenta variance
 real(8) :: m4_x(1),m4_y(1),m4_z(1),m4_px(1),m4_py(1),m4_pz(1) !4th central moments for kurtosis
 real(8) :: mu_gamma(1),s_gamma(1),dgamma_su_gamma(1)     !gamma mean-variance
 real(8) :: corr_y_py(1),corr_z_pz(1),corr_x_px(1) !correlation transverse plane
 real(8) :: emittance_x(1),emittance_y(1) !emittance variables
 character(1) :: b2str
 character*90 :: filename
 TYPE(simul_param) :: sim_par


	mu_x(1)  = calculate_nth_moment_bunch(number_bunch,1,1)
	mu_y(1)  = calculate_nth_moment_bunch(number_bunch,1,2)
	mu_z(1)  = calculate_nth_moment_bunch(number_bunch,1,3)
	mu_px(1) = calculate_nth_moment_bunch(number_bunch,1,4)
	mu_py(1) = calculate_nth_moment_bunch(number_bunch,1,5)
	mu_pz(1) = calculate_nth_moment_bunch(number_bunch,1,6)

	s_x(1)  = sqrt( calculate_nth_central_moment_bunch(number_bunch,2,1) )
	s_y(1)  = sqrt( calculate_nth_central_moment_bunch(number_bunch,2,2) )
	s_z(1)  = sqrt( calculate_nth_central_moment_bunch(number_bunch,2,3) )
	s_px(1) = sqrt( calculate_nth_central_moment_bunch(number_bunch,2,4) )
	s_py(1) = sqrt( calculate_nth_central_moment_bunch(number_bunch,2,5) )
	s_pz(1) = sqrt( calculate_nth_central_moment_bunch(number_bunch,2,6) )

  m4_x(1)  = calculate_nth_central_moment_bunch(number_bunch,4,1)
	m4_y(1)  = calculate_nth_central_moment_bunch(number_bunch,4,2)
	m4_z(1)  = calculate_nth_central_moment_bunch(number_bunch,4,3)
	m4_px(1) = calculate_nth_central_moment_bunch(number_bunch,4,4)
	m4_py(1) = calculate_nth_central_moment_bunch(number_bunch,4,5)
	m4_pz(1) = calculate_nth_central_moment_bunch(number_bunch,4,6)

	corr_x_px(1) = calculate_central_correlation(number_bunch,1,4)
	corr_y_py(1) = calculate_central_correlation(number_bunch,2,5)
	corr_z_pz(1) = calculate_central_correlation(number_bunch,3,6)

    !---!
	mu_gamma = &
		sum(  sqrt(   1.0 + bunch(number_bunch)%part(:)%cmp(4)**2 + &
		                    bunch(number_bunch)%part(:)%cmp(5)**2 + &
		                    bunch(number_bunch)%part(:)%cmp(6)**2 ) )
	mu_gamma = mu_gamma / real ( count_particles(number_bunch,"noocut") )

	s_gamma = &
		sum( (sqrt(   1.0 + bunch(number_bunch)%part(:)%cmp(4)**2 + &
		                    bunch(number_bunch)%part(:)%cmp(5)**2 + &
		                    bunch(number_bunch)%part(:)%cmp(6)**2 ) - &
		                    mu_gamma(1) )**2 )
	s_gamma = sqrt( s_gamma/ real ( count_particles(number_bunch,"noocut") ) )

	dgamma_su_gamma = s_gamma(1)/mu_gamma(1)

	!---!
	emittance_x = sqrt( s_x(1)**2 *s_px(1)**2 - corr_x_px(1)**2 )
	emittance_y = sqrt( s_y(1)**2 *s_py(1)**2 - corr_y_py(1)**2 )


  write(b2str,'(I1.1)') number_bunch
  filename=TRIM(sim_parameters%path_integrated_diagnostics)//'bunch_integrated_quantity_'//b2str//'.dat'
  call open_file(OSys%macwin,filename)
  !1  2   3   4   5    6    7     8      9      10     11      12      13     14    15    16     17       18       19       20
  !t,<X>,<Y>,<Z>,<Px>,<Py>,<Pz>,<rmsX>,<rmsY>,<rmsZ>,<rmsPx>,<rmsPy>,<rmsPz>,<Emx>,<Emy>,<Gam>,DGam/Gam,cov<xPx>,cov<yPy>,cov<zPz>
  write(11,'(100e14.5)') sim_parameters%sim_time*c,mu_x,mu_y,mu_z,mu_px,mu_py,mu_pz,s_x,s_y,s_z,s_px,s_py, &
   s_pz,emittance_x,emittance_y,mu_gamma,dgamma_su_gamma,corr_x_px,corr_y_py,corr_z_pz
  close(11)

  filename=TRIM(sim_parameters%path_integrated_diagnostics)//'kurtosis_'//b2str//'.dat'
  call open_file(OSys%macwin,filename)
  !1,  2,  3,  4,   5,   6,   7
  !t,K_x,K_y,K_z,K_px,K_py,K_pz
  write(11,'(100e14.5)') sim_parameters%sim_time*c, &
                         m4_x/s_x**4-3.D0,   m4_y/s_y**4-3.D0,   m4_z/s_z**4-3.D0, &
                         m4_px/s_px**4-3.D0, m4_py/s_py**4-3.D0, m4_pz/s_pz**4-3.D0
  close(11)

 END SUBROUTINE


 !-------------------------------------!
 !----- albz's slice diagnostics ------!
 !---- for Architect begins here ------!
 !-------------------------------------!


 !--- --- ---!
 SUBROUTINE bunch_sliced_diagnostics(bunch_number)
 integer, intent(in) 	:: bunch_number
 real(8) :: avgz,sigmaz
 real(8) :: mu_x(1),       mu_y(1),       mu_z(1)          !spatial mean
 real(8) :: mu_px(1),       mu_py(1),       mu_pz(1)       !momenta mean
 real(8) :: s_x(1), s_y(1), s_z(1)                         !spatial variance
 real(8) :: s_px(1), s_py(1), s_pz(1)                      !momenta variance
 real(8) :: mu_gamma(1)                 !gamma mean
 real(8) :: s_gamma(1)                   !gamma variance
 real(8) :: corr_y_py(1), corr_z_pz(1), corr_x_px(1) !correlation transverse plane
 real(8) :: emittance_y(1), emittance_x(1) !emittance variables
 real(8) :: nSigmaCut
 integer :: ip,nInside,islice,np_local
 logical, allocatable :: bunch_mask(:)
 character(1) :: b2str,s2str
 character*90 :: filename
 !---!
 np_local=size(bunch(bunch_number)%part(:))

 !---- bunch_mask Calculation ---------!
 allocate (bunch_mask(np_local))

 !--- bunch position and variance
 avgz=calculate_nth_moment_bunch(bunch_number,1,3)
 sigmaz=sqrt(calculate_nth_central_moment_bunch(bunch_number,2,3))

 !---  -5sigma   -4sigma   -3sigma   -2sigma  -1sigma     0sigma   +1sigma   +2sigma    +3sigma   +4sigma   +5sigma
 !---  | slice 0  |    1     |    2    |     3   |     4    |    5    |     6   |     7    |   8    |     9    |   ----!
 do islice=0,9 ! change string format in output file for more than 9 slices

  nSigmaCut = 5.0
  nInside=0
  do ip=1,np_local
   bunch_mask(ip)=( (bunch(bunch_number)%part(ip)%cmp(3)- avgz ) >( real(islice)-nSigmaCut)*sigmaz  ) &
    .and.( (bunch(bunch_number)%part(ip)%cmp(3)- avgz ) <(real(islice+1)-nSigmaCut)*sigmaz )
   if (bunch_mask(ip)) nInside=nInside+1
  enddo

  !--- mean calculation ---!
  !--- SUM(x, bunch_mask=MOD(x, 2)==1)   odd elements, sum = 9 ---!
  mu_x(1)   = sum( bunch(bunch_number)%part(1:np_local)%cmp(1), MASK=bunch_mask(1:np_local) ) / real(nInside)
  mu_y(1)   = sum( bunch(bunch_number)%part(1:np_local)%cmp(2), MASK=bunch_mask(1:np_local) ) / real(nInside)
  mu_z(1)   = sum( bunch(bunch_number)%part(1:np_local)%cmp(3), MASK=bunch_mask(1:np_local) ) / real(nInside)
  mu_px(1)  = sum( bunch(bunch_number)%part(1:np_local)%cmp(4), MASK=bunch_mask(1:np_local) ) / real(nInside)
  mu_py(1)  = sum( bunch(bunch_number)%part(1:np_local)%cmp(5), MASK=bunch_mask(1:np_local) ) / real(nInside)
  mu_pz(1)  = sum( bunch(bunch_number)%part(1:np_local)%cmp(6), MASK=bunch_mask(1:np_local) ) / real(nInside)
  !---

  !--- variance calculation ---!
  s_x(1)   = sqrt( sum( ( bunch(bunch_number)%part(1:np_local)%cmp(1)-mu_x(1)  )**2, MASK=bunch_mask(1:np_local) ) / real(nInside) )
  s_y(1)   = sqrt( sum( ( bunch(bunch_number)%part(1:np_local)%cmp(2)-mu_y(1)  )**2, MASK=bunch_mask(1:np_local) ) / real(nInside) )
  s_z(1)   = sqrt( sum( ( bunch(bunch_number)%part(1:np_local)%cmp(3)-mu_z(1)  )**2, MASK=bunch_mask(1:np_local) ) / real(nInside) )
  s_px(1)  = sqrt( sum( ( bunch(bunch_number)%part(1:np_local)%cmp(4)-mu_px(1) )**2, MASK=bunch_mask(1:np_local) ) / real(nInside) )
  s_py(1)  = sqrt( sum( ( bunch(bunch_number)%part(1:np_local)%cmp(5)-mu_py(1) )**2, MASK=bunch_mask(1:np_local) ) / real(nInside) )
  s_pz(1)  = sqrt( sum( ( bunch(bunch_number)%part(1:np_local)%cmp(6)-mu_pz(1) )**2, MASK=bunch_mask(1:np_local) ) / real(nInside) )
  !---

  !--- gamma diagnostic calculation ---!
  mu_gamma(1)  = sum(  sqrt(   1.0 + bunch(bunch_number)%part(1:np_local)%cmp(4)**2 + &
   bunch(bunch_number)%part(1:np_local)%cmp(5)**2 + &
   bunch(bunch_number)%part(1:np_local)%cmp(6)**2 ), MASK=bunch_mask(1:np_local)  ) / real(nInside)
  !---

  !--- --- ---!
  s_gamma  = sum(  (sqrt ((1.0 + bunch(bunch_number)%part(1:np_local)%cmp(4)**2 + &
   bunch(bunch_number)%part(1:np_local)%cmp(5)**2 + &
   bunch(bunch_number)%part(1:np_local)%cmp(6)**2 )) - mu_gamma(1))**2, MASK=bunch_mask(1:np_local)  )
  !---

  !---
  s_gamma(1)  = s_gamma(1) / real(nInside)
  s_gamma(1)  = sqrt(s_gamma(1))
  s_gamma(1)  = s_gamma(1) / mu_gamma(1)
  !~s_gamma  = sqrt(s_gamma(1)-1.D0)

  !--- emittance calculation ---!
  corr_x_px(1) = sum(  (bunch(bunch_number)%part(1:np_local)%cmp(1)-mu_x(1)) &
   * (bunch(bunch_number)%part(1:np_local)%cmp(4)-mu_px(1)), MASK=bunch_mask(1:np_local)  )
  corr_y_py(1) = sum(  (bunch(bunch_number)%part(1:np_local)%cmp(2)-mu_y(1)) &
   * (bunch(bunch_number)%part(1:np_local)%cmp(5)-mu_py(1)), MASK=bunch_mask(1:np_local)  )
  corr_z_pz(1) = sum(  (bunch(bunch_number)%part(1:np_local)%cmp(3)-mu_z(1)) &
   * (bunch(bunch_number)%part(1:np_local)%cmp(6)-mu_pz(1)), MASK=bunch_mask(1:np_local)  )

  !---
  corr_x_px(1)  = corr_x_px(1) / real(nInside)
  corr_y_py(1)  = corr_y_py(1) / real(nInside)
  corr_z_pz(1)  = corr_z_pz(1) / real(nInside)
  !---
  emittance_x(1) = sqrt( s_x(1)**2 *s_px(1)**2 - corr_x_px(1)**2 )
  emittance_y(1) = sqrt( s_y(1)**2 *s_py(1)**2 - corr_y_py(1)**2 )



  !--- output ---!

  write(b2str,'(I1.1)') bunch_number
  write(s2str,'(I1.1)') islice
!  open(11,file='bunch_sliced_quantity_'//b2str//'_'//s2str//'.dat',form='formatted', position='append')
!  open(11,file=TRIM(sim_parameters%out_root)//'bunch_sliced_quantity_'//b2str//'_'//s2str//'.dat',form='formatted',position='append')
  filename=TRIM(sim_parameters%path_integrated_diagnostics)//'bunch_sliced_quantity_'//b2str//'_'//s2str//'.dat'
  call open_file(OSys%macwin,filename)
  !1  2   3   4   5    6    7     8      9      10     11      12      13     14    15    16     17       18       19       20
  !t,<X>,<Y>,<Z>,<Px>,<Py>,<Pz>,<rmsX>,<rmsY>,<rmsZ>,<rmsPx>,<rmsPy>,<rmsPz>,<Emx>,<Emy>,<Gam>,DGam/Gam,cov<xPx>,cov<yPy>,cov<zPz>
  write(11,'(100e14.5)') sim_parameters%sim_time*c,mu_x,mu_y,mu_z,mu_px,mu_py,mu_pz,s_x,s_y,s_z,s_px,s_py, &
   s_pz,emittance_x,emittance_y,mu_gamma,s_gamma,corr_x_px,corr_y_py,corr_z_pz
  close(11)


 enddo ! end loop on slices
 !--- deallocate memory ----!
 deallocate (bunch_mask)
 END SUBROUTINE bunch_sliced_diagnostics

 ! --------------------------!
 ! DIAGNOSTICS WITH DCUT
 ! --------------------------!


 !--- --- ---!
 real(8) FUNCTION calculate_nth_central_moment_bunch_dcut(number_bunch,nth,component)
 integer, intent(in) :: nth, component, number_bunch
 integer :: np
 real(8) :: mu_mean(1),moment(1)
 !real :: calculate_nth_central_moment_bunch_dcut

 !--- mean calculation
 mu_mean  = sum( bunch(number_bunch)%part(:)%cmp(component)*bunch(number_bunch)%part(:)%cmp(8) )
 mu_mean  = mu_mean / real( count_particles(number_bunch,"yescut") )

 !--- moment calculation
 moment   = sum( ( bunch(number_bunch)%part(:)%cmp(component)*bunch(number_bunch)%part(:)%cmp(8) - mu_mean(1) )**nth )
 moment   = moment / real( count_particles(number_bunch,"yescut") )

 !---
 calculate_nth_central_moment_bunch_dcut = moment(1)
 END FUNCTION calculate_nth_central_moment_bunch_dcut



 !--- --- ---!
 real(8) FUNCTION calculate_nth_moment_bunch_dcut(number_bunch,nth,component)
 integer, intent(in) :: nth, component, number_bunch
 integer :: np
 real(8) :: moment(1)
 !real :: calculate_nth_moment_bunch_dcut

 !--- moment calculation
 moment   = sum( ( bunch(number_bunch)%part(:)%cmp(component)*bunch(number_bunch)%part(:)%cmp(8) )**nth )
 moment   = moment / real( count_particles(number_bunch,"yescut") )

 !---
 calculate_nth_moment_bunch_dcut = moment(1)
 END FUNCTION calculate_nth_moment_bunch_dcut




 !--- --- ---!
 real(8) FUNCTION calculate_central_correlation_dcut(number_bunch,component1,component2)
 integer, intent(in) :: number_bunch, component1, component2
 real(8) :: mu_component1(1),mu_component2(1)
 real(8) :: corr!, calculate_central_correlation_dcut

 mu_component1(1) = calculate_nth_moment_bunch_dcut(number_bunch,1,component1)
 mu_component2(1) = calculate_nth_moment_bunch_dcut(number_bunch,1,component2)

 corr = &
		sum(       &
			(bunch(number_bunch)%part(:)%cmp(component1)*bunch(number_bunch)%part(:)%cmp(8) -mu_component1(1)) &
          * (bunch(number_bunch)%part(:)%cmp(component2)*bunch(number_bunch)%part(:)%cmp(8) -mu_component2(1)) )
 corr = corr / real ( count_particles(number_bunch,"yescut") )

 calculate_central_correlation_dcut = corr
 END FUNCTION calculate_central_correlation_dcut





 !--- --- ---!
 SUBROUTINE bunch_integrated_diagnostics_dcut(number_bunch)
 integer, intent(in) :: number_bunch
 real(8) :: mu_x(1),mu_y(1),mu_z(1)          !spatial meam
 real(8) :: mu_px(1),mu_py(1),mu_pz(1)       !momenta mean
 real(8) :: s_x(1),s_y(1),s_z(1)                         !spatial variance
 real(8) :: s_px(1),s_py(1), s_pz(1)                      !momenta variance
 real(8) :: m4_x(1),m4_y(1),m4_z(1),m4_px(1),m4_py(1),m4_pz(1) !4th central moments for kurtosis
 real(8) :: mu_gamma(1),s_gamma(1),dgamma_su_gamma(1)     !gamma mean-variance
 real(8) :: corr_y_py(1),corr_z_pz(1),corr_x_px(1) !correlation transverse plane
 real(8) :: emittance_x(1),emittance_y(1) !emittance variables
 character(1) :: b2str
 character*90 :: filename
 TYPE(simul_param) :: sim_par


	mu_x(1)  = calculate_nth_moment_bunch_dcut(number_bunch,1,1)
	mu_y(1)  = calculate_nth_moment_bunch_dcut(number_bunch,1,2)
	mu_z(1)  = calculate_nth_moment_bunch_dcut(number_bunch,1,3)
	mu_px(1) = calculate_nth_moment_bunch_dcut(number_bunch,1,4)
	mu_py(1) = calculate_nth_moment_bunch_dcut(number_bunch,1,5)
	mu_pz(1) = calculate_nth_moment_bunch_dcut(number_bunch,1,6)

	s_x(1)  = sqrt( calculate_nth_central_moment_bunch_dcut(number_bunch,2,1) )
	s_y(1)  = sqrt( calculate_nth_central_moment_bunch_dcut(number_bunch,2,2) )
	s_z(1)  = sqrt( calculate_nth_central_moment_bunch_dcut(number_bunch,2,3) )
	s_px(1) = sqrt( calculate_nth_central_moment_bunch_dcut(number_bunch,2,4) )
	s_py(1) = sqrt( calculate_nth_central_moment_bunch_dcut(number_bunch,2,5) )
	s_pz(1) = sqrt( calculate_nth_central_moment_bunch_dcut(number_bunch,2,6) )

  m4_x(1)  = calculate_nth_central_moment_bunch_dcut(number_bunch,4,1)
	m4_y(1)  = calculate_nth_central_moment_bunch_dcut(number_bunch,4,2)
	m4_z(1)  = calculate_nth_central_moment_bunch_dcut(number_bunch,4,3)
	m4_px(1) = calculate_nth_central_moment_bunch_dcut(number_bunch,4,4)
	m4_py(1) = calculate_nth_central_moment_bunch_dcut(number_bunch,4,5)
	m4_pz(1) = calculate_nth_central_moment_bunch_dcut(number_bunch,4,6)

	corr_x_px(1) = calculate_central_correlation_dcut(number_bunch,1,4)
	corr_y_py(1) = calculate_central_correlation_dcut(number_bunch,2,5)
	corr_z_pz(1) = calculate_central_correlation_dcut(number_bunch,3,6)

    !---!
	mu_gamma = &
		sum(  sqrt(   1.0 + (bunch(number_bunch)%part(:)%cmp(4)*bunch(number_bunch)%part(:)%cmp(8))**2 + &
		                    (bunch(number_bunch)%part(:)%cmp(5)*bunch(number_bunch)%part(:)%cmp(8))**2 + &
		                    (bunch(number_bunch)%part(:)%cmp(6)*bunch(number_bunch)%part(:)%cmp(8))**2 ) )
	mu_gamma = mu_gamma / real ( count_particles(number_bunch,"yescut") )

	s_gamma = &
		sum( (sqrt(   1.0 + (bunch(number_bunch)%part(:)%cmp(4)*bunch(number_bunch)%part(:)%cmp(8))**2 + &
		                    (bunch(number_bunch)%part(:)%cmp(5)*bunch(number_bunch)%part(:)%cmp(8))**2 + &
		                    (bunch(number_bunch)%part(:)%cmp(6)*bunch(number_bunch)%part(:)%cmp(8))**2 ) - &
		                    mu_gamma(1) )**2 )
	s_gamma = sqrt( s_gamma/ real ( count_particles(number_bunch,"yescut") ) )

	dgamma_su_gamma = s_gamma(1)/mu_gamma(1)

	!---!
	emittance_x = sqrt( s_x(1)**2 *s_px(1)**2 - corr_x_px(1)**2 )
	emittance_y = sqrt( s_y(1)**2 *s_py(1)**2 - corr_y_py(1)**2 )


  write(b2str,'(I1.1)') number_bunch
  filename=TRIM(sim_parameters%path_integrated_diagnostics)//'bunch_integrated_quantity_'//b2str//'_dcut.dat'
  call open_file(OSys%macwin,filename)
  !1  2   3   4   5    6    7     8      9      10     11      12      13     14    15    16     17       18       19       20
  !t,<X>,<Y>,<Z>,<Px>,<Py>,<Pz>,<rmsX>,<rmsY>,<rmsZ>,<rmsPx>,<rmsPy>,<rmsPz>,<Emx>,<Emy>,<Gam>,DGam/Gam,cov<xPx>,cov<yPy>,cov<zPz>
  write(11,'(100e14.5)') sim_parameters%sim_time*c,mu_x,mu_y,mu_z,mu_px,mu_py,mu_pz,s_x,s_y,s_z,s_px,s_py, &
   s_pz,emittance_x,emittance_y,mu_gamma,dgamma_su_gamma,corr_x_px,corr_y_py,corr_z_pz
  close(11)

  filename=TRIM(sim_parameters%path_integrated_diagnostics)//'kurtosis_'//b2str//'_dcut.dat'
  call open_file(OSys%macwin,filename)
  !1,  2,  3,  4,   5,   6,   7
  !t,K_x,K_y,K_z,K_px,K_py,K_pz
  write(11,'(100e14.5)') sim_parameters%sim_time*c, &
                         m4_x/s_x**4-3.D0,   m4_y/s_y**4-3.D0,   m4_z/s_z**4-3.D0, &
                         m4_px/s_px**4-3.D0, m4_py/s_py**4-3.D0, m4_pz/s_pz**4-3.D0
  close(11)
 END SUBROUTINE


 !-------------------------------------!
 !----- albz's slice diagnostics ------!
 !---- for Architect begins here ------!
 !-------------------------------------!


 !--- --- ---!
 SUBROUTINE bunch_sliced_diagnostics_dcut(bunch_number,avgz,sigmaz)
 integer, intent(in) 	:: bunch_number
 integer			   	:: np_local,np
 real(8), intent(in) 		:: avgz,sigmaz
 real(8) :: mu_x(1),       mu_y(1),       mu_z(1)          !spatial mean
 real(8) :: mu_px(1),       mu_py(1),       mu_pz(1)       !momenta mean
 real(8) :: s_x(1), s_y(1), s_z(1)                         !spatial variance
 real(8) :: s_px(1), s_py(1), s_pz(1)                      !momenta variance
 real(8) :: mu_gamma(1)                 !gamma mean
 real(8) :: s_gamma(1)                   !gamma variance
 real(8) :: corr_y_py(1), corr_z_pz(1), corr_x_px(1) !correlation transverse plane
 real(8) :: emittance_y(1), emittance_x(1) !emittance variables
 real(8) :: nSigmaCut
 integer :: ip,nInside_loc,islice
 logical, allocatable :: bunch_mask(:)
 character(1) :: b2str,s2str
 character*90 :: filename

 !---!
 np_local=count_particles(bunch_number,"noocut")

 !---- bunch_mask Calculation ---------!
 allocate (bunch_mask(np_local))

 !---  -5sigma   -4sigma   -3sigma   -2sigma  -1sigma     0sigma   +1sigma   +2sigma    +3sigma   +4sigma   +5sigma
 !---  | slice 0  |    1     |    2    |     3   |     4    |    5    |     6   |     7    |   8    |     9    |   ----!

 do islice=0,9 ! change string format in output file for more than 9 slices

  nSigmaCut = 5.0
  nInside_loc=0
  do ip=1,np_local
   bunch_mask(ip)=( (bunch(bunch_number)%part(ip)%cmp(3) - avgz ) >( real(islice)-nSigmaCut)*sigmaz  ) &
      .and. ( (bunch(bunch_number)%part(ip)%cmp(3) - avgz ) <(real(islice+1)-nSigmaCut)*sigmaz )
   if (bunch_mask(ip)) nInside_loc=nInside_loc+1
  enddo

  !--- mean calculation ---!
  !--- SUM(x, bunch_mask=MOD(x, 2)==1)   odd elements, sum = 9 ---!
  mu_x(1)   = sum( bunch(bunch_number)%part(1:np_local)%cmp(1), MASK=bunch_mask(1:np_local) )
  mu_y(1)   = sum( bunch(bunch_number)%part(1:np_local)%cmp(2), MASK=bunch_mask(1:np_local) )
  mu_z(1)   = sum( bunch(bunch_number)%part(1:np_local)%cmp(3), MASK=bunch_mask(1:np_local) )
  mu_px(1)  = sum( bunch(bunch_number)%part(1:np_local)%cmp(4), MASK=bunch_mask(1:np_local) )
  mu_py(1)  = sum( bunch(bunch_number)%part(1:np_local)%cmp(5), MASK=bunch_mask(1:np_local) )
  mu_pz(1)  = sum( bunch(bunch_number)%part(1:np_local)%cmp(6), MASK=bunch_mask(1:np_local) )
  !---

  np=0
  do ip=1,np_local
		if ( bunch_mask(ip) ) np=np+1
  enddo

  !---
  mu_x(1)  = mu_x(1) / real(np)
  mu_y(1)  = mu_y(1) / real(np)
  mu_z(1)  = mu_z(1) / real(np)
  mu_px(1) = mu_px(1) / real(np)
  mu_py(1) = mu_py(1) / real(np)
  mu_pz(1) = mu_pz(1) / real(np)

  !--- variance calculation ---!
  s_x(1)   = sum( ( bunch(bunch_number)%part(1:np_local)%cmp(1)-mu_x(1)  )**2, MASK=bunch_mask(1:np_local) )
  s_y(1)   = sum( ( bunch(bunch_number)%part(1:np_local)%cmp(2)-mu_y(1)  )**2, MASK=bunch_mask(1:np_local) )
  s_z(1)   = sum( ( bunch(bunch_number)%part(1:np_local)%cmp(3)-mu_z(1)  )**2, MASK=bunch_mask(1:np_local) )
  s_px(1)  = sum( ( bunch(bunch_number)%part(1:np_local)%cmp(4)-mu_px(1) )**2, MASK=bunch_mask(1:np_local) )
  s_py(1)  = sum( ( bunch(bunch_number)%part(1:np_local)%cmp(5)-mu_py(1) )**2, MASK=bunch_mask(1:np_local) )
  s_pz(1)  = sum( ( bunch(bunch_number)%part(1:np_local)%cmp(6)-mu_pz(1) )**2, MASK=bunch_mask(1:np_local) )
  !---

  s_x(1)  = sqrt( s_x(1) / real(np)   )
  s_y(1)  = sqrt( s_y(1) / real(np)   )
  s_z(1)  = sqrt( s_z(1) / real(np)   )
  s_px(1) = sqrt( s_px(1) / real(np)  )
  s_py(1) = sqrt( s_py(1) / real(np)  )
  s_pz(1) = sqrt( s_pz(1) / real(np)  )

  !--- gamma diagnostic calculation ---!
  mu_gamma(1)  = sum(  sqrt(   1.0 + (bunch(bunch_number)%part(1:np_local)%cmp(4))**2 + &
   (bunch(bunch_number)%part(1:np_local)%cmp(5))**2 + &
   (bunch(bunch_number)%part(1:np_local)%cmp(6))**2 ), MASK=bunch_mask(1:np_local)  )
  !---

  !---
  mu_gamma(1)  = mu_gamma(1) / real(np)
  !--- --- ---!
  s_gamma  = sum(  (sqrt ((1.0 + (bunch(bunch_number)%part(1:np_local)%cmp(4))**2 + &
   (bunch(bunch_number)%part(1:np_local)%cmp(5))**2 + &
   (bunch(bunch_number)%part(1:np_local)%cmp(6))**2 )) - mu_gamma(1))**2, MASK=bunch_mask(1:np_local)  )
  !---

  !---
  s_gamma(1)  = s_gamma(1) / real(np)
  s_gamma(1)  = sqrt(s_gamma(1))
  s_gamma(1)  = s_gamma(1) / mu_gamma(1)
  !~s_gamma  = sqrt(s_gamma(1)-1.D0)

  !--- emittance calculation ---!
  corr_x_px(1) = sum(  (bunch(bunch_number)%part(1:np_local)%cmp(1)-mu_x(1)) &
   * (bunch(bunch_number)%part(1:np_local)%cmp(4)-mu_px(1)), MASK=bunch_mask(1:np_local)  )
  corr_y_py(1) = sum(  (bunch(bunch_number)%part(1:np_local)%cmp(2)-mu_y(1)) &
   * (bunch(bunch_number)%part(1:np_local)%cmp(5)-mu_py(1)), MASK=bunch_mask(1:np_local)  )
  corr_z_pz(1) = sum(  (bunch(bunch_number)%part(1:np_local)%cmp(3)-mu_z(1)) &
   * (bunch(bunch_number)%part(1:np_local)%cmp(6)-mu_pz(1)), MASK=bunch_mask(1:np_local)  )

  !---
  corr_x_px(1)  = corr_x_px(1) / real(np)
  corr_y_py(1)  = corr_y_py(1) / real(np)
  corr_z_pz(1)  = corr_z_pz(1) / real(np)
  !---
  emittance_x(1) = sqrt( s_x(1)**2 *s_px(1)**2 - corr_x_px(1)**2 )
  emittance_y(1) = sqrt( s_y(1)**2 *s_py(1)**2 - corr_y_py(1)**2 )



  !--- output ---!

  write(b2str,'(I1.1)') bunch_number
  write(s2str,'(I1.1)') islice
  filename=TRIM(sim_parameters%path_integrated_diagnostics)//'bunch_sliced_quantity_'//b2str//'_'//s2str//'_dcut.dat'
  call open_file(OSys%macwin,filename)
  !1  2   3   4   5    6    7     8      9      10     11      12      13     14    15    16     17       18       19       20
  !t,<X>,<Y>,<Z>,<Px>,<Py>,<Pz>,<rmsX>,<rmsY>,<rmsZ>,<rmsPx>,<rmsPy>,<rmsPz>,<Emx>,<Emy>,<Gam>,DGam/Gam,cov<xPx>,cov<yPy>,cov<zPz>
  write(11,'(100e14.5)') sim_parameters%sim_time*c,mu_x,mu_y,mu_z,mu_px,mu_py,mu_pz,s_x,s_y,s_z,s_px,s_py, &
   s_pz,emittance_x,emittance_y,mu_gamma,s_gamma,corr_x_px,corr_y_py,corr_z_pz
  close(11)
 enddo ! end loop on slices
 !--- deallocate memory ----!
 deallocate (bunch_mask)
 END SUBROUTINE bunch_sliced_diagnostics_dcut



 !--- --- ---!
 end module moments
 !--- --- ---!
