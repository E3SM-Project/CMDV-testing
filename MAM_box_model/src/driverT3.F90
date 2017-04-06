module driver
  
  use shr_kind_mod, only: r8 => shr_kind_r8
  use constituents, only: pcnst, cnst_name, cnst_get_ind
  use modal_aero_data, only: ntot_amode
  
  implicit none
  
  public
  
  integer, parameter :: lun_outfld = 90
  
  
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
    use driver_init,             only: cambox_init_basics, cambox_init_run
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
    logical  :: success
    
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
         q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens, success        )
    if(TESTING==1) then
       if(success)print*,'the test passed'
    end if
  end subroutine cambox_main
  
  !-------------------------------------------------------------------------------
  subroutine cambox_do_run( &
       ncol, nstop, deltat, t, pmid, pdel, zm, pblh, cld, relhum, qv, &
       q, qqcw, dgncur_a, dgncur_awet, qaerwat, wetdens, success       )
    
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
    use driver_utilities, only: load_pbuf, unload_pbuf, dump4x
    use driver_init, only: mdo_gaschem, mdo_cloudchem,&
         mdo_gasaerexch, mdo_rename, mdo_newnuc, mdo_coag,&
         mopt_aero_comp, mopt_aero_load, mopt_ait_size,&
         mopt_h2so4_uptake,i_cldy_sameas_clear,&
         iwrite3x_species_flagaa, iwrite3x_units_flagaa, &
         iwrite4x_heading_flagbb,xopt_cloudf
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
    logical, intent(out)    :: success

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
    
    real(r8) :: scr(30),tol
    integer, parameter :: tempunit=29
    logical :: match=.true.
    
    tol=1.0e-10
    lchnk = 1
    success=.true.
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
    
    open(tempunit,file="test3Res")
    
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
             match=.true.
             match = match.and.(abs(vmr_svaa(i,k,lmz_so2g)-scr(1))<tol)
             match = match.and.(abs(vmr(i,k,lmz_so2g)-scr(2))<tol)
             match = match.and.(abs(vmr_svaa(i,k,lmz_h2so4g)-scr(3))<tol)
             match = match.and.(abs(vmr(i,k,lmz_h2so4g)-scr(4))<tol)
             if(.not.match) success=.false.
          end if
       end do
    end do ! i
    
    
    call dump4x( 'gasch', ncol, nstep, vmr_svaa, vmrcw_svaa, vmr, vmrcw )
    
    
!!$    !
!!$    ! cloudchem_simple
!!$    !
!!$    lun = 6
!!$    write(lun,'(/a,i8)') &
!!$         'cambox_do_run doing cloudchem simple, istep=', istep
!!$    vmr_svbb = vmr
!!$    vmrcw_svbb = vmrcw
!!$    
!!$    if (mdo_cloudchem > 0 .and. maxval( cld_ncol(:,:) ) > 1.0e-6_r8) then
!!$       
!!$       call cloudchem_simple_sub(                  &
!!$            lchnk,    ncol,     nstep,               &
!!$            loffset,  deltat,                        &
!!$            vmr,      vmrcw,    cld_ncol             )
!!$       
!!$       do i = 1, ncol
!!$          lun = tempunit + i
!!$          write(lun,'(/a,i8)') &
!!$               'cambox_do_run doing cloudchem simple, istep=', istep
!!$          
!!$          if (iwrite3x_units_flagaa >= 10) then
!!$             tmpch80 = '(nmol/mol)'
!!$          else
!!$             tmpch80 = '(ppbv)'
!!$          end if
!!$          write(lun,'(2a)') &
!!$               'k, old & new so2, ... h2so4, ... so4_c1, ... so4_c2  ', trim(tmpch80)
!!$          do k = 1, pver
!!$             write(lun,'( i4,1p,6(2x,2e12.4))') k, &
!!$                  vmr_svbb(i,k,lmz_so2g)*1.0e9,     vmr(i,k,lmz_so2g)*1.0e9, &
!!$                  vmr_svbb(i,k,lmz_h2so4g)*1.0e9,   vmr(i,k,lmz_h2so4g)*1.0e9, &
!!$                  vmrcw_svbb(i,k,lmz_so4_a1)*1.0e9, vmrcw(i,k,lmz_so4_a1)*1.0e9, &
!!$                  vmrcw_svbb(i,k,lmz_so4_a2)*1.0e9, vmrcw(i,k,lmz_so4_a2)*1.0e9
!!$             if(TESTING==0) then 
!!$                write(tempunit,*)vmr_svbb(i,k,lmz_so2g), vmr(i,k,lmz_so2g), &
!!$                     vmr_svbb(i,k,lmz_h2so4g), vmr(i,k,lmz_h2so4g), &
!!$                     vmrcw_svbb(i,k,lmz_so4_a1),&
!!$                     vmrcw(i,k,lmz_so4_a1), &
!!$                     vmrcw_svbb(i,k,lmz_so4_a2), vmrcw(i,k,lmz_so4_a2)
!!$             else
!!$                read(tempunit,*)scr(1),scr(2),scr(3),scr(4),scr(5),scr(6),scr(7),scr(8)
!!$                match=.true.
!!$                match = match.and.(abs(vmr_svbb(i,k,lmz_so2g)-scr(1))<tol)
!!$                match = match.and.(abs(vmr(i,k,lmz_so2g)-scr(2))<tol)
!!$                match = match.and.(abs(vmr_svbb(i,k,lmz_h2so4g)-scr(3))<tol)
!!$                match = match.and.(abs(vmr(i,k,lmz_h2so4g)-scr(4))<tol)
!!$                match = match.and.(abs(vmrcw_svbb(i,k,lmz_so4_a1)-scr(5))<tol)
!!$                match = match.and.(abs(vmrcw(i,k,lmz_so4_a1)-scr(6))<tol)
!!$                match = match.and.(abs(vmrcw_svbb(i,k,lmz_so4_a2)-scr(7))<tol)
!!$                match = match.and.(abs(vmrcw(i,k,lmz_so4_a2)-scr(8))<tol)
!!$                
!!$                if(.not.match)call endrun("stop at 4a")
!!$             end if
!!$             
!!$          end do
!!$          if (lmz_nh3g > 0) then
!!$             write(lun,'(2a)') &
!!$                  'k, old & new nh3, ... nh4_c1, ... nh4_c2  ', trim(tmpch80)
!!$             do k = 1, pver
!!$                write(lun,'( i4,1p,6(2x,2e12.4))') k, &
!!$                     vmr_svbb(i,k,lmz_nh3g)*1.0e9,     vmr(i,k,lmz_nh3g)*1.0e9, &
!!$                     vmrcw_svbb(i,k,lmz_nh4_a1)*1.0e9, vmrcw(i,k,lmz_nh4_a1)*1.0e9, &
!!$                     vmrcw_svbb(i,k,lmz_nh4_a2)*1.0e9, vmrcw(i,k,lmz_nh4_a2)*1.0e9
!!$                if(TESTING==0)then
!!$                   write(tempunit,*) &
!!$                        vmr_svbb(i,k,lmz_nh3g),     vmr(i,k,lmz_nh3g), &
!!$                        vmrcw_svbb(i,k,lmz_nh4_a1), vmrcw(i,k,lmz_nh4_a1), &
!!$                        vmrcw_svbb(i,k,lmz_nh4_a2), vmrcw(i,k,lmz_nh4_a2)
!!$                else
!!$                   read(tempunit,*)scr(1),scr(2),scr(3),scr(4),scr(5),scr(6)
!!$                   match=.true.
!!$                   match = match.and.(abs(vmr_svbb(i,k,lmz_nh3g)-scr(1))<tol)
!!$                   match = match.and.(abs(vmr(i,k,lmz_nh3g)-scr(2))<tol)
!!$                   match = match.and.(abs(vmrcw_svbb(i,k,lmz_nh4_a1)-scr(3))<tol)
!!$                   match = match.and.(abs(vmrcw(i,k,lmz_nh4_a1)-scr(4))<tol)
!!$                   match = match.and.(abs(vmrcw_svbb(i,k,lmz_nh4_a2)-scr(5))<tol)
!!$                   match = match.and.(abs(vmrcw(i,k,lmz_nh4_a2)-scr(6))<tol)
!!$                   
!!$                   if(.not.match)call endrun("stop at 4b")
!!$                end if
!!$             end do
!!$          end if
!!$          
!!$       end do ! i
!!$       
!!$       call dump4x( 'cldch', ncol, nstep, vmr_svbb, vmrcw_svbb, vmr, vmrcw )
!!$       
!!$    end if ! (mdo_cloudchem > 0 .and. maxval( cld_ncol(:,:) ) > 1.0e-6_r8) then
!!$    
!!$    
!!$    !
!!$    ! gasaerexch
!!$    !
!!$    lun = 6
!!$    write(lun,'(/a,i8)') 'cambox_do_run doing gasaerexch, istep=', istep
!!$    vmr_svcc = vmr
!!$    vmrcw_svcc = vmrcw
!!$    
!!$    dvmrdt_bb = 0.0_r8 ; dvmrcwdt_bb = 0.0_r8
!!$    
!!$    
!!$    !.....tine modal_aero_amicphys_intr(              &
!!$    !        mdo_gasaerexch,     mdo_rename,          &
!!$    !        mdo_newnuc,         mdo_coag,            &
!!$    !        lchnk,    ncol,     nstep,               &
!!$    !        loffset,  deltat,                        &
!!$    !        latndx,   lonndx,                        &
!!$    !        t,        pmid,     pdel,                &
!!$    !        zm,       pblh,                          &
!!$    !        qv,       cld,                           &
!!$    !        q,                  qqcw,                &
!!$    !        q_pregaschem,                            &
!!$    !        q_precldchem,       qqcw_precldchem,     &
!!$    !#if ( defined( CAMBOX_ACTIVATE_THIS ) )
!!$    !        nqtendbb,           nqqcwtendbb,         &
!!$    !        q_tendbb,           qqcw_tendbb,         &
!!$    !#endif
!!$    !        dgncur_a,           dgncur_awet,         &
!!$    !        wetdens,                                 &
!!$    !        qaerwat                                  )
!!$    
!!$    call modal_aero_amicphys_intr(              &
!!$         mdo_gasaerexch,     mdo_rename,          &
!!$         mdo_newnuc,         mdo_coag,            &
!!$         lchnk,    ncol,     nstep,               &
!!$         loffset,  deltat,                        &
!!$         latndx,   lonndx,                        &
!!$         t,        pmid,     pdel,                &
!!$         zm,       pblh,                          &
!!$         qv,       cld_ncol,                      &
!!$         vmr,                vmrcw,               &   ! after  cloud chem
!!$         vmr_svaa,                                &   ! before gas chem
!!$         vmr_svbb,           vmrcw_svbb,          &   ! before cloud chem
!!$         nqtendbb,           nqqcwtendbb,         &
!!$         dvmrdt_bb,          dvmrcwdt_bb,         &
!!$         dgncur_a,           dgncur_awet,         &
!!$         wetdens                                  )
!!$    
!!$    
!!$    
!!$    dvmrdt_cond(  :,:,:) = dvmrdt_bb(  :,:,:,iqtend_cond)
!!$    dvmrdt_rnam(  :,:,:) = dvmrdt_bb(  :,:,:,iqtend_rnam)
!!$    dvmrdt_nnuc(  :,:,:) = dvmrdt_bb(  :,:,:,iqtend_nnuc)
!!$    dvmrdt_coag(  :,:,:) = dvmrdt_bb(  :,:,:,iqtend_coag)
!!$    dvmrcwdt_cond(:,:,:) = 0.0_r8
!!$    dvmrcwdt_rnam(:,:,:) = dvmrcwdt_bb(:,:,:,iqqcwtend_rnam)
!!$    dvmrcwdt_nnuc(:,:,:) = 0.0_r8
!!$    dvmrcwdt_coag(:,:,:) = 0.0_r8
!!$    
!!$    
!!$    lun = 6
!!$    do i = 1, ncol
!!$       lun = tempunit + i
!!$       write(lun,'(/a,i8)') 'cambox_do_run doing gasaerexch, istep=', istep
!!$       if (iwrite3x_units_flagaa >= 10) then
!!$          tmpch80 = '  (nmol/mol)'
!!$       else
!!$          tmpch80 = '  (ppbv)'
!!$       end if
!!$       write(lun,'( 2a)') &
!!$            'k, old & new h2so4, old & new so4_a1, old & new so4_a2', &
!!$            trim(tmpch80)
!!$       do k = 1, pver
!!$          write(lun,'( i4,1p,6(2x,2e12.4))') k, &
!!$               vmr_svcc(i,k,lmz_h2so4g)*1.0e9, vmr(i,k,lmz_h2so4g)*1.0e9, &
!!$               vmr_svcc(i,k,lmz_so4_a1)*1.0e9, vmr(i,k,lmz_so4_a1)*1.0e9, &
!!$               vmr_svcc(i,k,lmz_so4_a2)*1.0e9, vmr(i,k,lmz_so4_a2)*1.0e9
!!$          if(TESTING==0)then
!!$             write(tempunit,*)&
!!$                  vmr_svcc(i,k,lmz_h2so4g), vmr(i,k,lmz_h2so4g), &
!!$                  vmr_svcc(i,k,lmz_so4_a1), vmr(i,k,lmz_so4_a1), &
!!$                  vmr_svcc(i,k,lmz_so4_a2), vmr(i,k,lmz_so4_a2)
!!$          else
!!$             read(tempunit,*)scr(1),scr(2),scr(3),scr(4),scr(5),scr(6)
!!$             if(.not.((vmr_svcc(i,k,lmz_h2so4g)==scr(1)).and.&
!!$                  (vmr(i,k,lmz_h2so4g)==scr(2)).and.&
!!$                  (vmr_svcc(i,k,lmz_so4_a1)==scr(3)).and.&
!!$                  (vmr(i,k,lmz_so4_a1)==scr(4)).and.&
!!$                  (vmr_svcc(i,k,lmz_so4_a2)==scr(5)).and.&
!!$                  (vmr(i,k,lmz_so4_a2)==scr(6))))call endrun("stop at 5")
!!$          end if
!!$       end do
!!$    end do ! i
!!$    
!!$    
!!$    i = 1 ; k = pver ; lun = 82
!!$    tmpveca = 0.0_r8
!!$    tmpveca(101) = vmr_svcc(i,k,lmz_h2so4g)
!!$    tmpveca(201) = vmr(i,k,lmz_h2so4g)
!!$    do n = 1, ntot_amode
!!$       l = lptr_so4_a_amode(n) - loffset
!!$       if (l > 0) tmpveca(110+n) = vmr_svcc(i,k,l)
!!$       if (l > 0) tmpveca(210+n) = vmr(i,k,l)
!!$    end do
!!$    tmpveca(102) = sum( tmpveca(111:118) )
!!$    tmpveca(103) = sum( tmpveca(101:102) )
!!$    tmpveca(202) = sum( tmpveca(211:218) )
!!$    tmpveca(203) = sum( tmpveca(201:202) )
!!$    tmpveca = tmpveca*1.0e9_r8
!!$    write(lun,'(/a,2i5)') 'h2so4g, so4a_tot, sum at i,k =', i, k
!!$    write(lun,'(/a,1p,3e20.10,10e10.2)') 'before gasaerexch', tmpveca(101:103)
!!$    write(lun,'(/a,1p,3e20.10,10e10.2)') 'after  gasaerexch', tmpveca(201:203)
!!$    write(lun,'(/a,2i5)') 'so4a_1-8 at i,k =', i, k
!!$    write(lun,'(/a,1p,3e20.10,10e10.2)') 'before gasaerexch', tmpveca(111:118)
!!$    write(lun,'(/a,1p,3e20.10,10e10.2)') 'after  gasaerexch', tmpveca(211:218)
!!$    
!!$    call dump4x( 'gaex ', ncol, nstep, vmr_svcc, vmrcw_svcc, vmr, vmrcw )
!!$    
!!$    
!!$    !
!!$    ! newnuc
!!$    !
!!$    if ( 1 == 0 ) then
!!$       !     deleted all of this
!!$    end if ! ( 1 == 0 )
!!$    
!!$    
!!$    !
!!$    ! coag
!!$    !
!!$    if ( 1 == 0 ) then
!!$       !     deleted all of this
!!$    end if ! ( 1 == 0 )
!!$    
!!$    
!!$    !
!!$    ! done
!!$    !
!!$    lun = 6
!!$    write(lun,'(/a,i8)') 'cambox_do_run step done, istep=', istep
!!$    
!!$    do i = 1, ncol
!!$       lun = tempunit + i
!!$       write(lun,'(/a,i8)') 'cambox_do_run step done, istep=', istep
!!$       
!!$       do k = 1, pver
!!$          
!!$          if (iwrite3x_units_flagaa >= 10) then
!!$             tmpch80 = '   --   units = nmol/mol & #/mg'
!!$          else
!!$             tmpch80 = ' '
!!$          end if
!!$          write(lun,'(/a,2i5,2f10.3,a)') 'i, k, told, tnew (h)', i, k, &
!!$               told/3600.0_r8, tnew/3600.0_r8, trim(tmpch80)
!!$          write(lun,'(2a)') &
!!$               'spec              qold       qnew         del-gas', &
!!$               '   del-cloud del-rena    del-cond  del-nuc   del-coag'
!!$          do l = 1, gas_pcnst
!!$             if (iwrite3x_species_flagaa < 10) then
!!$                !           if (max( vmr_svaa(i,k,l), vmr(i,k,l) ) < 1.0e-35) cycle
!!$                if (max( vmr_svaa(i,k,l), vmr_svbb(i,k,l), &
!!$                     vmr_svcc(i,k,l), vmr(i,k,l) ) < 1.0e-35) cycle
!!$             end if
!!$             tmpb = adv_mass(l)
!!$             if (abs(tmpb-1.0_r8) <= 0.1_r8) then
!!$                tmpa = 1.0e-6 * tmpb/mwdry
!!$             else
!!$                tmpa = 1.0e9
!!$             end if
!!$             tmpveca(:) = 0.0
!!$             tmpveca(1) = vmr_svaa(i,k,l)
!!$             tmpveca(2) = vmr(     i,k,l)
!!$             tmpveca(3) = vmr_svbb(i,k,l) - vmr_svaa(i,k,l)  ! gaschem
!!$             tmpveca(4) = vmr_svcc(i,k,l) - vmr_svbb(i,k,l)  ! cloudchem
!!$             
!!$             !        tmpveca(5) = dvmrdt_rename(i,k,l)*deltat        ! gasaerexch rename
!!$             !        tmpveca(6) = vmr_svdd(i,k,l) - vmr_svcc(i,k,l)  ! gasaerexch conden+rename
!!$             tmpveca(5) = dvmrdt_rnam(i,k,l)*deltat          ! gasaerexch rename
!!$             tmpveca(6) = dvmrdt_cond(i,k,l)*deltat          ! gasaerexch conden
!!$             tmpveca(7) = dvmrdt_nnuc(i,k,l)*deltat          ! gasaerexch newnuc
!!$             tmpveca(8) = dvmrdt_coag(i,k,l)*deltat          ! gasaerexch coagul
!!$             ! following commented out lines were for old gasaerexch, where you started with 
!!$             ! tmpveca(6) = vmr_svdd(i,k,l) - vmr_svcc(i,k,l)  ! gasaerexch conden+rename
!!$             !        tmpb = tmpveca(6)
!!$             !        tmpveca(6) = tmpveca(6) - tmpveca(5)
!!$             !        tmpc = max( abs(tmpveca(5)), abs(tmpb),1.0e-20_r8 )
!!$             !        if (abs(tmpveca(6)) < 1.0e-10*tmpc) tmpveca(6) = 0.0_r8
!!$             
!!$             !        tmpveca(7) = vmr_svee(i,k,l) - vmr_svdd(i,k,l)  ! newnuc
!!$             !        tmpveca(8) = vmr(     i,k,l) - vmr_svee(i,k,l)  ! coag
!!$             write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') &
!!$                  cnst_name(l+loffset), tmpveca(1:8)*tmpa
!!$          end do ! l
!!$          
!!$          do l = 1, gas_pcnst
!!$             if (max( vmrcw_svaa(i,k,l), vmrcw(i,k,l) ) < 1.0e-35) cycle
!!$             tmpb = adv_mass(l)
!!$             if (abs(tmpb-1.0_r8) <= 0.1_r8) then
!!$                tmpa = 1.0e-6 * tmpb/mwdry
!!$             else
!!$                tmpa = 1.0e9
!!$             end if
!!$             tmpveca(:) = 0.0
!!$             tmpveca(1) = vmrcw_svaa(i,k,l)
!!$             tmpveca(2) = vmrcw(     i,k,l)
!!$             tmpveca(3) = vmrcw_svbb(i,k,l) - vmrcw_svaa(i,k,l)  ! gaschem
!!$             tmpveca(4) = vmrcw_svcc(i,k,l) - vmrcw_svbb(i,k,l)  ! cloudchem
!!$             
!!$             !        tmpveca(5) = dvmrcwdt_rename(i,k,l)*deltat        ! gasaerexch rename
!!$             !        tmpveca(6) = vmrcw_svdd(i,k,l) - vmrcw_svcc(i,k,l)  ! gasaerexch conden+rename
!!$             tmpveca(5) = dvmrcwdt_rnam(i,k,l)*deltat          ! gasaerexch rename
!!$             tmpveca(6) = dvmrcwdt_cond(i,k,l)*deltat          ! gasaerexch conden
!!$             tmpveca(7) = dvmrcwdt_nnuc(i,k,l)*deltat          ! gasaerexch newnuc
!!$             tmpveca(8) = dvmrcwdt_coag(i,k,l)*deltat          ! gasaerexch coagul
!!$             ! following commented out lines were for old gasaerexch, where you started with 
!!$             ! tmpveca(6) = vmrcw_svdd(i,k,l) - vmrcw_svcc(i,k,l)  ! gasaerexch conden+rename
!!$             !        tmpb = tmpveca(6)
!!$             !        tmpveca(6) = tmpveca(6) - tmpveca(5)
!!$             !        tmpc = max( abs(tmpveca(5)), abs(tmpb),1.0e-20_r8 )
!!$             !        if (abs(tmpveca(6)) < 1.0e-10*tmpc) tmpveca(6) = 0.0_r8
!!$             
!!$             !        tmpveca(7) = vmrcw_svee(i,k,l) - vmrcw_svdd(i,k,l)  ! newnuc
!!$             !        tmpveca(8) = vmrcw(     i,k,l) - vmrcw_svee(i,k,l)  ! coag
!!$             tmpveca(9) = tmpveca(2) - tmpveca(1)
!!$             write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,5e10.2)') &
!!$                  cnst_name_cw(l+loffset)(1:16), tmpveca(1:8)*tmpa
!!$          end do ! l
!!$          
!!$          tmpveca(:) = 0.0
!!$          tmpveca( 1) = vmr_svaa(i,k,lmz_so2g) + vmr_svaa(i,k,lmz_h2so4g)
!!$          tmpveca( 2) = vmr(     i,k,lmz_so2g) + vmr(     i,k,lmz_h2so4g)
!!$          if (lmz_nh3g > 0) then
!!$             tmpveca(11) = vmr_svaa(i,k,lmz_nh3g)
!!$             tmpveca(12) = vmr(     i,k,lmz_nh3g)
!!$          end if
!!$          l = lptr2_soa_g_amode(1) - loffset
!!$          tmpveca(21) = vmr_svaa(i,k,l)
!!$          tmpveca(22) = vmr(     i,k,l)
!!$          if (lmz_hno3g > 0) then
!!$             tmpveca(31) = vmr_svaa(i,k,lmz_hno3g)
!!$             tmpveca(32) = vmr(     i,k,lmz_hno3g)
!!$          end if
!!$          if (lmz_hclg > 0) then
!!$             tmpveca(41) = vmr_svaa(i,k,lmz_hclg)
!!$             tmpveca(42) = vmr(     i,k,lmz_hclg)
!!$          end if
!!$          do n = 1, ntot_amode
!!$             l = lptr_so4_a_amode(n) - loffset
!!$             if (l > 0) then
!!$                tmpveca( 1) = tmpveca( 1) + vmr_svaa(i,k,l) + vmrcw_svaa(i,k,l)
!!$                tmpveca( 2) = tmpveca( 2) + vmr(     i,k,l) + vmrcw(     i,k,l)
!!$             end if
!!$             l = lptr_nh4_a_amode(n) - loffset
!!$             if (l > 0) then
!!$                tmpveca(11) = tmpveca(11) + vmr_svaa(i,k,l) + vmrcw_svaa(i,k,l)
!!$                tmpveca(12) = tmpveca(12) + vmr(     i,k,l) + vmrcw(     i,k,l)
!!$             end if
!!$             l = lptr2_soa_a_amode(n,1) - loffset
!!$             if (l > 0) then
!!$                tmpveca(21) = tmpveca(21) + vmr_svaa(i,k,l) + vmrcw_svaa(i,k,l)
!!$                tmpveca(22) = tmpveca(22) + vmr(     i,k,l) + vmrcw(     i,k,l)
!!$             end if
!!$#if ( defined MOSAIC_SPECIES )
!!$             l = lptr_no3_a_amode(n) - loffset
!!$             if (l > 0) then
!!$                tmpveca(31) = tmpveca(31) + vmr_svaa(i,k,l) + vmrcw_svaa(i,k,l)
!!$                tmpveca(32) = tmpveca(32) + vmr(     i,k,l) + vmrcw(     i,k,l)
!!$             end if
!!$             l = lptr_cl_a_amode(n) - loffset
!!$             if (l > 0) then
!!$                tmpveca(41) = tmpveca(41) + vmr_svaa(i,k,l) + vmrcw_svaa(i,k,l)
!!$                tmpveca(42) = tmpveca(42) + vmr(     i,k,l) + vmrcw(     i,k,l)
!!$             end if
!!$#endif
!!$          end do
!!$          tmpveca( 3) = tmpveca( 2) - tmpveca( 1)
!!$          tmpveca(13) = tmpveca(12) - tmpveca(11)
!!$          tmpveca(23) = tmpveca(22) - tmpveca(21)
!!$          tmpveca(33) = tmpveca(32) - tmpveca(31)
!!$          tmpveca(43) = tmpveca(42) - tmpveca(41)
!!$          tmpa = 1.0e9
!!$          write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') 'sox_tot         ', &
!!$               tmpveca(1:3)*tmpa
!!$          write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') 'nhx_tot         ', &
!!$               tmpveca(11:13)*tmpa
!!$          if (maxval( tmpveca(21:23) )*tmpa > 1.0e-10) &
!!$               write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') 'soa1_tot        ', &
!!$               tmpveca(21:23)*tmpa
!!$          if (maxval( tmpveca(31:33) )*tmpa > 1.0e-10) &
!!$               write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') 'no3_tot         ', &
!!$               tmpveca(31:33)*tmpa
!!$          if (maxval( tmpveca(41:43) )*tmpa > 1.0e-10) &
!!$               write(lun,'(a,1p,2e11.3,2x,3e10.2,2x,3e10.2)') 'cl_tot          ', &
!!$               tmpveca(41:43)*tmpa
!!$          
!!$          !     l = lmz_h2so4g
!!$          !     if (i == 1) then
!!$          !     write(81,'(/a,10x,2i5,1p,4e12.4,2x,4e12.4)') &
!!$          !        'main - i, k, q0, q1, q2, q3, d01, d23', i, k, &
!!$          !        vmr_svaa(i,k,l), vmr_svbb(i,k,l), &
!!$          !        vmr_svcc(i,k,l), vmr_svdd(i,k,l), &
!!$          !        vmr_svbb(i,k,l)-vmr_svaa(i,k,l), &
!!$          !        vmr_svdd(i,k,l)-vmr_svbb(i,k,l)
!!$          !     write(81,'(/a,10x,2i5,1p,4e12.4,2x,4e12.4)') &
!!$          !        'main - i, k, qavg, uptkrt            ', i, k, &
!!$          !        qavg_h2so4_gaex(i,k), uptkrt_h2so4_gaex(i,k)
!!$          !     end if
!!$          
!!$       end do ! k
!!$       
!!$    end do ! i
!!$    
!!$    
!!$    !
!!$    ! switch from vmr & vmrcw to q & qqcw
!!$    !
!!$    loffset = imozart - 1
!!$    do l = imozart, pcnst
!!$       l2 = l - loffset
!!$       mmr(  1:ncol,1:pver,l2) = vmr(  1:ncol,1:pver,l2) * adv_mass(l2)/mwdry
!!$       mmrcw(1:ncol,1:pver,l2) = vmrcw(1:ncol,1:pver,l2) * adv_mass(l2)/mwdry
!!$       q(    1:ncol,1:pver,l)  = mmr(  1:ncol,1:pver,l2)
!!$       qqcw( 1:ncol,1:pver,l)  = mmrcw(1:ncol,1:pver,l2)
!!$    end do
!!$    
!!$    
!!$    ! write binary file
!!$    lun = 181
!!$    write(lun) istep, ncol, pver, gas_pcnst, ntot_amode
!!$    do i = 1, ncol
!!$       do k = 1, pver
!!$          write(lun) i, k
!!$          write(lun) t(i,k), pmid(i,k), qv(i,k), relhum(i,k), cld(i,k), pblh(i)
!!$          write(lun) qaerwat(i,k,1:ntot_amode)
!!$          write(lun) dgncur_a(i,k,1:ntot_amode)
!!$          write(lun) dgncur_awet(i,k,1:ntot_amode)
!!$          do l = 1, gas_pcnst
!!$             write(lun) vmr(i,k,l), vmrcw(i,k,l)
!!$          end do ! l
!!$       end do ! k
!!$    end do ! i
    
 end do main_time_loop
 
 
 return
end subroutine cambox_do_run


end module driver
