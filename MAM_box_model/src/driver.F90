      module driver

      use shr_kind_mod, only: r8 => shr_kind_r8
      use constituents, only: pcnst, cnst_name, cnst_get_ind
      use modal_aero_data, only: ntot_amode

      implicit none

      public

      integer, parameter :: lun_outfld = 90

      integer :: mdo_gaschem, mdo_cloudchem
      integer :: mdo_gasaerexch, mdo_rename, mdo_newnuc, mdo_coag
      integer :: mopt_aero_comp, mopt_aero_load, mopt_ait_size
      integer :: mopt_h2so4_uptake
      integer :: i_cldy_sameas_clear
      integer :: iwrite3x_species_flagaa, iwrite3x_units_flagaa
      integer :: iwrite4x_heading_flagbb
      real(r8) :: xopt_cloudf

      ! in the multiple nbc/npoa code, the following are in modal_aero_data
      integer :: lptr_bca_a_amode(ntot_amode) = -999888777 
      integer :: lptr_poma_a_amode(ntot_amode) = -999888777 

      integer :: species_class(pcnst) = -1

      contains


!-------------------------------------------------------------------------------
      subroutine cambox_main

      use shr_kind_mod,            only: r8 => shr_kind_r8
      use abortutils,              only: endrun
      use cam_history,             only: ncol_for_outfld
      use cam_logfile,             only: iulog
      use ppgrid,                  only: pcols, pver
      use wv_saturation,           only: ncol_for_qsat
      use modal_aero_data,         only: ntot_amode

!     implicit none

      integer, parameter :: ncolxx = min( pcols, 10 )
      integer  :: ncol
      integer  :: nstop

      real(r8) :: deltat
      real(r8) :: t(pcols,pver)      ! Temperature in Kelvin
      real(r8) :: pmid(pcols,pver)   ! pressure at model levels (Pa)
      real(r8) :: pdel(pcols,pver)   ! pressure thickness of levels
      real(r8) :: zm(pcols,pver)     ! midpoint height above surface (m)
      real(r8) :: pblh(pcols)        ! pbl height (m)
      real(r8) :: relhum(pcols,pver) ! layer relative humidity
      real(r8) :: qv(pcols,pver)     ! layer specific humidity
      real(r8) :: cld(pcols,pver)    ! stratiform cloud fraction

      real(r8) :: q(pcols,pver,pcnst)     ! Tracer MR array
      real(r8) :: qqcw(pcols,pver,pcnst)  ! Cloudborne aerosol MR array
      real(r8) :: dgncur_a(pcols,pver,ntot_amode)
      real(r8) :: dgncur_awet(pcols,pver,ntot_amode)
      real(r8) :: qaerwat(pcols,pver,ntot_amode)
      real(r8) :: wetdens(pcols,pver,ntot_amode)

      ncol = ncolxx
      ncol_for_outfld = ncol
      ncol_for_qsat = ncol

      write(lun_outfld,'(/a,i5)') 'istep = ', -1

      iulog = 91
      write(*,'(/a)') '*** Hello from MAIN ***'

      write(*,'(/a)') '*** main calling cambox_init_basics'
      call cambox_init_basics( ncol )

      iulog = 92
      write(*,'(/a)') '*** main calling cambox_init_run'
      call cambox_init_run( &
         ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens        )

      iulog = 93
      write(*,'(/a)') '*** main calling cambox_do_run'
      call cambox_do_run( &
         ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens        )

      end subroutine cambox_main


!-------------------------------------------------------------------------------
      subroutine cambox_init_basics( ncol )

      use shr_kind_mod, only: r8 => shr_kind_r8
      use abortutils, only: endrun
      use cam_logfile, only: iulog
      use chem_mods, only: adv_mass, gas_pcnst, imozart
      use mo_tracname, only: solsym
      use ppgrid, only: pcols, pver
      use physics_buffer, only: physics_buffer_desc, pbuf_init

      use modal_aero_data, only: nbc, npoa, nsoa, nsoag
      use modal_aero_initialize_data
      use modal_aero_amicphys, only: mosaic
      use modal_aero_calcsize, only: modal_aero_calcsize_reg
      use modal_aero_wateruptake, only: modal_aero_wateruptake_reg, modal_aero_wateruptake_init

!     implicit none

      integer, intent(in) :: ncol

      integer :: l, l2
      integer :: n

      type(physics_buffer_desc), pointer :: pbuf2d(:,:)

#if ( ( defined MODAL_AERO_7MODE ) && ( defined MOSAIC_SPECIES ) )
      n = 60
#elif ( defined MODAL_AERO_7MODE ) 
      n = 42
#elif ( defined MODAL_AERO_4MODE_MOM ) 
      n = 31
#elif ( defined MODAL_AERO_4MODE ) 
      n = 28
#elif ( defined MODAL_AERO_3MODE ) 
      n = 25
#else
      call endrun( 'MODAL_AERO_3/4/4MOM/7MODE are all undefined' )
#endif
      n = n + 2*(nbc-1) + 2*(npoa-1) + 2*(nsoa-1)
      l = n - (imozart-1)


      write(*,'(/a,3i5 )') 'pcols, pver               =', pcols, pver
      write(*,'( a,3i5/)') 'pcnst, gas_pcnst, imozart =', pcnst, gas_pcnst, imozart
      if (pcnst /= gas_pcnst+imozart-1) call endrun( '*** bad pcnst aa' )
      if (pcnst /= n                  ) call endrun( '*** bad pcnst bb' )


#if ( defined MODAL_AERO_7MODE )
      if (nbc==1 .and. npoa==1 .and. nsoa==1) then

#if ( defined MOSAIC_SPECIES )
      solsym(:l) = &
      (/ 'H2O2    ','H2SO4   ','SO2     ','DMS     ','NH3     ', &
         'SOAG    ','HNO3    ','HCL     ',                       &
         'so4_a1  ','nh4_a1  ','pom_a1  ','soa_a1  ','bc_a1   ', &
         'ncl_a1  ','no3_a1  ','cl_a1   ','num_a1  ',            &
         'so4_a2  ','nh4_a2  ','soa_a2  ','ncl_a2  ','no3_a2  ', &
         'cl_a2   ','num_a2  ',                                  &
         'pom_a3  ','bc_a3   ','num_a3  ',                       &
         'ncl_a4  ','so4_a4  ','nh4_a4  ','no3_a4  ','cl_a4   ', &
         'num_a4  ',                                             &
         'dst_a5  ','so4_a5  ','nh4_a5  ','no3_a5  ','cl_a5   ', &
         'ca_a5   ','co3_a5  ','num_a5  ',                       &
         'ncl_a6  ','so4_a6  ','nh4_a6  ','no3_a6  ','cl_a6   ', &
         'num_a6  ',                                             &
         'dst_a7  ','so4_a7  ','nh4_a7  ','no3_a7  ','cl_a7   ', &
         'ca_a7   ','co3_a7  ','num_a7  '                        /)
      adv_mass(:l) = &
      (/ 34.0135994_r8, 98.0783997_r8, 64.0647964_r8, 62.1324005_r8, 17.0289402_r8, &
         12.0109997_r8, 63.0123400_r8, 36.4601000_r8,                               &
         96.0635986_r8, 18.0363407_r8, 12.0109997_r8, 12.0109997_r8, 12.0109997_r8, &
         22.9897667_r8, 62.0049400_r8, 35.4527000_r8, 1.00740004_r8,                &
         96.0635986_r8, 18.0363407_r8, 12.0109997_r8, 22.9897667_r8, 62.0049400_r8, &
         35.4527000_r8, 1.00740004_r8,                                              &
         12.0109997_r8, 12.0109997_r8, 1.00740004_r8,                               &
         22.9897667_r8, 96.0635986_r8, 18.0363407_r8, 62.0049400_r8, 35.4527000_r8, &
         1.00740004_r8,                                                             &
         135.064041_r8, 96.0635986_r8, 18.0363407_r8, 62.0049400_r8, 35.4527000_r8, &
         40.0780000_r8, 60.0092000_r8, 1.00740004_r8,                               &
         22.9897667_r8, 96.0635986_r8, 18.0363407_r8, 62.0049400_r8, 35.4527000_r8, &
         1.00740004_r8,                                                             &
         135.064041_r8, 96.0635986_r8, 18.0363407_r8, 62.0049400_r8, 35.4527000_r8, &
         40.0780000_r8, 60.0092000_r8, 1.00740004_r8                                /)
! nacl  58.4424667
! cl    35.4527000
! na    22.9897667
! hcl   36.4601000
! hno3  63.0123400
! no3   62.0049400
! ca    40.0780000
! co3   60.0092000


#else
      solsym(:l) = &
      (/ 'H2O2    ','H2SO4   ','SO2     ','DMS     ','NH3     ', &
         'SOAG    ','so4_a1  ','nh4_a1  ','pom_a1  ','soa_a1  ', &
         'bc_a1   ','ncl_a1  ','num_a1  ','so4_a2  ','nh4_a2  ', &
         'soa_a2  ','ncl_a2  ','num_a2  ','pom_a3  ','bc_a3   ', &
         'num_a3  ','ncl_a4  ','so4_a4  ','nh4_a4  ','num_a4  ', &
         'dst_a5  ','so4_a5  ','nh4_a5  ','num_a5  ','ncl_a6  ', &
         'so4_a6  ','nh4_a6  ','num_a6  ','dst_a7  ','so4_a7  ', &
         'nh4_a7  ','num_a7  ' /)
      adv_mass(:l) = &
      (/ 34.0135994_r8, 98.0783997_r8, 64.0647964_r8, 62.1324005_r8, 17.0289402_r8, &
         12.0109997_r8, 96.0635986_r8, 18.0363407_r8, 12.0109997_r8, 12.0109997_r8, &
         12.0109997_r8, 58.4424667_r8, 1.00740004_r8, 96.0635986_r8, 18.0363407_r8, &
         12.0109997_r8, 58.4424667_r8, 1.00740004_r8, 12.0109997_r8, 12.0109997_r8, &
         1.00740004_r8, 58.4424667_r8, 96.0635986_r8, 18.0363407_r8, 1.00740004_r8, &
         135.064041_r8, 96.0635986_r8, 18.0363407_r8, 1.00740004_r8, 58.4424667_r8, &
         96.0635986_r8, 18.0363407_r8, 1.00740004_r8, 135.064041_r8, 96.0635986_r8, &
         18.0363407_r8, 1.00740004_r8 /)

#endif

      else if (nbc==2 .and. npoa==2 .and. nsoa==1) then
      ! nbc=npoa=2 not fully implemented yet
      call endrun( '*** bad nbc and/or npoa and/or nsoa' )

      solsym(:l) = &
      (/ 'H2O2    ','H2SO4   ','SO2     ','DMS     ','NH3     ', &
         'SOAG    ','so4_a1  ','nh4_a1  ','poma_a1 ', &
                                          'pomb_a1 ','soa_a1  ', &
         'bca_a1  ', &
         'bcb_a1  ','ncl_a1  ','num_a1  ','so4_a2  ','nh4_a2  ', &
         'soa_a2  ','ncl_a2  ','num_a2  ','poma_a3 ','pomb_a3 ', &
                                          'bca_a3  ','bcb_a3  ', &
         'num_a3  ','ncl_a4  ','so4_a4  ','nh4_a4  ','num_a4  ', &
         'dst_a5  ','so4_a5  ','nh4_a5  ','num_a5  ','ncl_a6  ', &
         'so4_a6  ','nh4_a6  ','num_a6  ','dst_a7  ','so4_a7  ', &
         'nh4_a7  ','num_a7  ' /)
      adv_mass(:l) = &
      (/ 34.0135994_r8, 98.0783997_r8, 64.0647964_r8, 62.1324005_r8, 17.0289402_r8, &
         12.0109997_r8, 96.0635986_r8, 18.0363407_r8, 12.0109997_r8, 12.0109997_r8, 12.0109997_r8, &
         12.0109997_r8, 12.0109997_r8, 58.4424667_r8, 1.00740004_r8, 96.0635986_r8, 18.0363407_r8, &
         12.0109997_r8, 58.4424667_r8, 1.00740004_r8, 12.0109997_r8,12.0109997_r8,  12.0109997_r8, 12.0109997_r8, &
         1.00740004_r8, 58.4424667_r8, 96.0635986_r8, 18.0363407_r8, 1.00740004_r8, &
         135.064041_r8, 96.0635986_r8, 18.0363407_r8, 1.00740004_r8, 58.4424667_r8, &
         96.0635986_r8, 18.0363407_r8, 1.00740004_r8, 135.064041_r8, 96.0635986_r8, &
         18.0363407_r8, 1.00740004_r8 /)

      else
         call endrun( '*** bad nbc and/or npoa and/or nsoa' )
      end if

#elif ( defined MODAL_AERO_4MODE_MOM )
      if (nbc==1 .and. npoa==1 .and. nsoa==1 .and. nsoag==1) then
#if ( defined RAIN_EVAP_TO_COARSE_AERO )
      solsym(:l) = &
      (/ 'H2O2          ', 'H2SO4         ', 'SO2           ', 'DMS           ', 'SOAG          ', &
         'so4_a1        ', 'pom_a1        ', 'soa_a1        ', 'bc_a1         ', 'dst_a1        ', &
         'ncl_a1        ', 'mom_a1        ', 'num_a1        ', 'so4_a2        ', 'soa_a2        ', &
         'ncl_a2        ', 'mom_a2        ', 'num_a2        ', 'dst_a3        ', 'ncl_a3        ', &
         'so4_a3        ', 'bc_a3         ', 'pom_a3        ', 'soa_a3        ', 'mom_a3        ', &
         'num_a3        ', 'pom_a4        ', 'bc_a4         ', 'mom_a4        ', 'num_a4        ' /)
      adv_mass(:l) = &
      (/     34.013600_r8,     98.078400_r8,     64.064800_r8,     62.132400_r8,     12.011000_r8, &
            115.107340_r8,     12.011000_r8,     12.011000_r8,     12.011000_r8,    135.064039_r8, &
             58.442468_r8, 250092.672000_r8,      1.007400_r8,    115.107340_r8,     12.011000_r8, &
             58.442468_r8, 250092.672000_r8,      1.007400_r8,    135.064039_r8,     58.442468_r8, &
            115.107340_r8,     12.011000_r8,     12.011000_r8,     12.011000_r8, 250092.672000_r8, &
              1.007400_r8,     12.011000_r8,     12.011000_r8, 250092.672000_r8,      1.007400_r8 /)
#else
      solsym(:l) = &
      (/ 'H2O2    ', 'H2SO4   ', 'SO2     ', 'DMS     ',             &
         'SOAG    ', 'so4_a1  ',             'pom_a1  ', 'soa_a1  ', &
         'bc_a1   ', 'ncl_a1  ', 'dst_a1  ', 'mom_a1  ', 'num_a1  ', &
         'so4_a2  ', 'soa_a2  ', 'ncl_a2  ', 'mom_a2  ', 'num_a2  ', &
         'dst_a3  ', 'ncl_a3  ', 'so4_a3  ', 'num_a3  ',             &
         'pom_a4  ', 'bc_a4   ', 'mom_a4  ', 'num_a4  ' /)
      adv_mass(:l) = &
      (/ 34.0135994_r8, 98.0783997_r8, 64.0647964_r8, 62.1324005_r8,                &
         12.0109997_r8, 115.107340_r8,                12.0109997_r8, 12.0109997_r8, &
         12.0109997_r8, 58.4424667_r8, 135.064041_r8, 250092.672_r8, 1.00740004_r8, &
         115.107340_r8, 12.0109997_r8, 58.4424667_r8, 250092.672_r8, 1.00740004_r8, &
         135.064041_r8, 58.4424667_r8, 115.107340_r8, 1.00740004_r8,                &
         12.0109997_r8, 12.0109997_r8, 250092.672_r8, 1.00740004_r8 /)
#endif
      else
         call endrun( '*** bad nbc and/or npoa and/or nsoa' )
      end if


#elif ( defined MODAL_AERO_4MODE )
      if (nbc==1 .and. npoa==1 .and. nsoa==1 .and. nsoag==1) then

      solsym(:l) = &
      (/ 'H2O2    ', 'H2SO4   ', 'SO2     ', 'DMS     ',             &
         'SOAG    ', 'so4_a1  ',             'pom_a1  ', 'soa_a1  ', &
         'bc_a1   ', 'ncl_a1  ', 'dst_a1  ', 'num_a1  ', 'so4_a2  ', &
         'soa_a2  ', 'ncl_a2  ', 'num_a2  ',                         &
         'dst_a3  ', 'ncl_a3  ', 'so4_a3  ', 'num_a3  ',             &
         'pom_a4  ', 'bc_a4   ', 'num_a4  ' /)
      adv_mass(:l) = &
      (/ 34.0135994_r8, 98.0783997_r8, 64.0647964_r8, 62.1324005_r8,                &
         12.0109997_r8, 115.107340_r8,                12.0109997_r8, 12.0109997_r8, &
         12.0109997_r8, 58.4424667_r8, 135.064041_r8, 1.00740004_r8, 115.107340_r8, &
         12.0109997_r8, 58.4424667_r8, 1.00740004_r8,                               &
         135.064041_r8, 58.4424667_r8, 115.107340_r8, 1.00740004_r8,                &
         12.0109997_r8, 12.0109997_r8, 1.00740004_r8 /)
      else
         call endrun( '*** bad nbc and/or npoa and/or nsoa' )
      end if

#else
!if ( defined MODAL_AERO_3MODE )
      if (nbc==1 .and. npoa==1 .and. nsoa==1 .and. nsoag==1) then

      solsym(:l) = &
      (/ 'H2O2    ', 'H2SO4   ', 'SO2     ', 'DMS     ',             &
         'SOAG    ', 'so4_a1  ',             'pom_a1  ', 'soa_a1  ', &
         'bc_a1   ', 'ncl_a1  ', 'dst_a1  ', 'num_a1  ', 'so4_a2  ', &
         'soa_a2  ', 'ncl_a2  ', 'num_a2  ',                         &
         'dst_a3  ', 'ncl_a3  ', 'so4_a3  ', 'num_a3  ' /)
      adv_mass(:l) = &
      (/ 34.0135994_r8, 98.0783997_r8, 64.0647964_r8, 62.1324005_r8,                &
         12.0109997_r8, 115.107340_r8,                12.0109997_r8, 12.0109997_r8, &
         12.0109997_r8, 58.4424667_r8, 135.064041_r8, 1.00740004_r8, 115.107340_r8, &
         12.0109997_r8, 58.4424667_r8, 1.00740004_r8,                               &
         135.064041_r8, 58.4424667_r8, 115.107340_r8, 1.00740004_r8 /)

      else
         call endrun( '*** bad nbc and/or npoa and/or nsoa' )
      end if

#endif

      cnst_name(1) = 'QVAPOR'
      cnst_name(2) = 'CLDLIQ'
      cnst_name(3) = 'CLDICE'
      cnst_name(4) = 'NUMLIQ'
      cnst_name(5) = 'NUMICE'
      cnst_name(imozart:pcnst) = solsym(1:gas_pcnst)

      mosaic = .false.

      write(iulog,'(/a)') &
         'l, l2, cnst_name(l), solsym(l2), adv_mass(l2)'
      do l = 1, pcnst
         if (l < imozart) then
            write(iulog,'(i4,6x,a)') l, cnst_name(l)
         else
            l2 = l - imozart + 1
            if (adv_mass(l2) < 1.0e5_r8) then
               write(iulog,'(2i4,2x,2a,f9.3)') l, l2, cnst_name(l), solsym(l2), adv_mass(l2)
            else
               write(iulog,'(2i4,2x,2a,1pe16.8)') l, l2, cnst_name(l), solsym(l2), adv_mass(l2)
            end if
         end if
      end do


      write(*,'(/a)') 'cambox_init_basics calling pbuf_init'
      call pbuf_init( )

      write(*,'(/a)') 'cambox_init_basics calling modal_aero_register'
      call modal_aero_register( species_class )

      write(*,'(/a)') &
         'cambox_init_basics calling modal_aero_calcsize_reg'
      call modal_aero_calcsize_reg( )

      write(*,'(/a)') &
         'cambox_init_basics calling modal_aero_wateruptake_reg'
      call modal_aero_wateruptake_reg( )

      write(*,'(/a)') 'cambox_init_basics calling modal_aero_initialize'
      call modal_aero_initialize( pbuf2d, imozart, species_class )

      write(*,'(/a)') &
         'cambox_init_basics calling modal_aero_wateruptake_init'
      call modal_aero_wateruptake_init( pbuf2d )

      write(*,'(/a)') 'cambox_init_basics all done'

      return
      end subroutine cambox_init_basics


!-------------------------------------------------------------------------------
      subroutine cambox_init_run( &
         ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens        )

      use shr_kind_mod, only: r8 => shr_kind_r8
      use abortutils, only: endrun
      use cam_logfile, only: iulog
      use chem_mods, only: adv_mass, gas_pcnst, imozart
      use physconst, only: epsilo, latvap, latice, rh2o, cpair, tmelt, mwdry
      use ppgrid, only: pcols, pver
      use wv_saturation, only: qsat, gestbl

      use modal_aero_data
      use modal_aero_amicphys, only: &
         gaexch_h2so4_uptake_optaa, newnuc_h2so4_conc_optaa, mosaic

!     implicit none

      integer,  intent(in   ) :: ncol
      integer,  intent(out  ) :: nstop

      real(r8), intent(out  ) :: deltat
      real(r8), intent(out  ) :: t(pcols,pver)      ! Temperature in Kelvin
      real(r8), intent(out  ) :: pmid(pcols,pver)   ! pressure at model levels (Pa)
      real(r8), intent(out  ) :: pdel(pcols,pver)   ! pressure thickness of levels
      real(r8), intent(out  ) :: zm(pcols,pver)     ! midpoint height above surface (m)
      real(r8), intent(out  ) :: pblh(pcols)        ! pbl height (m)
      real(r8), intent(out  ) :: cld(pcols,pver)    ! stratiform cloud fraction
      real(r8), intent(out  ) :: relhum(pcols,pver) ! layer relative humidity
      real(r8), intent(out  ) :: qv(pcols,pver)     ! layer specific humidity

      real(r8), intent(out  ) :: q(pcols,pver,pcnst)     ! Tracer MR array
      real(r8), intent(out  ) :: qqcw(pcols,pver,pcnst)  ! Cloudborne aerosol MR array
      real(r8), intent(out  ) :: dgncur_a(pcols,pver,ntot_amode)
      real(r8), intent(out  ) :: dgncur_awet(pcols,pver,ntot_amode)
      real(r8), intent(out  ) :: qaerwat(pcols,pver,ntot_amode)
      real(r8), intent(out  ) :: wetdens(pcols,pver,ntot_amode)

      integer :: i
      integer :: k
      integer :: l, ll, loffset, lun
      integer :: l_nh3g, l_so2g, l_soag, l_hno3g, l_hclg
      integer :: l_num_a1, l_num_a2, l_nh4_a1, l_nh4_a2, &
                 l_so4_a1, l_so4_a2, l_soa_a1, l_soa_a2
      integer :: l_numa, l_so4a, l_nh4a, l_soaa, l_poma, l_bcxa, l_ncla, &
                 l_dsta, l_no3a, l_clxa, l_caxa, l_co3a
      integer :: mode123_empty
      integer :: mopt_aero_loadaa, mopt_aero_loadbb
      integer :: n, nacc, nait

      logical :: ip

      character(len=80) :: tmpch80

      real(r8) :: ev_sat(pcols,pver)
      real(r8) :: qv_sat(pcols,pver)
      real(r8) :: relhum_clea(ncol,pver)
      real(r8) :: zdel(ncol,pver)     ! thickness of levels (m)
      real(r8) :: tmn, tmx, trice
      real(r8) :: tmpa, tmpq
      real(r8) :: tmpfso4, tmpfnh4, tmpfsoa, tmpfpom, tmpfbcx, tmpfncl, tmpfdst
      real(r8) :: tmpfno3, tmpfclx, tmpfcax, tmpfco3
      real(r8) :: tmpfmact, tmpfnact 
      real(r8) :: tmpdens, tmpvol 


      iwrite3x_species_flagaa = 1
      iwrite3x_units_flagaa   = 1
      iwrite4x_heading_flagbb = 1

! mopt_aero_comp -- accum mode composition
!  1, 5     tmpfso4 = 0.5_r8 ; tmpfpom = 0.0_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.5_r8
!  4, 6     tmpfso4 = 0.3_r8 ; tmpfpom = 0.3_r8 ; tmpfsoa = 0.3_r8 ; tmpfncl = 0.1_r8
!  2        tmpfso4 = 0.3_r8 ; tmpfpom = 0.3_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.4_r8
!  3        tmpfso4 = 0.3_r8 ; tmpfpom = 0.0_r8 ; tmpfsoa = 0.3_r8 ; tmpfncl = 0.4_r8
!  7, 8     tmpfso4 = 1.0_r8 ; tmpfpom = 0.0_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.0_r8
!  9        tmpfso4 = 0.5_r8 ; tmpfpom = 0.5_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.0_r8
!  11       tmpfso4 = 0.3_r8 ; tmpfpom = 0.0_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.4_r8 ; tmpfno3 = 0.3_r8
!  11       tmpfso4 = 0.3_r8 ; tmpfpom = 0.2_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.3_r8 ; tmpfno3 = 0.2_r8
! also for mam7
! 1-4, 8       tmpfnh4 = tmpfso4*(18.0_r8/114.0_r8)
! 5-7          tmpfnh4 = tmpfso4*(36.0_r8/132.0_r8)
! 9            tmpfnh4 = 0.0

!  mopt_aero_loadaa = ones digit of mopt_aero_load
!     0  - accum mode number (k=pver) = 1.0e0  #/mg -- very low
!     1  - accum mode number (k=pver) = 2.0e1  #/mg -- low
!     6  - accum mode number (k=pver) = 1.0e-5 #/mg -- almost zero
!   other- accum mode number (k=pver) = 5.0e2  #/mg -- moderately high

!  mopt_aero_loadbb = tens digit of mopt_aero_load
!     0 - do modes 1,2,3       4 - do modes 1,2
!     1 - do modes 1           5 - do modes 2,3
!     2 - do modes 2           6 - do modes 1,3
!     3 - do modes 3           7 - do modes 1,2,3,4,5,6,7
!                              8 - do modes 1,2,5,7

      mdo_gaschem    = 1
      mdo_cloudchem  = 1
      mdo_gasaerexch = 1
      mdo_rename     = 1
      mdo_newnuc     = 1
      mdo_coag       = 1

      gaexch_h2so4_uptake_optaa =  2  ! 1=sequential prod then loss,  2=prod+loss together
      newnuc_h2so4_conc_optaa   =  2  ! controls treatment of h2so4 concentrationin mam_newnuc_1subcol
                              !    1 = use avg. value calculated in standard cam5.2.10 and earlier
                              !    2 = use avg. value calculated in mam_gasaerexch_1subcol
                              !   11 = use avg. of initial and final values from mam_gasaerexch_1subcol
                              !   12 = use final value from mam_gasaerexch_1subcol
      mopt_h2so4_uptake          = 1  ! *** no longer used

      mopt_aero_comp    = 6
      mopt_aero_load    = 71
      mopt_ait_size     = 2
      xopt_cloudf       = 0.6_r8
      i_cldy_sameas_clear = 0
      deltat            =   50.0_r8
      deltat            = 3600.0_r8*120.0_r8
      deltat            = 3600.0_r8
      deltat            = 1800.0_r8
      nstop             = 1
      nstop             = 3

      mosaic = .true.
      mosaic = .false.

      mopt_aero_load    = 72
      mopt_aero_comp    = 11

      mode123_empty = 1

      if ( 0 == 1 ) then
! values for newnuc comparison with dd06f
      mdo_rename     = 0
      mdo_coag       = 0
      mopt_aero_comp    = 1
      mopt_aero_load    = 10
      mopt_ait_size     = 1
      end if

      lun = -4
      if (lun > 0) then
      open( unit=lun, file='cambox_init.inp', status='old' )
      read(lun,*) deltat
      read(lun,*) mopt_aero_comp, mopt_aero_load, mopt_ait_size
      read(lun,*) xopt_cloudf
      close( unit=lun )
      end if

      if (pver /= 4) then
         call endrun( '*** cambox_init_run -- pver must be 4' )
      end if

      do i = 1, ncol
         pdel(i,1:pver) = (/ 0.2e5_r8, 0.3e5_r8, 0.2e5_r8, 0.1e5_r8 /)
         zdel(i,1:pver) = (/ 3.0e3_r8, 3.0e3_r8, 2.0e3_r8, 1.0e3_r8 /)

         k = pver
         pmid(i,k) = 1.0e5_r8 - 0.5_r8*pdel(i,k)
         zm(i,k) = 0.5_r8*zdel(i,k)
         t(i,k) = 288.0_r8 - 6.5e-3_r8*zm(i,k)

         pblh(i) = 1.1e3_r8

         do k = pver-1, 1, -1
            pmid(i,k) = pmid(i,k+1) - 0.5_r8*( pdel(i,k+1) + pdel(i,k) )
            zm(i,k) = zm(i,k+1) + 0.5_r8*( zdel(i,k+1) + zdel(i,k) )
            t(i,k) = t(i,k+1) - 6.5e-3_r8*0.5_r8*( zdel(i,k+1) + zdel(i,k) )
         end do
      end do

      q = 0.0_r8
      qqcw = 0.0_r8
      dgncur_a = 0.0_r8
      dgncur_awet = 0.0_r8
      qaerwat = 0.0_r8
      wetdens = 0.0_r8


! set cloud, rh, qv
      cld(:,:) = 0.0_r8
!     cld(:,2) = 0.5_r8
      cld(2,:) = 0.5_r8
      cld(5,:) = 0.5_r8
      cld(:,:) = xopt_cloudf
      do k = 1, pver
      do i = 1, ncol
         exit
         cld(i,k) = ((k*0.7)/pver) + ((i*0.2)/ncol)
      end do
      end do

      relhum_clea(:,:) = 0.50_r8
      relhum_clea(:,2) = 0.60_r8
      relhum_clea(:,3) = 0.70_r8
      relhum_clea(:,4) = 0.90_r8
!     relhum_clea(:,:) = 0.01_r8
! above values are for clear fraction
! now do grid average
      do i = 1, ncol
      if (i_cldy_sameas_clear <= 0) then
         relhum(i,:) = relhum_clea(i,:)*(1.0_r8-cld(i,:)) + cld(i,:)
      else
         relhum(i,:) = relhum_clea(i,:)
      end if
      end do

! call gestbl to build saturation vapor pressure table.
      tmn   = 173.16_r8
      tmx   = 375.16_r8
      trice =  20.00_r8
      ip    = .true.
      call gestbl(tmn     ,tmx     ,trice   ,ip      ,epsilo  , &
                  latvap  ,latice  ,rh2o    ,cpair   ,tmelt )

!     call aqsat( t, pmid, ev_sat, qv_sat, pcols, ncol, pver, 1, pver )
      call  qsat( t(1:ncol,1:pver), pmid(1:ncol,1:pver), &
                  ev_sat(1:ncol,1:pver), qv_sat(1:ncol,1:pver) )

      qv(1:ncol,1:pver) = relhum(1:ncol,1:pver)*qv_sat(1:ncol,1:pver)

      q(1:ncol,1:pver,1) = qv(1:ncol,1:pver)


! set trace gases
      call cnst_get_ind( 'SOAG', l_soag,  .false. )
      call cnst_get_ind( 'SO2',  l_so2g,  .false. )
      call cnst_get_ind( 'NH3',  l_nh3g,  .false. )
      call cnst_get_ind( 'HNO3', l_hno3g, .false. )
      call cnst_get_ind( 'HCL',  l_hclg,  .false. )
      loffset = imozart-1

      q( 1,:,l_so2g) =  0.20e-9 *(adv_mass(l_so2g-loffset)/mwdry)
      q( 3,:,l_so2g) =  0.20e-9 *(adv_mass(l_so2g-loffset)/mwdry)
      q( 7,:,l_so2g) =  0.20e-9 *(adv_mass(l_so2g-loffset)/mwdry)
      q( 8,:,l_so2g) =  0.20e-9 *(adv_mass(l_so2g-loffset)/mwdry)
      q( 2,:,l_so2g) = 10.00e-9 *(adv_mass(l_so2g-loffset)/mwdry)
      q( 4,:,l_so2g) = 10.00e-9 *(adv_mass(l_so2g-loffset)/mwdry)
      q( 9,:,l_so2g) = 10.00e-9 *(adv_mass(l_so2g-loffset)/mwdry)
      q(10,:,l_so2g) = 10.00e-9 *(adv_mass(l_so2g-loffset)/mwdry)
! for mam7 to mam4 compare, had so2 and h2so4 = 0
! for testing of aging, want to have some
!     q(:,:,l_so2g) = 0.0

      if (l_nh3g > 0) then
      q( 1,:,l_nh3g) = 0.01e-9 *(adv_mass(l_nh3g-loffset)/mwdry)
      q( 4,:,l_nh3g) = 0.01e-9 *(adv_mass(l_nh3g-loffset)/mwdry)
      q( 7,:,l_nh3g) = 0.01e-9 *(adv_mass(l_nh3g-loffset)/mwdry)
      q( 8,:,l_nh3g) = 0.01e-9 *(adv_mass(l_nh3g-loffset)/mwdry)
      q( 2,:,l_nh3g) = 1.00e-9 *(adv_mass(l_nh3g-loffset)/mwdry)
      q( 3,:,l_nh3g) = 1.00e-9 *(adv_mass(l_nh3g-loffset)/mwdry)
      q( 9,:,l_nh3g) = 1.00e-9 *(adv_mass(l_nh3g-loffset)/mwdry)
      q(10,:,l_nh3g) = 1.00e-9 *(adv_mass(l_nh3g-loffset)/mwdry)
      if (mopt_aero_comp == 9) q(:,:,l_nh3g) = 0.0
      q(:,:,l_nh3g) = 0.0
      end if

      if (l_hno3g > 0) then
      tmpa = adv_mass(l_hno3g-loffset)/adv_mass(l_nh3g-loffset)
      if ( (mopt_aero_comp == 11) .or. &
           (mopt_aero_comp == 12) ) then
         q(:,:,l_hno3g) = q(:,:,l_nh3g)*tmpa
      end if
      end if
      if (l_hclg > 0) then
      if ( (mopt_aero_comp == 11) .or. &
           (mopt_aero_comp == 13) ) then
         q( 1,:,l_hclg) = 0.1e-9 *(adv_mass(l_hclg-loffset)/mwdry)
      end if
      end if

      q( 5,:,l_soag) = 0.50e-9 *(adv_mass(l_soag-loffset)/mwdry)
      q( 7,:,l_soag) = 0.50e-9 *(adv_mass(l_soag-loffset)/mwdry)
      q( 9,:,l_soag) = 0.50e-9 *(adv_mass(l_soag-loffset)/mwdry)
      q( 6,:,l_soag) = 5.00e-9 *(adv_mass(l_soag-loffset)/mwdry)
      q( 8,:,l_soag) = 5.00e-9 *(adv_mass(l_soag-loffset)/mwdry)
      q(10,:,l_soag) = 5.00e-9 *(adv_mass(l_soag-loffset)/mwdry)
! for testing of aging, less soag
      q( 5,:,l_soag) = 0.100e-9 *(adv_mass(l_soag-loffset)/mwdry)
      q( 7,:,l_soag) = 0.100e-9 *(adv_mass(l_soag-loffset)/mwdry)
      q( 9,:,l_soag) = 0.100e-9 *(adv_mass(l_soag-loffset)/mwdry)
      q( 6,:,l_soag) = 0.30e-9 *(adv_mass(l_soag-loffset)/mwdry)
      q( 8,:,l_soag) = 0.30e-9 *(adv_mass(l_soag-loffset)/mwdry)
      q(10,:,l_soag) = 0.30e-9 *(adv_mass(l_soag-loffset)/mwdry)

      do k = 1, pver
         tmpa = (k-0.6666666)/(pver-0.6666666)
!        tmpa = 0.5 + 0.5*(k-0.6666666)/(pver-0.6666666)
         tmpa = 1.0 - 0.2*(pver-k)
         tmpa = max( tmpa, 0.0_r8 )
         q(:,k,l_so2g) = q(:,k,l_so2g) * tmpa
         if (l_nh3g > 0) then
         q(:,k,l_nh3g) = q(:,k,l_nh3g) * tmpa
         end if
         q(:,k,l_soag) = q(:,k,l_soag) * tmpa
      end do


      mopt_aero_loadaa = mod( mopt_aero_load, 10 )
      mopt_aero_loadbb = mod( (mopt_aero_load/10), 10 )
!     mopt_aero_loadbb = 0 - do modes 1,2,3
!     mopt_aero_loadbb = 1 - do modes 1
!     mopt_aero_loadbb = 2 - do modes 2
!     mopt_aero_loadbb = 3 - do modes 3
!     mopt_aero_loadbb = 4 - do modes 1,2
!     mopt_aero_loadbb = 5 - do modes 2,3
!     mopt_aero_loadbb = 6 - do modes 1,3
!     mopt_aero_loadbb = 8 - do modes 1,2,5,7
!     mopt_aero_loadbb = other - do modes 1,2,3,4,5,6,7

      tmpdens = 1770.0_r8
! set accum mode number and masses
      n = modeptr_accum
      l_numa = numptr_amode(n)
      l_so4a = lptr_so4_a_amode(n)
      l_nh4a = lptr_nh4_a_amode(n)
      l_soaa = lptr_soa_a_amode(n)
      l_poma = lptr_pom_a_amode(n)
      if (npoa == 2) l_poma = lptr_poma_a_amode(n)
      l_bcxa = lptr_bc_a_amode(n)
      if (nbc  == 2) l_bcxa = lptr_bca_a_amode(n)
      l_ncla = lptr_nacl_a_amode(n)
      l_dsta = lptr_dust_a_amode(n)
#if ( defined MOSAIC_SPECIES )
      l_no3a = lptr_no3_a_amode(n)
      l_clxa = lptr_cl_a_amode(n)
      l_caxa = lptr_ca_a_amode(n)
      l_co3a = lptr_co3_a_amode(n)
#else
      l_no3a = -1
      l_clxa = -1
      l_caxa = -1
      l_co3a = -1
#endif
      l_num_a1 = l_numa
      l_so4_a1 = l_so4a

      do k = 1, pver
      do i = 1, ncol
         if (mode123_empty > 0) exit

         tmpa = k*1.0/pver

!k, accum num, so4, dgncur_a, same for aitken  (#/mg,  ug/kg,  nm)
!   1    1.2240E+02  9.6053E-08  5.3500E+01    1.2500E+02  2.7831E-09  8.7000E+00
!   2    2.4479E+02  1.9211E-07  5.3500E+01    2.5000E+02  5.5663E-09  8.7000E+00
!   3    3.6719E+02  2.8816E-07  5.3500E+01    3.7500E+02  8.3494E-09  8.7000E+00
!   4    4.8958E+02  3.8421E-07  5.3500E+01    5.0000E+02  1.1133E-08  8.7000E+00

         if (mopt_aero_loadbb == 2 .or. &
             mopt_aero_loadbb == 3 .or. &
             mopt_aero_loadbb == 5 ) exit
         if (mopt_aero_loadaa <= 0) then
            q(i,k,l_numa) = 1.0e6_r8*tmpa
         else if (mopt_aero_loadaa == 1) then
            q(i,k,l_numa) = 2.0e7_r8*tmpa
         else if (mopt_aero_loadaa == 6) then
            q(i,k,l_numa) = 1.0e1_r8*tmpa
         else
            q(i,k,l_numa) = 5.0e8_r8*tmpa
         end if
         tmpvol = q(i,k,l_numa)/voltonumb_amode(n)
!        if (k==1) q(i,k,l_numa) = q(i,k,l_numa) / 100.0  ! decrease number to make particles bigger  and force calcsize 
!        if (k==3) q(i,k,l_numa) = q(i,k,l_numa) * 100.0  ! increase number to make particles smaller and force calcsize 

         tmpfso4 = 0.0_r8 ; tmpfnh4 = 0.0_r8
         tmpfsoa = 0.0_r8 ; tmpfpom = 0.0_r8 ; tmpfbcx = 0.0_r8
         tmpfncl = 0.0_r8 ; tmpfdst = 0.0_r8
         tmpfno3 = 0.0_r8 ; tmpfclx = 0.0_r8
         tmpfcax = 0.0_r8 ; tmpfco3 = 0.0_r8

         if ( mopt_aero_comp <= 1 .or. &
              mopt_aero_comp == 5 ) then
            tmpfso4 = 0.5_r8 ; tmpfpom = 0.0_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.5_r8
         else if ( mopt_aero_comp == 4 .or. &
                   mopt_aero_comp == 6 ) then
            tmpfso4 = 0.3_r8 ; tmpfpom = 0.3_r8 ; tmpfsoa = 0.3_r8 ; tmpfncl = 0.1_r8
         else if ( mopt_aero_comp == 2 ) then
            tmpfso4 = 0.3_r8 ; tmpfpom = 0.3_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.4_r8
         else if ( mopt_aero_comp == 3 ) then
            tmpfso4 = 0.3_r8 ; tmpfpom = 0.0_r8 ; tmpfsoa = 0.3_r8 ; tmpfncl = 0.4_r8
         else if ( mopt_aero_comp == 9 ) then
            tmpfso4 = 0.5_r8 ; tmpfpom = 0.5_r8
         else if ( mopt_aero_comp == 11 ) then
!           tmpfso4 = 0.3_r8 ; tmpfncl = 0.4_r8 ; tmpfno3 = 0.3_r8
!           tmpfso4 = 0.3_r8 ; tmpfncl = 0.3_r8 ; tmpfno3 = 0.2_r8 ; tmpfpom = 0.2_r8
            tmpfsoa = 0.01_r8 ; tmpfncl = 0.59_r8 ; tmpfbcx = 0.01_r8 ; tmpfpom = 0.39_r8
         else ! here ( mopt_aero_comp >= 7 )
            tmpfso4 = 1.0_r8 ; tmpfpom = 0.0_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.0_r8
         end if

         if (ntot_amode == 7) then
            if ( mopt_aero_comp == 11 ) then
               tmpfnh4 = tmpfso4*0.27300_r8 + tmpfno3*0.22534_r8
               tmpfso4 = tmpfso4*(1.0_r8 - 0.27300_r8)
               tmpfno3 = tmpfno3*(1.0_r8 - 0.22534_r8)
               tmpfclx = tmpfncl*0.60663_r8
               tmpfncl = tmpfncl - tmpfclx
            else
!              if ( mopt_aero_comp <= 4 ) then
               if ( mopt_aero_comp <= 4 .or. mopt_aero_comp == 8 ) then
                  tmpfnh4 = tmpfso4*(18.0_r8/114.0_r8)
               else if ( mopt_aero_comp == 9 ) then
                  tmpfnh4 = 0.0
               else
                  tmpfnh4 = tmpfso4*(36.0_r8/132.0_r8)
               end if
               tmpfso4 = tmpfso4 - tmpfnh4
            end if
         end if

         if (l_so4a > 0) q(i,k,l_so4a) = (tmpvol*tmpdens)*tmpfso4
         if (l_nh4a > 0) q(i,k,l_nh4a) = (tmpvol*tmpdens)*tmpfnh4
         if (l_soaa > 0) q(i,k,l_soaa) = (tmpvol*tmpdens)*tmpfsoa
         if (l_poma > 0) q(i,k,l_poma) = (tmpvol*tmpdens)*tmpfpom
         if (l_bcxa > 0) q(i,k,l_bcxa) = (tmpvol*tmpdens)*tmpfbcx
         if (l_dsta > 0) q(i,k,l_dsta) = (tmpvol*tmpdens)*tmpfdst
         if (l_ncla > 0) q(i,k,l_ncla) = (tmpvol*tmpdens)*tmpfncl
         if (l_no3a > 0) q(i,k,l_no3a) = (tmpvol*tmpdens)*tmpfno3
         if (l_clxa > 0) q(i,k,l_clxa) = (tmpvol*tmpdens)*tmpfclx
         if (l_caxa > 0) q(i,k,l_caxa) = (tmpvol*tmpdens)*tmpfcax
         if (l_co3a > 0) q(i,k,l_co3a) = (tmpvol*tmpdens)*tmpfco3
      end do ! i
      end do ! k


! set aitken mode number and masses
      n = modeptr_aitken
      l_numa = numptr_amode(n)
      l_so4a = lptr_so4_a_amode(n)
      l_nh4a = lptr_nh4_a_amode(n)
      l_soaa = lptr_soa_a_amode(n)
      l_poma = lptr_pom_a_amode(n)
      if (npoa == 2) l_poma = lptr_poma_a_amode(n)
      l_bcxa = lptr_bc_a_amode(n)
      if (nbc  == 2) l_bcxa = lptr_bca_a_amode(n)
      l_ncla = lptr_nacl_a_amode(n)
      l_dsta = lptr_dust_a_amode(n)
#if ( defined MOSAIC_SPECIES )
      l_no3a = lptr_no3_a_amode(n)
      l_clxa = lptr_cl_a_amode(n)
      l_caxa = lptr_ca_a_amode(n)
      l_co3a = lptr_co3_a_amode(n)
#else
      l_no3a = -1
      l_clxa = -1
      l_caxa = -1
      l_co3a = -1
#endif
      l_num_a2 = l_numa
      l_so4_a2 = l_so4a

      do k = 1, pver
      do i = 1, ncol
         if (mode123_empty > 0) exit

         tmpa = k*1.0/pver

         if (mopt_aero_loadbb == 1 .or. &
             mopt_aero_loadbb == 3 .or. &
             mopt_aero_loadbb == 6 ) exit
         if (mopt_aero_loadaa <= 0) then
            q(i,k,l_numa) = 1.0e6_r8*tmpa
         else if (mopt_aero_loadaa == 1) then
            q(i,k,l_numa) = 2.0e7_r8*tmpa
         else
            q(i,k,l_numa) = 5.0e8_r8*tmpa
         end if
         tmpvol = q(i,k,l_numa)/voltonumb_amode(n)
         if (mopt_ait_size > 1) tmpvol = tmpvol*8.0_r8
!        if (k==2) q(i,k,l_numa) = q(i,k,l_numa) * 100.0  ! increase number to make particles smaller and force calcsize
!        if (k==4) q(i,k,l_numa) = q(i,k,l_numa) / 100.0  ! decrease number to make particles bigger  and force calcsize

         tmpfso4 = 0.0_r8 ; tmpfnh4 = 0.0_r8
         tmpfsoa = 0.0_r8 ; tmpfpom = 0.0_r8 ; tmpfbcx = 0.0_r8
         tmpfncl = 0.0_r8 ; tmpfdst = 0.0_r8
         tmpfno3 = 0.0_r8 ; tmpfclx = 0.0_r8
         tmpfcax = 0.0_r8 ; tmpfco3 = 0.0_r8

         if ( mopt_aero_comp <= 1 .or. &
              mopt_aero_comp == 2 .or. &
              mopt_aero_comp == 5 ) then
            tmpfso4 = 0.5_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.5_r8
         else if ( mopt_aero_comp == 11 ) then
!           tmpfso4 = 0.3_r8 ; tmpfncl = 0.4_r8 ; tmpfno3 = 0.3_r8
            tmpfso4 = 0.0_r8 ; tmpfsoa = 0.3_r8 ; tmpfncl = 0.7_r8
         else if ( mopt_aero_comp >= 7 ) then
            tmpfso4 = 1.0_r8 ; tmpfsoa = 0.0_r8 ; tmpfncl = 0.0_r8
         else
            tmpfso4 = 0.3_r8 ; tmpfsoa = 0.3_r8 ; tmpfncl = 0.4_r8
         end if

         if (ntot_amode == 7) then
            if ( mopt_aero_comp == 11 ) then
!              tmpfnh4 = tmpfso4*0.27300_r8 + tmpfno3*0.22534_r8
!              tmpfso4 = tmpfso4*(1.0_r8 - 0.27300_r8)
!              tmpfno3 = tmpfno3*(1.0_r8 - 0.22534_r8)
!              tmpfclx = tmpfncl*0.60663_r8
!              tmpfncl = tmpfncl - tmpfclx
               tmpfso4 = 0.0_r8 ; tmpfsoa = 0.3_r8 ; tmpfncl = 0.7_r8
            else
!              if ( mopt_aero_comp <= 4 ) then
               if ( mopt_aero_comp <= 4 .or. mopt_aero_comp == 8 ) then
                  tmpfnh4 = tmpfso4*(18.0_r8/114.0_r8)
               else if ( mopt_aero_comp == 9 ) then
                  tmpfnh4 = 0.0
               else
                  tmpfnh4 = tmpfso4*(36.0_r8/132.0_r8)
               end if
               tmpfso4 = tmpfso4 - tmpfnh4
               tmpfso4 = 0.0_r8 ; tmpfsoa = 0.3_r8 ; tmpfncl = 0.7_r8
            end if
         end if

         if (l_so4a > 0) q(i,k,l_so4a) = (tmpvol*tmpdens)*tmpfso4
         if (l_nh4a > 0) q(i,k,l_nh4a) = (tmpvol*tmpdens)*tmpfnh4
         if (l_soaa > 0) q(i,k,l_soaa) = (tmpvol*tmpdens)*tmpfsoa
         if (l_poma > 0) q(i,k,l_poma) = (tmpvol*tmpdens)*tmpfpom
         if (l_bcxa > 0) q(i,k,l_bcxa) = (tmpvol*tmpdens)*tmpfbcx
         if (l_dsta > 0) q(i,k,l_dsta) = (tmpvol*tmpdens)*tmpfdst
         if (l_ncla > 0) q(i,k,l_ncla) = (tmpvol*tmpdens)*tmpfncl
         if (l_no3a > 0) q(i,k,l_no3a) = (tmpvol*tmpdens)*tmpfno3
         if (l_clxa > 0) q(i,k,l_clxa) = (tmpvol*tmpdens)*tmpfclx
         if (l_caxa > 0) q(i,k,l_caxa) = (tmpvol*tmpdens)*tmpfcax
         if (l_co3a > 0) q(i,k,l_co3a) = (tmpvol*tmpdens)*tmpfco3
      end do ! i
      end do ! k



! set coarse mode number and masses
!     if ( modeptr_coarse > 0 ) then
      if ( modeptr_coarse > 99 ) then

      n = modeptr_coarse
      l_numa = numptr_amode(n)
      l_so4a = lptr_so4_a_amode(n)
      l_nh4a = lptr_nh4_a_amode(n)
      l_soaa = lptr_soa_a_amode(n)
      l_poma = lptr_pom_a_amode(n)
      if (npoa == 2) l_poma = lptr_poma_a_amode(n)
      l_bcxa = lptr_bc_a_amode(n)
      if (nbc  == 2) l_bcxa = lptr_bca_a_amode(n)
      l_ncla = lptr_nacl_a_amode(n)
      l_dsta = lptr_dust_a_amode(n)
#if ( defined MOSAIC_SPECIES )
      l_no3a = lptr_no3_a_amode(n)
      l_clxa = lptr_cl_a_amode(n)
      l_caxa = lptr_ca_a_amode(n)
      l_co3a = lptr_co3_a_amode(n)
#else
      l_no3a = -1
      l_clxa = -1
      l_caxa = -1
      l_co3a = -1
#endif

      do k = 1, pver
      do i = 1, ncol
         if (mode123_empty > 0) exit

         tmpa = k*1.0/pver

         if (mopt_aero_loadbb <= 6 ) exit
         if (mopt_aero_loadbb == 8 ) exit
         if (mopt_aero_loadaa <= 0) then
            q(i,k,l_numa) = 1.0e3_r8*tmpa
         else if (mopt_aero_loadaa == 1) then
            q(i,k,l_numa) = 1.0e4_r8*tmpa
         else
            q(i,k,l_numa) = 2.5e4_r8*tmpa
         end if
         tmpvol = q(i,k,l_numa)/voltonumb_amode(n)

         tmpfso4 = 0.0_r8 ; tmpfnh4 = 0.0_r8
         tmpfsoa = 0.0_r8 ; tmpfpom = 0.0_r8 ; tmpfbcx = 0.0_r8
         tmpfncl = 0.0_r8 ; tmpfdst = 0.0_r8
         tmpfno3 = 0.0_r8 ; tmpfclx = 0.0_r8
         tmpfcax = 0.0_r8 ; tmpfco3 = 0.0_r8

         tmpfncl = 0.5_r8 ; tmpfdst = 0.5_r8

         if (l_so4a > 0) q(i,k,l_so4a) = (tmpvol*tmpdens)*tmpfso4
         if (l_nh4a > 0) q(i,k,l_nh4a) = (tmpvol*tmpdens)*tmpfnh4
         if (l_soaa > 0) q(i,k,l_soaa) = (tmpvol*tmpdens)*tmpfsoa
         if (l_poma > 0) q(i,k,l_poma) = (tmpvol*tmpdens)*tmpfpom
         if (l_bcxa > 0) q(i,k,l_bcxa) = (tmpvol*tmpdens)*tmpfbcx
         if (l_dsta > 0) q(i,k,l_dsta) = (tmpvol*tmpdens)*tmpfdst
         if (l_ncla > 0) q(i,k,l_ncla) = (tmpvol*tmpdens)*tmpfncl
         if (l_no3a > 0) q(i,k,l_no3a) = (tmpvol*tmpdens)*tmpfno3
         if (l_clxa > 0) q(i,k,l_clxa) = (tmpvol*tmpdens)*tmpfclx
         if (l_caxa > 0) q(i,k,l_caxa) = (tmpvol*tmpdens)*tmpfcax
         if (l_co3a > 0) q(i,k,l_co3a) = (tmpvol*tmpdens)*tmpfco3
      end do ! i
      end do ! k

      end if ! ( modeptr_coarse > 0 )



! set primary carbon mode number and masses
      if ( modeptr_pcarbon > 0 ) then

      n = modeptr_pcarbon
      l_numa = numptr_amode(n)
      l_so4a = lptr_so4_a_amode(n)
      l_nh4a = lptr_nh4_a_amode(n)
      l_soaa = lptr_soa_a_amode(n)
      l_poma = lptr_pom_a_amode(n)
      if (npoa == 2) l_poma = lptr_poma_a_amode(n)
      l_bcxa = lptr_bc_a_amode(n)
      if (nbc  == 2) l_bcxa = lptr_bca_a_amode(n)
      l_ncla = lptr_nacl_a_amode(n)
      l_dsta = lptr_dust_a_amode(n)
#if ( defined MOSAIC_SPECIES )
      l_no3a = lptr_no3_a_amode(n)
      l_clxa = lptr_cl_a_amode(n)
      l_caxa = lptr_ca_a_amode(n)
      l_co3a = lptr_co3_a_amode(n)
#else
      l_no3a = -1
      l_clxa = -1
      l_caxa = -1
      l_co3a = -1
#endif

      do k = 1, pver
      do i = 1, ncol
         tmpa = k*1.0/pver

         tmpfso4 = 0.0_r8 ; tmpfnh4 = 0.0_r8
         tmpfsoa = 0.0_r8 ; tmpfpom = 0.0_r8 ; tmpfbcx = 0.0_r8
         tmpfncl = 0.0_r8 ; tmpfdst = 0.0_r8
         tmpfno3 = 0.0_r8 ; tmpfclx = 0.0_r8
         tmpfcax = 0.0_r8 ; tmpfco3 = 0.0_r8


         if (mopt_aero_loadbb == 1 .or. &
             mopt_aero_loadbb == 2 .or. &
             mopt_aero_loadbb == 4 ) exit
         if (mopt_aero_loadbb == 8 ) exit
         if (mopt_aero_loadaa <= 0) then
            q(i,k,l_numa) = 1.0e6_r8*tmpa
         else if (mopt_aero_loadaa == 1) then
            q(i,k,l_numa) = 2.0e7_r8*tmpa
         else
            q(i,k,l_numa) = 5.0e8_r8*tmpa
         end if
         tmpvol = q(i,k,l_numa)/voltonumb_amode(n)

         if ( mopt_aero_comp <= 1 .or. &
              mopt_aero_comp == 3 .or. &
              mopt_aero_comp == 5 ) then
            tmpfbcx = 1.0_r8 ; tmpfpom = 0.0_r8
         else
            tmpfbcx = 0.1_r8 ; tmpfpom = 0.9_r8
         end if

         if (l_so4a > 0) q(i,k,l_so4a) = (tmpvol*tmpdens)*tmpfso4
         if (l_nh4a > 0) q(i,k,l_nh4a) = (tmpvol*tmpdens)*tmpfnh4
         if (l_soaa > 0) q(i,k,l_soaa) = (tmpvol*tmpdens)*tmpfsoa
         if (l_poma > 0) q(i,k,l_poma) = (tmpvol*tmpdens)*tmpfpom
         if (l_bcxa > 0) q(i,k,l_bcxa) = (tmpvol*tmpdens)*tmpfbcx
         if (l_dsta > 0) q(i,k,l_dsta) = (tmpvol*tmpdens)*tmpfdst
         if (l_ncla > 0) q(i,k,l_ncla) = (tmpvol*tmpdens)*tmpfncl
         if (l_no3a > 0) q(i,k,l_no3a) = (tmpvol*tmpdens)*tmpfno3
         if (l_clxa > 0) q(i,k,l_clxa) = (tmpvol*tmpdens)*tmpfclx
         if (l_caxa > 0) q(i,k,l_caxa) = (tmpvol*tmpdens)*tmpfcax
         if (l_co3a > 0) q(i,k,l_co3a) = (tmpvol*tmpdens)*tmpfco3
      end do ! i
      end do ! k

      end if ! ( modeptr_pcarbon > 0 )



! set number and masses for fine & coarse sea-salt and dust modes
      if ( ntot_amode >= 7 ) then

      do n = 4, 7

      cycle

      l_numa = numptr_amode(n)
      l_so4a = lptr_so4_a_amode(n)
      l_nh4a = lptr_nh4_a_amode(n)
      l_soaa = lptr_soa_a_amode(n)
      l_poma = lptr_pom_a_amode(n)
      if (npoa == 2) l_poma = lptr_poma_a_amode(n)
      l_bcxa = lptr_bc_a_amode(n)
      if (nbc  == 2) l_bcxa = lptr_bca_a_amode(n)
      l_ncla = lptr_nacl_a_amode(n)
      l_dsta = lptr_dust_a_amode(n)
#if ( defined MOSAIC_SPECIES )
      l_no3a = lptr_no3_a_amode(n)
      l_clxa = lptr_cl_a_amode(n)
      l_caxa = lptr_ca_a_amode(n)
      l_co3a = lptr_co3_a_amode(n)
#else
      l_no3a = -1
      l_clxa = -1
      l_caxa = -1
      l_co3a = -1
#endif

      do k = 1, pver
      do i = 1, ncol
         tmpa = k*1.0/pver

         tmpfso4 = 0.0_r8 ; tmpfnh4 = 0.0_r8
         tmpfsoa = 0.0_r8 ; tmpfpom = 0.0_r8 ; tmpfbcx = 0.0_r8
         tmpfncl = 0.0_r8 ; tmpfdst = 0.0_r8
         tmpfno3 = 0.0_r8 ; tmpfclx = 0.0_r8
         tmpfcax = 0.0_r8 ; tmpfco3 = 0.0_r8

         if (mopt_aero_loadbb <= 6 ) exit
         if (mopt_aero_loadbb == 8 .and. l_dsta <= 0 ) exit

         if (mopt_aero_loadaa <= 0) then
            q(i,k,l_numa) = 1.0e3_r8*tmpa
         else if (mopt_aero_loadaa == 1) then
            q(i,k,l_numa) = 1.0e4_r8*tmpa
         else
            q(i,k,l_numa) = 2.5e4_r8*tmpa
         end if
         tmpvol = q(i,k,l_numa)/voltonumb_amode(n)

         if (l_dsta > 0) then
            tmpfdst = 1.0_r8
            if ( mopt_aero_comp == 11 ) then
               tmpfcax = tmpfdst*0.1*0.40043_r8
               tmpfco3 = tmpfdst*0.1*(1.0_r8 - 0.40043_r8)
               tmpfdst = tmpfdst - (tmpfcax + tmpfco3)
            end if
         else
            tmpfncl = 1.0_r8 
            if ( mopt_aero_comp == 11 ) then
               tmpfclx = tmpfncl*0.60663_r8
               tmpfncl = tmpfncl - tmpfclx
            end if
         end if

         if (l_so4a > 0) q(i,k,l_so4a) = (tmpvol*tmpdens)*tmpfso4
         if (l_nh4a > 0) q(i,k,l_nh4a) = (tmpvol*tmpdens)*tmpfnh4
         if (l_soaa > 0) q(i,k,l_soaa) = (tmpvol*tmpdens)*tmpfsoa
         if (l_poma > 0) q(i,k,l_poma) = (tmpvol*tmpdens)*tmpfpom
         if (l_bcxa > 0) q(i,k,l_bcxa) = (tmpvol*tmpdens)*tmpfbcx
         if (l_dsta > 0) q(i,k,l_dsta) = (tmpvol*tmpdens)*tmpfdst
         if (l_ncla > 0) q(i,k,l_ncla) = (tmpvol*tmpdens)*tmpfncl
         if (l_no3a > 0) q(i,k,l_no3a) = (tmpvol*tmpdens)*tmpfno3
         if (l_clxa > 0) q(i,k,l_clxa) = (tmpvol*tmpdens)*tmpfclx
         if (l_caxa > 0) q(i,k,l_caxa) = (tmpvol*tmpdens)*tmpfcax
         if (l_co3a > 0) q(i,k,l_co3a) = (tmpvol*tmpdens)*tmpfco3
      end do ! i
      end do ! k

      end do ! n = 4, 7

      end if ! ntot_amode >= 7


!
! set qqcw
!
      do n = 1, ntot_amode
         if (i_cldy_sameas_clear > 0) exit
         if (n == modeptr_pcarbon) then
            cycle
         else if (n == modeptr_aitken) then
            tmpfnact = 0.4
            tmpfmact = 0.6
         else
            tmpfnact = 0.7
            tmpfmact = 0.8
         end if

         do k = 1, pver
         do i = 1, ncol
            if (cld(i,k) <= 0.00999999_r8) cycle
            do ll = 0, nspec_amode(n)
               if (ll == 0) then
                  l = numptr_amode(n)
               else
                  l = lmassptr_amode(ll,n)
               end if
               if (l <= 0 .or. l > pcnst) cycle
               if (ll == 0) then
                  tmpq = q(i,k,l)*cld(i,k)*tmpfnact
               else
                  tmpq = q(i,k,l)*cld(i,k)*tmpfmact
               end if
               qqcw(i,k,l) = max( 0.0_r8, tmpq )
               q(i,k,l) = max( 0.0_r8, q(i,k,l) - tmpq )
            end do ! ll
         end do ! i
         end do ! k
      end do ! n

      lun = 6
      do i = 1, ncol
      lun = 29+i
      if (iwrite3x_units_flagaa >= 10) then
         tmpch80 = '  (nmol/mol & #/mg)'
         tmpa = 1.0e9*mwdry/adv_mass(l_so4_a1-(imozart-1))
      else
         tmpch80 = ' '
         tmpa = 1.0e9
      end if
      write(lun,'(/3a)') &
         'k, zm, pmid, tc, pblh, cld, relhum, qv, ', &
         'so2, accum num & so4, aitken num & so4 icol=1', trim(tmpch80)
      do k = 1, pver
      write(lun,'(/i4,1p,12e10.2)') k, &
         zm(i,k)*0.001, pmid(i,k)*0.01, t(i,k)-273.16, &
         pblh(i)*0.001, cld(i,k), relhum(i,k), qv(i,k)*1000.0, &
         q(i,k,l_so2g)*1.0e9, &
         q(i,k,l_num_a1)*1.0e-6, q(i,k,l_so4_a1)*tmpa, &
         q(i,k,l_num_a2)*1.0e-6, q(i,k,l_so4_a2)*tmpa
      end do
      end do ! i

      write(*,'(/a)') 'cambox_init_run all done'

      return
      end subroutine cambox_init_run


!-------------------------------------------------------------------------------
      subroutine cambox_do_run( &
         ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens        )

      use shr_kind_mod, only: r8 => shr_kind_r8
      use abortutils, only: endrun
      use cam_logfile, only: iulog
      use chem_mods, only: adv_mass, gas_pcnst, imozart
      use physconst, only: mwdry
      use ppgrid, only: pcols, pver
      use physics_types, only: physics_state, physics_ptend
      use physics_buffer, only: physics_buffer_desc

      use modal_aero_data
      use modal_aero_calcsize, only: modal_aero_calcsize_sub
      use modal_aero_amicphys, only: modal_aero_amicphys_intr, &
          gaexch_h2so4_uptake_optaa, newnuc_h2so4_conc_optaa, mosaic
      use modal_aero_wateruptake, only: modal_aero_wateruptake_dr
      use gaschem_simple, only: gaschem_simple_sub
      use cloudchem_simple, only: cloudchem_simple_sub

!     implicit none

      integer,  intent(in   ) :: ncol
      integer,  intent(in   ) :: nstop

      real(r8), intent(in   ) :: deltat
      real(r8), intent(in   ) :: t(pcols,pver)      ! Temperature in Kelvin
      real(r8), intent(in   ) :: pmid(pcols,pver)   ! pressure at model levels (Pa)
      real(r8), intent(in   ) :: pdel(pcols,pver)   ! pressure thickness of levels
      real(r8), intent(in   ) :: zm(pcols,pver)     ! midpoint height above surface (m)
      real(r8), intent(in   ) :: pblh(pcols)        ! pbl height (m)
      real(r8), intent(in   ) :: cld(pcols,pver)    ! stratiform cloud fraction
      real(r8), intent(in   ) :: relhum(pcols,pver) ! layer relative humidity
      real(r8), intent(in   ) :: qv(pcols,pver)     ! layer specific humidity

      real(r8), intent(inout) :: q(pcols,pver,pcnst)     ! Tracer MR array
      real(r8), intent(inout) :: qqcw(pcols,pver,pcnst)  ! Cloudborne aerosol MR array
      real(r8), intent(inout) :: dgncur_a(pcols,pver,ntot_amode)
      real(r8), intent(inout) :: dgncur_awet(pcols,pver,ntot_amode)
      real(r8), intent(inout) :: qaerwat(pcols,pver,ntot_amode)
      real(r8), intent(inout) :: wetdens(pcols,pver,ntot_amode)

      integer, parameter :: nqtendbb = 4
      integer, parameter :: iqtend_cond = 1
      integer, parameter :: iqtend_rnam = 2
      integer, parameter :: iqtend_nnuc = 3
      integer, parameter :: iqtend_coag = 4
      integer, parameter :: nqqcwtendbb = 1
      integer, parameter :: iqqcwtend_rnam = 1

      integer :: i, icalcaer_flag, iwaterup_flag
      integer :: istep
      integer :: itmpa, itmpb
      integer :: k
      integer :: l, l2, ll
      integer :: l_h2so4g, l_nh3g,  l_so2g, l_hno3g, l_hclg
      integer :: l_num_a1, l_nh4_a1, l_so4_a1
      integer :: l_num_a2, l_nh4_a2, l_so4_a2
      integer :: lmz_h2so4g, lmz_nh3g,  lmz_so2g, lmz_hno3g, lmz_hclg
      integer :: lmz_num_a1, lmz_nh4_a1, lmz_so4_a1
      integer :: lmz_num_a2, lmz_nh4_a2, lmz_so4_a2
      integer :: lchnk, loffset, lun
      integer :: latndx(pcols), lonndx(pcols)
      integer :: n, nacc, nait, nstep

      logical :: aero_mmr_flag
      logical :: h2o_mmr_flag
      logical :: dotend(pcnst)

      character(len=80) :: tmpch80

      real(r8) :: cld_ncol(ncol,pver)
      real(r8) :: del_h2so4_aeruptk(ncol,pver)
      real(r8) :: del_h2so4_gasprod(ncol,pver)
      real(r8) :: dqdt(pcols,pver,pcnst)        ! Tracer MR tendency array
      real(r8) :: dvmrdt_bb(ncol,pver,gas_pcnst,nqtendbb)   ! mixing ratio changes
      real(r8) :: dvmrcwdt_bb(ncol,pver,gas_pcnst,nqqcwtendbb) ! mixing ratio changes
      real(r8) :: dvmrdt_cond(ncol,pver,gas_pcnst)   ! mixing ratio changes from renaming 
      real(r8) :: dvmrcwdt_cond(ncol,pver,gas_pcnst) ! mixing ratio changes from renaming 
      real(r8) :: dvmrdt_nnuc(ncol,pver,gas_pcnst)   ! mixing ratio changes from renaming 
      real(r8) :: dvmrcwdt_nnuc(ncol,pver,gas_pcnst) ! mixing ratio changes from renaming 
      real(r8) :: dvmrdt_coag(ncol,pver,gas_pcnst)   ! mixing ratio changes from renaming 
      real(r8) :: dvmrcwdt_coag(ncol,pver,gas_pcnst) ! mixing ratio changes from renaming 
      real(r8) :: dvmrdt_rnam(ncol,pver,gas_pcnst)   ! mixing ratio changes from renaming 
      real(r8) :: dvmrcwdt_rnam(ncol,pver,gas_pcnst) ! mixing ratio changes from renaming 
      real(r8) :: h2so4_pre_gaschem(ncol,pver) ! grid-avg h2so4(g) mix ratio before gas chem (mol/mol)
      real(r8) :: h2so4_aft_gaschem(ncol,pver) ! grid-avg h2so4(g) mix ratio after  gas chem (mol/mol)
      real(r8) :: h2so4_clear_avg(  ncol,pver) ! average clear sub-area h2so4(g) mix ratio (mol/mol)
      real(r8) :: h2so4_clear_fin(  ncol,pver) ! final   clear sub-area h2so4(g) mix ratio (mol/mol)
      real(r8) :: mmr(ncol,pver,gas_pcnst)     ! gas & aerosol mass   mixing ratios
      real(r8) :: mmrcw(ncol,pver,gas_pcnst)   ! gas & aerosol mass   mixing ratios
      real(r8) :: tau_gaschem_simple(ncol,pver)
      real(r8) :: tmpa, tmpb, tmpc
      real(r8) :: tmpveca(999)
      real(r8) :: told, tnew
      real(r8) :: uptkrate_h2so4(   ncol,pver) ! h2so4(g) uptake (by aerosols) rate (1/s)
      real(r8) :: vmr(ncol,pver,gas_pcnst)     ! gas & aerosol volume mixing ratios
      real(r8) :: vmr_svaa(ncol,pver,gas_pcnst)
      real(r8) :: vmr_svbb(ncol,pver,gas_pcnst)
      real(r8) :: vmr_svcc(ncol,pver,gas_pcnst)
      real(r8) :: vmr_svdd(ncol,pver,gas_pcnst)
      real(r8) :: vmr_svee(ncol,pver,gas_pcnst)
      real(r8) :: vmrcw(ncol,pver,gas_pcnst)   ! gas & aerosol volume mixing ratios
      real(r8) :: vmrcw_svaa(ncol,pver,gas_pcnst)
      real(r8) :: vmrcw_svbb(ncol,pver,gas_pcnst)
      real(r8) :: vmrcw_svcc(ncol,pver,gas_pcnst)
      real(r8) :: vmrcw_svdd(ncol,pver,gas_pcnst)
      real(r8) :: vmrcw_svee(ncol,pver,gas_pcnst)

!     type(physics_state), target, intent(in)    :: state       ! Physics state variables
!     type(physics_ptend), target, intent(inout) :: ptend       ! indivdual parameterization tendencies
      type(physics_state)                        :: state       ! Physics state variables
      type(physics_ptend)                        :: ptend       ! indivdual parameterization tendencies
      type(physics_buffer_desc),   pointer       :: pbuf(:)     ! physics buffer

      real(r8) :: scr(30)
      integer, parameter :: tempunit=29

      lchnk = 1

      cld_ncol(1:ncol,:) = cld(1:ncol,:)

      latndx = -1
      lonndx = -1

      call cnst_get_ind( 'H2SO4', l_h2so4g, .false. )
      call cnst_get_ind( 'SO2',   l_so2g,   .false. )
      call cnst_get_ind( 'NH3',   l_nh3g,   .false. )
      call cnst_get_ind( 'HNO3',  l_hno3g,  .false. )
      call cnst_get_ind( 'HCL',   l_hclg,   .false. )

      nacc = modeptr_accum
      l_num_a1 = numptr_amode(nacc)
      l_so4_a1 = lptr_so4_a_amode(nacc)
      l_nh4_a1 = lptr_nh4_a_amode(nacc)

      nait = modeptr_aitken
      l_num_a2 = numptr_amode(nait)
      l_so4_a2 = lptr_so4_a_amode(nait)
      l_nh4_a2 = lptr_nh4_a_amode(nait)

      lmz_h2so4g = l_h2so4g - (imozart-1)
      lmz_so2g   = l_so2g   - (imozart-1)
      lmz_nh3g   = l_nh3g   - (imozart-1)
      lmz_hno3g  = l_hno3g  - (imozart-1)
      lmz_hclg   = l_hclg   - (imozart-1)

      lmz_num_a1 = l_num_a1 - (imozart-1)
      lmz_so4_a1 = l_so4_a1 - (imozart-1)
      lmz_nh4_a1 = l_nh4_a1 - (imozart-1)

      lmz_num_a2 = l_num_a2 - (imozart-1)
      lmz_so4_a2 = l_so4_a2 - (imozart-1)
      lmz_nh4_a2 = l_nh4_a2 - (imozart-1)

      write(*,'(/a,3i5)') 'l_h2so4g, l_so2g,   l_nh3g  ', l_h2so4g, l_so2g,   l_nh3g
      write(*,'( a,3i5)') 'l_num_a1, l_so4_a1, l_nh4_a1', l_num_a1, l_so4_a1, l_nh4_a1
      write(*,'( a,3i5)') 'l_num_a2, l_so4_a2, l_nh4_a2', l_num_a2, l_so4_a2, l_nh4_a2


main_time_loop: &
      do nstep = 1, nstop
      istep = nstep
      if (nstep == 1) tnew = 0.0_r8
      told = tnew
      tnew = told + deltat

      write(lun_outfld,'(/a,i5,2f10.3)') 'istep, told, tnew (h) = ', &
         istep, told/3600.0_r8, tnew/3600.0_r8


!
! calcsize
!
      lun = 6
      write(lun,'(/a,i8)') 'cambox_do_run doing calcsize, istep=', istep
      loffset = 0
      icalcaer_flag = 1
      aero_mmr_flag = .true.

      dotend = .false.
      dqdt = 0.0_r8

! *** old calcsize interface ***

!
!!...routine modal_aero_calcsize_sub( &
!!   lchnk, ncol, t, pmid, pdel, q, &
!!   dotend, dqdt, &
!!   qqcw, dgncur_a, &
!!   deltat, do_adjust_in, &
!!   do_aitacc_transfer_in)
!      call modal_aero_calcsize_sub(                &
!         lchnk,   ncol,                            &
!         t,       pmid,    pdel,    q,             &
!         dotend,           dqdt,                   &
!         qqcw,             dgncur_a,               &
!         deltat,                                   &
!         do_adjust_in=.true.,                      &
!         do_aitacc_transfer_in=.true.              )

! *** new calcsize interface ***

! load state
      state%lchnk = lchnk
      state%ncol = ncol
      state%t = t
      state%pmid = pmid
      state%pdel = pdel
      state%q = q
! load ptend
      ptend%lq = dotend
      ptend%q = dqdt
! load pbuf
      call load_pbuf( &
         ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens        )

! call calcsize
!     subr modal_aero_calcsize_sub( state, ptend, deltat, pbuf, &
!        do_adjust_in, do_aitacc_transfer_in )
      call modal_aero_calcsize_sub( state, ptend, deltat, pbuf, &
         do_adjust_in=.true., do_aitacc_transfer_in=.true. )

! unload ptend
      dotend = ptend%lq
      dqdt = ptend%q
! unload pbuf
      call unload_pbuf( &
         ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens        )
      
! apply tendencies
      itmpb = 0
      do l = 1, pcnst
         itmpa = 0
         if ( .not. dotend(l) ) cycle
         do k = 1, pver
         do i = 1, ncol
            if (abs(dqdt(i,k,l)) > 1.0e-30_r8) then
!              write(lun,'(2a,2i4,1p,2e10.2)') &
!                 'calcsize tend > 0   ', cnst_name(l), i, k, &
!                 q(i,k,l), dqdt(i,k,l)*deltat
               itmpa = itmpa + 1
            end if
            q(i,k,l) = q(i,k,l) + dqdt(i,k,l)*deltat
            q(i,k,l) = max( q(i,k,l), 0.0_r8 )
         end do
         end do
         if (itmpa > 0) then
            write(lun,'(2a,i7)') &
               'calcsize tend > 0   ', cnst_name(l), itmpa
            itmpb = itmpb + 1
         end if
      end do
      if (itmpb > 0) then
         write(lun,'(a,i7)') 'calcsize tend > 0 for nspecies =', itmpb
      else
         write(lun,'(a,i7)') 'calcsize tend = 0 for all species'
      end if

      open(tempunit,file="temp0")

      do i = 1, ncol
      lun = tempunit + i
      write(lun,'(/a,i8)') 'cambox_do_run doing calcsize, istep=', istep
      if (itmpb > 0) then
         write(lun,'(a,i7)') 'calcsize tend > 0 for nspecies =', itmpb
      else
         write(lun,'(a,i7)') 'calcsize tend = 0 for all species'
      end if
      if (iwrite3x_units_flagaa >= 10) then
         tmpch80 = '  (#/mg,  nmol/mol,  nm)'
         tmpa = 1.0e9*mwdry/adv_mass(lmz_so4_a1)
      else
         tmpch80 = '  (#/mg,  ug/kg,  nm)'
         tmpa = 1.0e9
      end if
      
      write(lun,'( 2a)') &
         'k, accum num, so4, dgncur_a, same for aitken', trim(tmpch80)
      do k = 1, pver
         if(TESTING==0) then
            write(tempunit,*)q(i,k,l_num_a1), q(i,k,l_so4_a1), dgncur_a(i,k,nacc), &
                 q(i,k,l_num_a2), q(i,k,l_so4_a2), dgncur_a(i,k,nait)
         else
            read(tempunit,*)scr(1),scr(2),scr(3),scr(4), scr(5),scr(6)
            if(.not.((q(i,k,l_num_a1)==scr(1)).and. &
                 & (q(i,k,l_so4_a1)==scr(2)).and. &
                 & (dgncur_a(i,k,nacc)==scr(3)).and. &
                 & (q(i,k,l_num_a2)==scr(4)).and. &
                 & (q(i,k,l_so4_a2)==scr(5)).and. &
                 & (dgncur_a(i,k,nait)==scr(6)))) then
               write(*,*)q(i,k,l_num_a1),scr(1), &
                  q(i,k,l_so4_a1),scr(2), &
                  dgncur_a(i,k,nacc),scr(3), &
                  q(i,k,l_num_a2),scr(4), &
                  q(i,k,l_so4_a2),scr(5), &
                  dgncur_a(i,k,nait),scr(6) 
               call endrun( 'Stop at first' )
            end if

         endif
!!$      write(lun,'( i4,1p,4(2x,3e12.4))') k, &
!!$         q(i,k,l_num_a1)*1.0e-6, q(i,k,l_so4_a1)*tmpa, dgncur_a(i,k,nacc)*1.0e9, &
!!$         q(i,k,l_num_a2)*1.0e-6, q(i,k,l_so4_a2)*tmpa, dgncur_a(i,k,nait)*1.0e9

      write(lun,'( i4,1p,4(2x,3e12.4))') k, &
         q(i,k,l_num_a1), q(i,k,l_so4_a1), dgncur_a(i,k,nacc), &
         q(i,k,l_num_a2), q(i,k,l_so4_a2), dgncur_a(i,k,nait)

      end do
      end do ! i
!
! watruptake
!
      lun = 6
      write(lun,'(/a,i8)') 'cambox_do_run doing wateruptake, istep=', istep
      loffset = 0
      iwaterup_flag = 1
      aero_mmr_flag = .true.
      h2o_mmr_flag = .true.

      dotend = .false.
      dqdt = 0.0_r8

! *** old wateruptake interface ***

!!ubroutine modal_aero_wateruptake_dr(          &
!!     lchnk, ncol,                             &
!!     h2ommr, t, pmid, cldn, raer,             &
!!     dgnum_a, dgnumwet, qaerwater, wetdensity )
!
!      call modal_aero_wateruptake_dr(          &
!      i_cldy_sameas_clear,                     &
!      lchnk, ncol,                             &
!      qv,     t, pmid, cld,  q,                &
!      dgncur_a, dgncur_awet, qaerwat, wetdens  )

! *** new wateruptake interface ***

! load state
      state%lchnk = lchnk
      state%ncol = ncol
      state%t = t
      state%pmid = pmid
      state%pdel = pdel
      state%q = q
! load ptend
      ptend%lq = dotend
      ptend%q = dqdt
! load pbuf
      call load_pbuf( &
         ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens        )

! call wateruptake
      call modal_aero_wateruptake_dr( state, pbuf )

! unload ptend
      dotend = ptend%lq
      dqdt = ptend%q
! unload pbuf
      call unload_pbuf( &
         ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens        )
      
! following line involving dotend and dqdt are no longer needed !
      lun = 6
      itmpb = 0
      do l = 1, pcnst
         itmpa = 0
         if ( .not. dotend(l) ) cycle
         do k = 1, pver
         do i = 1, ncol
            if (abs(dqdt(i,k,l)) > 1.0e-30_r8) then
!              write(lun,'(2a,2i4,1p,2e10.2)') &
!                 'watruptk tend > 0   ', cnst_name(l), i, k, &
!                 q(i,k,l), dqdt(i,k,l)*deltat
               itmpa = itmpa + 1
            end if
            q(i,k,l) = q(i,k,l) + dqdt(i,k,l)*deltat
            q(i,k,l) = max( q(i,k,l), 0.0_r8 )
         end do
         end do
         if (itmpa > 0) then
            write(lun,'(2a,i7)') &
               'watruptk tend > 0   ', cnst_name(l), itmpa
            itmpb = itmpb + 1
         end if
      end do
      if (itmpb > 0) then
         write(lun,'(a,i7)') 'watruptk tend > 0 for nspecies =', itmpb
      else
         write(lun,'(a,i7)') 'watruptk tend = 0 for all species'
      end if

      do i = 1, ncol
      lun = tempunit + i
      write(lun,'(/a,i8)') 'cambox_do_run doing wateruptake, istep=', istep
      if (itmpb > 0) then
         write(lun,'(a,i7)') 'watruptk tend > 0 for nspecies =', itmpb
      else
         write(lun,'(a,i7)') 'watruptk tend = 0 for all species'
      end if
      if (iwrite3x_units_flagaa >= 10) then
         tmpch80 = '  (#/mg,  nmol/mol,  nm,  g/cm3)'
         tmpa = 1.0e9*mwdry/adv_mass(lmz_so4_a1)
         tmpb = 1.0e9*mwdry/18.0
      else
         tmpch80 = '  (#/mg,  ug/kg,  nm)'
         tmpa = 1.0e9 ; tmpb = 1.0e9
      end if
      write(lun,'( 2a)') &
         'k, accum num, so4, watr, dgncur_a, dgncur_awet, wetdens', &
         trim(tmpch80)

      do k = 1, pver
         if(TESTING==0)then
            write(tempunit,*)q(i,k,l_num_a1),&
                 q(i,k,l_so4_a1),qaerwat(i,k,nacc), & 
                 dgncur_a(i,k,nacc), dgncur_awet(i,k,nacc), &
                 wetdens(i,k,nacc)
         else
            read(tempunit,*)scr(1),scr(2),scr(3),scr(4),scr(5),scr(6)
            if(.not.((q(i,k,l_num_a1)==scr(1)).and.&
                 (q(i,k,l_so4_a1)==scr(2)).and.&
                 (qaerwat(i,k,nacc)==scr(3)).and.& 
                 (dgncur_a(i,k,nacc)==scr(4)).and.&
                 (dgncur_awet(i,k,nacc)==scr(5)).and. &
                 (wetdens(i,k,nacc)==scr(6))))then
               write(*,*)q(i,k,l_num_a1),scr(1),&
                    q(i,k,l_so4_a1),scr(2),&
                    qaerwat(i,k,nacc),scr(3),& 
                    dgncur_a(i,k,nacc),scr(4),&
                    dgncur_awet(i,k,nacc),scr(5), &
                    wetdens(i,k,nacc),scr(6)
               call endrun( 'Stop at second' )
            end if
         end if
         
      write(lun,'( i4,1p,4(2x,3e12.4))') k, &
         q(i,k,l_num_a1)*1.0e-6, q(i,k,l_so4_a1)*tmpa, qaerwat(i,k,nacc)*tmpb, &
         dgncur_a(i,k,nacc)*1.0e9, dgncur_awet(i,k,nacc)*1.0e9, &
         wetdens(i,k,nacc)*1.0e-3
      end do

      write(lun,'( 2a)') &
         'k, aitken num, so4, watr, dgncur_a, dgncur_awet, wetdens', &
         trim(tmpch80)
      do k = 1, pver
      write(lun,'( i4,1p,4(2x,3e12.4))') k, &
         q(i,k,l_num_a2)*1.0e-6, q(i,k,l_so4_a2)*tmpa, qaerwat(i,k,nait)*tmpb, &
         dgncur_a(i,k,nait)*1.0e9, dgncur_awet(i,k,nait)*1.0e9, &
         wetdens(i,k,nait)*1.0e-3
      end do

      end do ! i

!
! switch from q & qqcw to vmr and vmrcw
!
      loffset = imozart - 1
      mmr = 0.0_r8
      mmrcw = 0.0_r8
      vmr = 0.0_r8
      vmrcw = 0.0_r8
      do l = imozart, pcnst
         l2 = l - loffset
         mmr(  1:ncol,1:pver,l2) = q(  1:ncol,1:pver,l)
         mmrcw(1:ncol,1:pver,l2) = qqcw(1:ncol,1:pver,l)
         vmr(  1:ncol,1:pver,l2) = mmr(  1:ncol,1:pver,l2)*mwdry/adv_mass(l2)
         vmrcw(1:ncol,1:pver,l2) = mmrcw(1:ncol,1:pver,l2)*mwdry/adv_mass(l2)
      end do

!
! output
!
      do lun = 40, 40+ncol-1
         write(lun,'(a,6i5)') &
            'mdo_gasch, cldch, gaex, rename, newnuc, coag', &
            mdo_gaschem, mdo_cloudchem, &
            mdo_gasaerexch, mdo_rename, mdo_newnuc, mdo_coag
         if (iwrite4x_heading_flagbb > 0) then
            write(lun,'(2a,3i5,l5)') &
            'mopt_h2so4_uptake, gaexch_h2so4_uptake_flagaa, ', &
            'newnuc_h2so4_conc_flagaa, mosaic', &
             mopt_h2so4_uptake, gaexch_h2so4_uptake_optaa, &
             newnuc_h2so4_conc_optaa, mosaic
         else
            if (mopt_h2so4_uptake /= 1) write(lun,'(a,6i5)') &
               'mopt_h2so4_uptake', mopt_h2so4_uptake
         end if
         write(lun,'(a,6i5)') &
            'mopt_aero_comp, aero_load, ait_size', &
            mopt_aero_comp, mopt_aero_load, mopt_ait_size
         write(lun,'(a,2f14.6)') &
            'deltat, xopt_cloudf', &
            deltat, xopt_cloudf
      end do

!     call dump4x( 'start', ncol, nstep, vmr, vmrcw, vmr, vmrcw )

!
! gaschem_simple
!
      lun = 6
      write(lun,'(/a,i8)') 'cambox_do_run doing gaschem simple, istep=', istep
      vmr_svaa = vmr
      vmrcw_svaa = vmrcw
      h2so4_pre_gaschem(1:ncol,:) = vmr(1:ncol,:,lmz_h2so4g)

! global avg ~= 13 d = 1.12e6 s, daytime avg ~= 5.6e5, noontime peak ~= 3.7e5
      tau_gaschem_simple = 3.0e5  ! so2 gas-rxn timescale (s)

      if (mdo_gaschem > 0) then
      call gaschem_simple_sub(                       &
         lchnk,    ncol,     nstep,               &
         loffset,  deltat,                        &
         vmr,                tau_gaschem_simple      )
      end if

      h2so4_aft_gaschem(1:ncol,:) = vmr(1:ncol,:,lmz_h2so4g)

      do i = 1, ncol
      lun = tempunit + i
      write(lun,'(/a,i8)') 'cambox_do_run doing gaschem simple, istep=', istep
      if (iwrite3x_units_flagaa >= 10) then
         tmpch80 = '(nmol/mol)'
      else
         tmpch80 = '(ppbv)'
      end if
      write(lun,'(2a)') &
         'k, old & new so2, old & new h2so4  ', trim(tmpch80)
      do k = 1, pver
      write(lun,'( i4,1p,6(2x,2e12.4))') k, &
         vmr_svaa(i,k,lmz_so2g)*1.0e9, vmr(i,k,lmz_so2g)*1.0e9, &
         vmr_svaa(i,k,lmz_h2so4g)*1.0e9, vmr(i,k,lmz_h2so4g)*1.0e9
      if(TESTING==0)then
         write(tempunit,*)vmr_svaa(i,k,lmz_so2g), vmr(i,k,lmz_so2g), &
         vmr_svaa(i,k,lmz_h2so4g), vmr(i,k,lmz_h2so4g)
      else
         read(tempunit,*)scr(1),scr(2),scr(3),scr(4)
         if(.not.((vmr_svaa(i,k,lmz_so2g)==scr(1)).and.&
              (vmr(i,k,lmz_so2g)==scr(2)).and.&
              (vmr_svaa(i,k,lmz_h2so4g)==scr(3)).and.&
              (vmr(i,k,lmz_h2so4g)==scr(4))))call endrun('stop at third')
      end if
      end do
      end do ! i


      call dump4x( 'gasch', ncol, nstep, vmr_svaa, vmrcw_svaa, vmr, vmrcw )


!
! cloudchem_simple
!
      lun = 6
      write(lun,'(/a,i8)') &
         'cambox_do_run doing cloudchem simple, istep=', istep
      vmr_svbb = vmr
      vmrcw_svbb = vmrcw

      if (mdo_cloudchem > 0 .and. maxval( cld_ncol(:,:) ) > 1.0e-6_r8) then

      call cloudchem_simple_sub(                  &
         lchnk,    ncol,     nstep,               &
         loffset,  deltat,                        &
         vmr,      vmrcw,    cld_ncol             )

      do i = 1, ncol
      lun = tempunit + i
      write(lun,'(/a,i8)') &
         'cambox_do_run doing cloudchem simple, istep=', istep

      if (iwrite3x_units_flagaa >= 10) then
         tmpch80 = '(nmol/mol)'
      else
         tmpch80 = '(ppbv)'
      end if
      write(lun,'(2a)') &
         'k, old & new so2, ... h2so4, ... so4_c1, ... so4_c2  ', trim(tmpch80)
      do k = 1, pver
      write(lun,'( i4,1p,6(2x,2e12.4))') k, &
         vmr_svbb(i,k,lmz_so2g)*1.0e9,     vmr(i,k,lmz_so2g)*1.0e9, &
         vmr_svbb(i,k,lmz_h2so4g)*1.0e9,   vmr(i,k,lmz_h2so4g)*1.0e9, &
         vmrcw_svbb(i,k,lmz_so4_a1)*1.0e9, vmrcw(i,k,lmz_so4_a1)*1.0e9, &
         vmrcw_svbb(i,k,lmz_so4_a2)*1.0e9, vmrcw(i,k,lmz_so4_a2)*1.0e9
      if(TESTING==0) then 
         write(tempunit,*)vmr_svbb(i,k,lmz_so2g), vmr(i,k,lmz_so2g), &
         vmr_svbb(i,k,lmz_h2so4g), vmr(i,k,lmz_h2so4g), &
         vmrcw_svbb(i,k,lmz_so4_a1),&
         vmrcw(i,k,lmz_so4_a1), &
         vmrcw_svbb(i,k,lmz_so4_a2), vmrcw(i,k,lmz_so4_a2)
      else
         read(tempunit,*)scr(1),scr(2),scr(3),scr(4),scr(5),scr(6),scr(7),scr(8)
         if(.not.((vmr_svbb(i,k,lmz_so2g)==scr(1)).and.&
              (vmr(i,k,lmz_so2g)==scr(2)).and.&
              (vmr_svbb(i,k,lmz_h2so4g)==scr(3)).and.&
              (vmr(i,k,lmz_h2so4g)==scr(4)).and.&
              (vmrcw_svbb(i,k,lmz_so4_a1)==scr(5)).and.&
              (vmrcw(i,k,lmz_so4_a1)==scr(6)).and.&
              (vmrcw_svbb(i,k,lmz_so4_a2)==scr(7)).and.&
              (vmrcw(i,k,lmz_so4_a2)==scr(8)))) call endrun("stop at 4a")
      end if

      end do
      if (lmz_nh3g > 0) then
      write(lun,'(2a)') &
         'k, old & new nh3, ... nh4_c1, ... nh4_c2  ', trim(tmpch80)
      do k = 1, pver
      write(lun,'( i4,1p,6(2x,2e12.4))') k, &
         vmr_svbb(i,k,lmz_nh3g)*1.0e9,     vmr(i,k,lmz_nh3g)*1.0e9, &
         vmrcw_svbb(i,k,lmz_nh4_a1)*1.0e9, vmrcw(i,k,lmz_nh4_a1)*1.0e9, &
         vmrcw_svbb(i,k,lmz_nh4_a2)*1.0e9, vmrcw(i,k,lmz_nh4_a2)*1.0e9
      if(TESTING==0)then
         write(tempunit,*) &
         vmr_svbb(i,k,lmz_nh3g),     vmr(i,k,lmz_nh3g), &
         vmrcw_svbb(i,k,lmz_nh4_a1), vmrcw(i,k,lmz_nh4_a1), &
         vmrcw_svbb(i,k,lmz_nh4_a2), vmrcw(i,k,lmz_nh4_a2)
      else
         read(tempunit,*)scr(1),scr(2),scr(3),scr(4),scr(5),scr(6)
         if(.not.((vmr_svbb(i,k,lmz_nh3g)==scr(1)).and.&
         (vmr(i,k,lmz_nh3g)==scr(2)).and.&
         (vmrcw_svbb(i,k,lmz_nh4_a1)==scr(3)).and.& 
         (vmrcw(i,k,lmz_nh4_a1)==scr(4)).and.&
         (vmrcw_svbb(i,k,lmz_nh4_a2)==scr(5)).and.& 
         (vmrcw(i,k,lmz_nh4_a2)==scr(6))))call endrun("stop at 4b")

      end if
      end do
      end if

      end do ! i

      call dump4x( 'cldch', ncol, nstep, vmr_svbb, vmrcw_svbb, vmr, vmrcw )

      end if ! (mdo_cloudchem > 0 .and. maxval( cld_ncol(:,:) ) > 1.0e-6_r8) then


!
! gasaerexch
!
      lun = 6
      write(lun,'(/a,i8)') 'cambox_do_run doing gasaerexch, istep=', istep
      vmr_svcc = vmr
      vmrcw_svcc = vmrcw

      dvmrdt_bb = 0.0_r8 ; dvmrcwdt_bb = 0.0_r8


!.....tine modal_aero_amicphys_intr(              &
!        mdo_gasaerexch,     mdo_rename,          &
!        mdo_newnuc,         mdo_coag,            &
!        lchnk,    ncol,     nstep,               &
!        loffset,  deltat,                        &
!        latndx,   lonndx,                        &
!        t,        pmid,     pdel,                &
!        zm,       pblh,                          &
!        qv,       cld,                           &
!        q,                  qqcw,                &
!        q_pregaschem,                            &
!        q_precldchem,       qqcw_precldchem,     &
!#if ( defined( CAMBOX_ACTIVATE_THIS ) )
!        nqtendbb,           nqqcwtendbb,         &
!        q_tendbb,           qqcw_tendbb,         &
!#endif
!        dgncur_a,           dgncur_awet,         &
!        wetdens,                                 &
!        qaerwat                                  )

      call modal_aero_amicphys_intr(              &
         mdo_gasaerexch,     mdo_rename,          &
         mdo_newnuc,         mdo_coag,            &
         lchnk,    ncol,     nstep,               &
         loffset,  deltat,                        &
         latndx,   lonndx,                        &
         t,        pmid,     pdel,                &
         zm,       pblh,                          &
         qv,       cld_ncol,                      &
         vmr,                vmrcw,               &   ! after  cloud chem
         vmr_svaa,                                &   ! before gas chem
         vmr_svbb,           vmrcw_svbb,          &   ! before cloud chem
         nqtendbb,           nqqcwtendbb,         &
         dvmrdt_bb,          dvmrcwdt_bb,         &
         dgncur_a,           dgncur_awet,         &
         wetdens                                  )



      dvmrdt_cond(  :,:,:) = dvmrdt_bb(  :,:,:,iqtend_cond)
      dvmrdt_rnam(  :,:,:) = dvmrdt_bb(  :,:,:,iqtend_rnam)
      dvmrdt_nnuc(  :,:,:) = dvmrdt_bb(  :,:,:,iqtend_nnuc)
      dvmrdt_coag(  :,:,:) = dvmrdt_bb(  :,:,:,iqtend_coag)
      dvmrcwdt_cond(:,:,:) = 0.0_r8
      dvmrcwdt_rnam(:,:,:) = dvmrcwdt_bb(:,:,:,iqqcwtend_rnam)
      dvmrcwdt_nnuc(:,:,:) = 0.0_r8
      dvmrcwdt_coag(:,:,:) = 0.0_r8


      lun = 6
      do i = 1, ncol
      lun = tempunit + i
      write(lun,'(/a,i8)') 'cambox_do_run doing gasaerexch, istep=', istep
      if (iwrite3x_units_flagaa >= 10) then
         tmpch80 = '  (nmol/mol)'
      else
         tmpch80 = '  (ppbv)'
      end if
      write(lun,'( 2a)') &
         'k, old & new h2so4, old & new so4_a1, old & new so4_a2', &
         trim(tmpch80)
      do k = 1, pver
      write(lun,'( i4,1p,6(2x,2e12.4))') k, &
         vmr_svcc(i,k,lmz_h2so4g)*1.0e9, vmr(i,k,lmz_h2so4g)*1.0e9, &
         vmr_svcc(i,k,lmz_so4_a1)*1.0e9, vmr(i,k,lmz_so4_a1)*1.0e9, &
         vmr_svcc(i,k,lmz_so4_a2)*1.0e9, vmr(i,k,lmz_so4_a2)*1.0e9
      if(TESTING==0)then
         write(tempunit,*)&
              vmr_svcc(i,k,lmz_h2so4g), vmr(i,k,lmz_h2so4g), &
              vmr_svcc(i,k,lmz_so4_a1), vmr(i,k,lmz_so4_a1), &
              vmr_svcc(i,k,lmz_so4_a2), vmr(i,k,lmz_so4_a2)
      else
         read(tempunit,*)scr(1),scr(2),scr(3),scr(4),scr(5),scr(6)
         if(.not.((vmr_svcc(i,k,lmz_h2so4g)==scr(1)).and.&
         (vmr(i,k,lmz_h2so4g)==scr(2)).and.&
         (vmr_svcc(i,k,lmz_so4_a1)==scr(3)).and.&
         (vmr(i,k,lmz_so4_a1)==scr(4)).and.&
         (vmr_svcc(i,k,lmz_so4_a2)==scr(5)).and.&
         (vmr(i,k,lmz_so4_a2)==scr(6))))call endrun("stop at 5")
      end if
      end do
      end do ! i


      i = 1 ; k = pver ; lun = 82
      tmpveca = 0.0_r8
      tmpveca(101) = vmr_svcc(i,k,lmz_h2so4g)
      tmpveca(201) = vmr(i,k,lmz_h2so4g)
      do n = 1, ntot_amode
         l = lptr_so4_a_amode(n) - loffset
         if (l > 0) tmpveca(110+n) = vmr_svcc(i,k,l)
         if (l > 0) tmpveca(210+n) = vmr(i,k,l)
      end do
      tmpveca(102) = sum( tmpveca(111:118) )
      tmpveca(103) = sum( tmpveca(101:102) )
      tmpveca(202) = sum( tmpveca(211:218) )
      tmpveca(203) = sum( tmpveca(201:202) )
      tmpveca = tmpveca*1.0e9_r8
      write(lun,'(/a,2i5)') 'h2so4g, so4a_tot, sum at i,k =', i, k
      write(lun,'(/a,1p,3e20.10,10e10.2)') 'before gasaerexch', tmpveca(101:103)
      write(lun,'(/a,1p,3e20.10,10e10.2)') 'after  gasaerexch', tmpveca(201:203)
      write(lun,'(/a,2i5)') 'so4a_1-8 at i,k =', i, k
      write(lun,'(/a,1p,3e20.10,10e10.2)') 'before gasaerexch', tmpveca(111:118)
      write(lun,'(/a,1p,3e20.10,10e10.2)') 'after  gasaerexch', tmpveca(211:218)

      call dump4x( 'gaex ', ncol, nstep, vmr_svcc, vmrcw_svcc, vmr, vmrcw )


!
! newnuc
!
      if ( 1 == 0 ) then
!     deleted all of this
      end if ! ( 1 == 0 )


!
! coag
!
      if ( 1 == 0 ) then
!     deleted all of this
      end if ! ( 1 == 0 )


!
! done
!
      lun = 6
      write(lun,'(/a,i8)') 'cambox_do_run step done, istep=', istep

      do i = 1, ncol
      lun = tempunit + i
      write(lun,'(/a,i8)') 'cambox_do_run step done, istep=', istep

      do k = 1, pver

      if (iwrite3x_units_flagaa >= 10) then
         tmpch80 = '   --   units = nmol/mol & #/mg'
      else
         tmpch80 = ' '
      end if
      write(lun,'(/a,2i5,2f10.3,a)') 'i, k, told, tnew (h)', i, k, &
         told/3600.0_r8, tnew/3600.0_r8, trim(tmpch80)
      write(lun,'(2a)') &
         'spec              qold       qnew         del-gas', &
         '   del-cloud del-rena    del-cond  del-nuc   del-coag'
      do l = 1, gas_pcnst
         if (iwrite3x_species_flagaa < 10) then
!           if (max( vmr_svaa(i,k,l), vmr(i,k,l) ) < 1.0e-35) cycle
            if (max( vmr_svaa(i,k,l), vmr_svbb(i,k,l), &
                     vmr_svcc(i,k,l), vmr(i,k,l) ) < 1.0e-35) cycle
         end if
         tmpb = adv_mass(l)
         if (abs(tmpb-1.0_r8) <= 0.1_r8) then
            tmpa = 1.0e-6 * tmpb/mwdry
         else
            tmpa = 1.0e9
         end if
         tmpveca(:) = 0.0
         tmpveca(1) = vmr_svaa(i,k,l)
         tmpveca(2) = vmr(     i,k,l)
         tmpveca(3) = vmr_svbb(i,k,l) - vmr_svaa(i,k,l)  ! gaschem
         tmpveca(4) = vmr_svcc(i,k,l) - vmr_svbb(i,k,l)  ! cloudchem

!        tmpveca(5) = dvmrdt_rename(i,k,l)*deltat        ! gasaerexch rename
!        tmpveca(6) = vmr_svdd(i,k,l) - vmr_svcc(i,k,l)  ! gasaerexch conden+rename
         tmpveca(5) = dvmrdt_rnam(i,k,l)*deltat          ! gasaerexch rename
         tmpveca(6) = dvmrdt_cond(i,k,l)*deltat          ! gasaerexch conden
         tmpveca(7) = dvmrdt_nnuc(i,k,l)*deltat          ! gasaerexch newnuc
         tmpveca(8) = dvmrdt_coag(i,k,l)*deltat          ! gasaerexch coagul
! following commented out lines were for old gasaerexch, where you started with 
! tmpveca(6) = vmr_svdd(i,k,l) - vmr_svcc(i,k,l)  ! gasaerexch conden+rename
!        tmpb = tmpveca(6)
!        tmpveca(6) = tmpveca(6) - tmpveca(5)
!        tmpc = max( abs(tmpveca(5)), abs(tmpb),1.0e-20_r8 )
!        if (abs(tmpveca(6)) < 1.0e-10*tmpc) tmpveca(6) = 0.0_r8

!        tmpveca(7) = vmr_svee(i,k,l) - vmr_svdd(i,k,l)  ! newnuc
!        tmpveca(8) = vmr(     i,k,l) - vmr_svee(i,k,l)  ! coag
         write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') &
            cnst_name(l+loffset), tmpveca(1:8)*tmpa
      end do ! l

      do l = 1, gas_pcnst
         if (max( vmrcw_svaa(i,k,l), vmrcw(i,k,l) ) < 1.0e-35) cycle
         tmpb = adv_mass(l)
         if (abs(tmpb-1.0_r8) <= 0.1_r8) then
            tmpa = 1.0e-6 * tmpb/mwdry
         else
            tmpa = 1.0e9
         end if
         tmpveca(:) = 0.0
         tmpveca(1) = vmrcw_svaa(i,k,l)
         tmpveca(2) = vmrcw(     i,k,l)
         tmpveca(3) = vmrcw_svbb(i,k,l) - vmrcw_svaa(i,k,l)  ! gaschem
         tmpveca(4) = vmrcw_svcc(i,k,l) - vmrcw_svbb(i,k,l)  ! cloudchem

!        tmpveca(5) = dvmrcwdt_rename(i,k,l)*deltat        ! gasaerexch rename
!        tmpveca(6) = vmrcw_svdd(i,k,l) - vmrcw_svcc(i,k,l)  ! gasaerexch conden+rename
         tmpveca(5) = dvmrcwdt_rnam(i,k,l)*deltat          ! gasaerexch rename
         tmpveca(6) = dvmrcwdt_cond(i,k,l)*deltat          ! gasaerexch conden
         tmpveca(7) = dvmrcwdt_nnuc(i,k,l)*deltat          ! gasaerexch newnuc
         tmpveca(8) = dvmrcwdt_coag(i,k,l)*deltat          ! gasaerexch coagul
! following commented out lines were for old gasaerexch, where you started with 
! tmpveca(6) = vmrcw_svdd(i,k,l) - vmrcw_svcc(i,k,l)  ! gasaerexch conden+rename
!        tmpb = tmpveca(6)
!        tmpveca(6) = tmpveca(6) - tmpveca(5)
!        tmpc = max( abs(tmpveca(5)), abs(tmpb),1.0e-20_r8 )
!        if (abs(tmpveca(6)) < 1.0e-10*tmpc) tmpveca(6) = 0.0_r8

!        tmpveca(7) = vmrcw_svee(i,k,l) - vmrcw_svdd(i,k,l)  ! newnuc
!        tmpveca(8) = vmrcw(     i,k,l) - vmrcw_svee(i,k,l)  ! coag
         tmpveca(9) = tmpveca(2) - tmpveca(1)
         write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,5e10.2)') &
            cnst_name_cw(l+loffset)(1:16), tmpveca(1:8)*tmpa
      end do ! l

      tmpveca(:) = 0.0
      tmpveca( 1) = vmr_svaa(i,k,lmz_so2g) + vmr_svaa(i,k,lmz_h2so4g)
      tmpveca( 2) = vmr(     i,k,lmz_so2g) + vmr(     i,k,lmz_h2so4g)
      if (lmz_nh3g > 0) then
      tmpveca(11) = vmr_svaa(i,k,lmz_nh3g)
      tmpveca(12) = vmr(     i,k,lmz_nh3g)
      end if
      l = lptr2_soa_g_amode(1) - loffset
      tmpveca(21) = vmr_svaa(i,k,l)
      tmpveca(22) = vmr(     i,k,l)
      if (lmz_hno3g > 0) then
      tmpveca(31) = vmr_svaa(i,k,lmz_hno3g)
      tmpveca(32) = vmr(     i,k,lmz_hno3g)
      end if
      if (lmz_hclg > 0) then
      tmpveca(41) = vmr_svaa(i,k,lmz_hclg)
      tmpveca(42) = vmr(     i,k,lmz_hclg)
      end if
      do n = 1, ntot_amode
         l = lptr_so4_a_amode(n) - loffset
         if (l > 0) then
            tmpveca( 1) = tmpveca( 1) + vmr_svaa(i,k,l) + vmrcw_svaa(i,k,l)
            tmpveca( 2) = tmpveca( 2) + vmr(     i,k,l) + vmrcw(     i,k,l)
         end if
         l = lptr_nh4_a_amode(n) - loffset
         if (l > 0) then
            tmpveca(11) = tmpveca(11) + vmr_svaa(i,k,l) + vmrcw_svaa(i,k,l)
            tmpveca(12) = tmpveca(12) + vmr(     i,k,l) + vmrcw(     i,k,l)
         end if
         l = lptr2_soa_a_amode(n,1) - loffset
         if (l > 0) then
            tmpveca(21) = tmpveca(21) + vmr_svaa(i,k,l) + vmrcw_svaa(i,k,l)
            tmpveca(22) = tmpveca(22) + vmr(     i,k,l) + vmrcw(     i,k,l)
         end if
#if ( defined MOSAIC_SPECIES )
         l = lptr_no3_a_amode(n) - loffset
         if (l > 0) then
            tmpveca(31) = tmpveca(31) + vmr_svaa(i,k,l) + vmrcw_svaa(i,k,l)
            tmpveca(32) = tmpveca(32) + vmr(     i,k,l) + vmrcw(     i,k,l)
         end if
         l = lptr_cl_a_amode(n) - loffset
         if (l > 0) then
            tmpveca(41) = tmpveca(41) + vmr_svaa(i,k,l) + vmrcw_svaa(i,k,l)
            tmpveca(42) = tmpveca(42) + vmr(     i,k,l) + vmrcw(     i,k,l)
         end if
#endif
      end do
      tmpveca( 3) = tmpveca( 2) - tmpveca( 1)
      tmpveca(13) = tmpveca(12) - tmpveca(11)
      tmpveca(23) = tmpveca(22) - tmpveca(21)
      tmpveca(33) = tmpveca(32) - tmpveca(31)
      tmpveca(43) = tmpveca(42) - tmpveca(41)
      tmpa = 1.0e9
      write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') 'sox_tot         ', &
         tmpveca(1:3)*tmpa
      write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') 'nhx_tot         ', &
         tmpveca(11:13)*tmpa
      if (maxval( tmpveca(21:23) )*tmpa > 1.0e-10) &
      write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') 'soa1_tot        ', &
         tmpveca(21:23)*tmpa
      if (maxval( tmpveca(31:33) )*tmpa > 1.0e-10) &
      write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') 'no3_tot         ', &
         tmpveca(31:33)*tmpa
      if (maxval( tmpveca(41:43) )*tmpa > 1.0e-10) &
      write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') 'cl_tot          ', &
         tmpveca(41:43)*tmpa

!     l = lmz_h2so4g
!     if (i == 1) then
!     write(81,'(/a,10x,2i5,1p,4e12.4,2x,4e12.4)') &
!        'main - i, k, q0, q1, q2, q3, d01, d23', i, k, &
!        vmr_svaa(i,k,l), vmr_svbb(i,k,l), &
!        vmr_svcc(i,k,l), vmr_svdd(i,k,l), &
!        vmr_svbb(i,k,l)-vmr_svaa(i,k,l), &
!        vmr_svdd(i,k,l)-vmr_svbb(i,k,l)
!     write(81,'(/a,10x,2i5,1p,4e12.4,2x,4e12.4)') &
!        'main - i, k, qavg, uptkrt            ', i, k, &
!        qavg_h2so4_gaex(i,k), uptkrt_h2so4_gaex(i,k)
!     end if

      end do ! k

      end do ! i


!
! switch from vmr & vmrcw to q & qqcw
!
      loffset = imozart - 1
      do l = imozart, pcnst
         l2 = l - loffset
         mmr(  1:ncol,1:pver,l2) = vmr(  1:ncol,1:pver,l2) * adv_mass(l2)/mwdry
         mmrcw(1:ncol,1:pver,l2) = vmrcw(1:ncol,1:pver,l2) * adv_mass(l2)/mwdry
         q(    1:ncol,1:pver,l)  = mmr(  1:ncol,1:pver,l2)
         qqcw( 1:ncol,1:pver,l)  = mmrcw(1:ncol,1:pver,l2)
      end do


! write binary file
      lun = 181
      write(lun) istep, ncol, pver, gas_pcnst, ntot_amode
      do i = 1, ncol
      do k = 1, pver
      write(lun) i, k
      write(lun) t(i,k), pmid(i,k), qv(i,k), relhum(i,k), cld(i,k), pblh(i)
      write(lun) qaerwat(i,k,1:ntot_amode)
      write(lun) dgncur_a(i,k,1:ntot_amode)
      write(lun) dgncur_awet(i,k,1:ntot_amode)
      do l = 1, gas_pcnst
      write(lun) vmr(i,k,l), vmrcw(i,k,l)
      end do ! l
      end do ! k
      end do ! i


      end do main_time_loop


      return
      end subroutine cambox_do_run


!-------------------------------------------------------------------------------
      subroutine load_pbuf( &
         ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens        )

      use shr_kind_mod, only: r8 => shr_kind_r8
      use chem_mods, only: adv_mass, gas_pcnst, imozart
      use physconst, only: mwdry
      use ppgrid, only: pcols, pver

      use modal_aero_data
      use physics_buffer, only: xx2d, xx3d

!     implicit none

      integer,  intent(in   ) :: ncol
      integer,  intent(in   ) :: nstop

      real(r8), intent(in   ) :: deltat
      real(r8), intent(in   ) :: t(pcols,pver)      ! Temperature in Kelvin
      real(r8), intent(in   ) :: pmid(pcols,pver)   ! pressure at model levels (Pa)
      real(r8), intent(in   ) :: pdel(pcols,pver)   ! pressure thickness of levels
      real(r8), intent(in   ) :: zm(pcols,pver)     ! midpoint height above surface (m)
      real(r8), intent(in   ) :: pblh(pcols)        ! pbl height (m)
      real(r8), intent(in   ) :: cld(pcols,pver)    ! stratiform cloud fraction
      real(r8), intent(in   ) :: relhum(pcols,pver) ! layer relative humidity
      real(r8), intent(in   ) :: qv(pcols,pver)     ! layer specific humidity

      real(r8), intent(inout) :: q(pcols,pver,pcnst)     ! Tracer MR array
      real(r8), intent(inout) :: qqcw(pcols,pver,pcnst)  ! Cloudborne aerosol MR array
      real(r8), intent(inout) :: dgncur_a(pcols,pver,ntot_amode)
      real(r8), intent(inout) :: dgncur_awet(pcols,pver,ntot_amode)
      real(r8), intent(inout) :: qaerwat(pcols,pver,ntot_amode)
      real(r8), intent(inout) :: wetdens(pcols,pver,ntot_amode)

      integer :: l


      do l = 1, pcnst
         if (cnst_name_cw(l) /= ' ') xx2d(:,:,l) = qqcw(:,:,l)
      end do
      xx2d(:,:,pcnst+1) = cld(:,:)

      xx3d(:,:,:,1) = dgncur_a(:,:,:)
      xx3d(:,:,:,2) = dgncur_awet(:,:,:)
      xx3d(:,:,:,3) = qaerwat(:,:,:)
      xx3d(:,:,:,4) = wetdens(:,:,:)

      return
      end subroutine load_pbuf


!-------------------------------------------------------------------------------
      subroutine unload_pbuf( &
         ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens        )

      use shr_kind_mod, only: r8 => shr_kind_r8
      use chem_mods, only: adv_mass, gas_pcnst, imozart
      use physconst, only: mwdry
      use ppgrid, only: pcols, pver

      use modal_aero_data
      use physics_buffer, only: xx2d, xx3d

!     implicit none

      integer,  intent(in   ) :: ncol
      integer,  intent(in   ) :: nstop

      real(r8), intent(in   ) :: deltat
      real(r8), intent(in   ) :: t(pcols,pver)      ! Temperature in Kelvin
      real(r8), intent(in   ) :: pmid(pcols,pver)   ! pressure at model levels (Pa)
      real(r8), intent(in   ) :: pdel(pcols,pver)   ! pressure thickness of levels
      real(r8), intent(in   ) :: zm(pcols,pver)     ! midpoint height above surface (m)
      real(r8), intent(in   ) :: pblh(pcols)        ! pbl height (m)
      real(r8), intent(in   ) :: cld(pcols,pver)    ! stratiform cloud fraction
      real(r8), intent(in   ) :: relhum(pcols,pver) ! layer relative humidity
      real(r8), intent(in   ) :: qv(pcols,pver)     ! layer specific humidity

      real(r8), intent(inout) :: q(pcols,pver,pcnst)     ! Tracer MR array
      real(r8), intent(inout) :: qqcw(pcols,pver,pcnst)  ! Cloudborne aerosol MR array
      real(r8), intent(inout) :: dgncur_a(pcols,pver,ntot_amode)
      real(r8), intent(inout) :: dgncur_awet(pcols,pver,ntot_amode)
      real(r8), intent(inout) :: qaerwat(pcols,pver,ntot_amode)
      real(r8), intent(inout) :: wetdens(pcols,pver,ntot_amode)

      integer :: i, k, l
      real(r8) :: tmpa
      real(r8) :: tmp_cld(pcols,pver)    ! stratiform cloud fraction

      do l = 1, pcnst
         if (cnst_name_cw(l) /= ' ') qqcw(:,:,l) = xx2d(:,:,l)
      end do

      tmp_cld(:,:) = xx2d(:,:,pcnst+1)  ! this should not change
      tmpa = 0.0
      do k = 1, pver
      do i = 1, ncol
         tmpa = max( tmpa, abs(tmp_cld(i,k)-cld(i,k)) )
      end do
      end do
      if (tmpa /= 0.0_r8) then
         write(*,*) '*** unload_pbuf cld change error - ', tmpa
         stop
      end if

      dgncur_a(:,:,:)    = xx3d(:,:,:,1)
      dgncur_awet(:,:,:) = xx3d(:,:,:,2)
      qaerwat(:,:,:)     = xx3d(:,:,:,3)
      wetdens(:,:,:)     = xx3d(:,:,:,4)

      return
      end subroutine unload_pbuf


!-------------------------------------------------------------------------------
      subroutine dump4x( txtaa, ncol, nstep, vmraa, vmrcwaa, vmrbb, vmrcwbb )

      use chem_mods, only: gas_pcnst, imozart
      use ppgrid, only: pcols, pver
      use physconst, only: spec_class_aerosol
      use modal_aero_data

      implicit none

      integer,  intent(in   ) :: ncol, nstep
      real(r8), intent(in   ) :: vmraa(ncol,pver,gas_pcnst)    ! gas & aerosol volume mixing ratios
      real(r8), intent(in   ) :: vmrbb(ncol,pver,gas_pcnst)    ! gas & aerosol volume mixing ratios
      real(r8), intent(in   ) :: vmrcwaa(ncol,pver,gas_pcnst)    ! gas & aerosol volume mixing ratios
      real(r8), intent(in   ) :: vmrcwbb(ncol,pver,gas_pcnst)    ! gas & aerosol volume mixing ratios
      character(len=*), intent(in   ) :: txtaa

      integer :: i, k, l, l2, lun
      real(r8) :: tmpa, tmpb, tmpc
      character(len=1) :: tmpch1(pver)

      do i = 1, ncol

      lun = 39 + i
      write(lun,'(/a,2i8)') txtaa, nstep, i

      do l = 1, gas_pcnst
         l2 = l+imozart-1
         tmpch1(:) = ' '
         do k = 1, pver
            tmpa = vmraa(i,k,l) ; tmpb = vmrbb(i,k,l)
            if (abs(tmpa-tmpb)/max(tmpa,tmpb,1.0e-30_r8) > 1.0e-5_r8) tmpch1(k) = '*'
         end do
!        write(lun,'(a,1x,a,1p,10(2x,2e11.3,a))') txtaa(1:4), &
         write(lun,'(a,1p,10(2x,2e11.3,a))') &
            cnst_name(l2)(1:10), &
            (vmraa(i,k,l), vmrbb(i,k,l), tmpch1(k), k=pver,1,-1)
      end do

      if (xopt_cloudf >= 1.0e-6_r8) then
      do l = 1, gas_pcnst
         l2 = l+imozart-1
         if (species_class(l2) /= spec_class_aerosol) cycle
         tmpch1(:) = ' '
         do k = 1, pver
            tmpa = vmrcwaa(i,k,l) ; tmpb = vmrcwbb(i,k,l)
            if (abs(tmpa-tmpb)/max(tmpa,tmpb,1.0e-30_r8) > 1.0e-5_r8) tmpch1(k) = '*'
         end do
!        write(lun,'(a,1x,a,1p,10(2x,2e11.3,a))') txtaa(1:4), &
         write(lun,'(a,1p,10(2x,2e11.3,a))') &
            cnst_name_cw(l2)(1:10), &
            (vmrcwaa(i,k,l), vmrcwbb(i,k,l), tmpch1(k), k=pver,1,-1)
      end do
      end if

      end do ! i

      return
      end subroutine dump4x
         

!-------------------------------------------------------------------------------

      end module driver
