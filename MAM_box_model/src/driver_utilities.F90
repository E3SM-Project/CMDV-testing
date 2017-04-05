module driver_utilities
  
  use shr_kind_mod, only: r8 => shr_kind_r8
  use constituents, only: pcnst, cnst_name, cnst_get_ind
  use modal_aero_data, only: ntot_amode
  
  implicit none
  save
  public
  
  real(r8) :: xopt_cloudf
  
  integer :: species_class(pcnst) = -1
  
contains

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


end module driver_utilities
