module driver_init
  
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
  


end module driver_init
