! physics_buffer.F90
!    This F90 module file is a special version of the equivalent ACME (and CAM5) module.
!    It provides the functionality needed by the cambox offline code
!    that is used for development and testing of the modal aerosol module (MAM),
!    but (in most cases) not all the functionality of the equivalent ACME module.
!    Also, it may have been taken from a version of CAM5 that was older
!    than ACME-V0 (i.e., pre 2014).

      module physics_buffer

      use shr_kind_mod, only: r8 => shr_kind_r8
      use cam_logfile, only: iulog
      use cam_abortutils, only: endrun
      use constituents, only: pcnst, cnst_name
      use ppgrid, only: pcols, pver

      implicit none

      integer, parameter, public :: dtype_r8 = 2008

#if ( defined MODAL_AERO_4MODE )
      integer, parameter, public :: nmodes = 4
#elif ( defined MODAL_AERO_4MODE_MOM )
      integer, parameter, public :: nmodes = 4
#endif

      integer, parameter :: nxx2d=pcnst+6
      integer, parameter :: nxx3d=5

      type physics_buffer_desc
         integer :: lchnk, ia, ib
      end type physics_buffer_desc

      real(r8), target, dimension(pcols,pver,nxx2d)  :: xx2d
      real(r8), target, dimension(pcols,pver,nmodes,nxx3d) :: xx3d

      interface pbuf_get_field
         module procedure pbuf_get_field_2d
         module procedure pbuf_get_field_2d_sk
         module procedure pbuf_get_field_3d
      end interface

      contains


!----------------------------------------------------------------------
      subroutine pbuf_init( )

      xx2d = 0.0_r8
      xx3d = 0.0_r8

      return
      end subroutine pbuf_init
    

!----------------------------------------------------------------------
      function pbuf_get_chunk( pbuf2d, lchnk )

      type(physics_buffer_desc), pointer :: pbuf2d(:,:)
      integer, intent(in) :: lchnk

      type(physics_buffer_desc), pointer :: pbuf_get_chunk(:)

      pbuf_get_chunk => pbuf2d(:,lchnk)

      return
      end function pbuf_get_chunk
    

!----------------------------------------------------------------------
      subroutine pbuf_add_field( aname, bname, atype, adims, aidx )

      character(len=*), intent(in) :: aname, bname
      integer, intent(in) :: atype
      integer, intent(in) :: adims(:)
      integer, intent(out) :: aidx

      integer :: j, l, n, nadims

      character(len=100) :: msg
      character(len=32)  :: tmpnamecw
      character(len=3)   :: tmpch3

      nadims = size( adims, 1 )
      aidx = -1

      if (nadims == 2) then

         do l = 1, pcnst
            tmpnamecw = cnst_name(l)
            j = len(trim(tmpnamecw))
            do n = 1, nmodes
               if (n < 10) then
                  write(tmpch3,'(a,i1)') '_a', n
                  if (tmpnamecw(j-2:j) == tmpch3) then
                     tmpnamecw(j-1:j-1) = 'c'
                     if (aname == tmpnamecw) then
                        aidx = 2000 + l
                        exit
                     end if
                  end if
               else
                  write(msg,*) 'pbuf_add_field - bad nmodes =', nmodes
                  call endrun( msg )
               end if
            end do ! n
         end do ! l

         if (aidx < 0) then
            if (aname == "CLD") then
               aidx = 2000 + pcnst + 1
            else if (aname == "chla ") then
               aidx = 2000 + pcnst + 2
            else if (aname == "mpoly") then
               aidx = 2000 + pcnst + 3
            else if (aname == "mprot") then
               aidx = 2000 + pcnst + 4
            else if (aname == "mlip") then
               aidx = 2000 + pcnst + 5
            else
               aidx = 2000 + pcnst + 6
            end if
         end if

      else if (nadims == 3) then

         if (aname == "DGNUM") then
            aidx = 3001
         else if (aname == "DGNUMWET") then
            aidx = 3002
         else if (aname == "QAERWAT") then
            aidx = 3003
         else if (aname == "WETDENS_AP") then
            aidx = 3004
         else
            aidx = 3005
         end if

      else
         write(msg,'(a,i8,2x,a)') 'pbuf_add_field error', nadims, trim(aname)
         call endrun( msg )
      end if

      write(*,'(a,i8,2x,a)') 'pbuf_add_field success', nadims, trim(aname)

      return
      end subroutine pbuf_add_field
    

!----------------------------------------------------------------------
      function pbuf_get_index( aname )

      character(len=*), intent(in) :: aname
      integer :: pbuf_get_index

      integer :: aidx
      character(len=100) :: msg

! only need to check for these 2 fields
      if (aname == "CLD") then
         aidx = 2000 + pcnst + 1
      else if (aname == "DGNUM") then
         aidx = 3001
      else
         write(msg,'(a,2x,a)') 'pbuf_get_index error', trim(aname)
         call endrun( msg )
      end if
      pbuf_get_index = aidx

      return
      end function pbuf_get_index
    

!----------------------------------------------------------------------
      subroutine pbuf_get_field_2d( apbuf, aidx, afield )

      type(physics_buffer_desc), pointer :: apbuf(:)
      integer, intent(in)                :: aidx
      real(r8), pointer                  :: afield(:,:)

      integer :: i
      character(len=100) :: msg

      i = aidx-2000
      if (1 <= i .and. i <= nxx2d) then
         afield => xx2d(:,:,i)
      else
         write(msg,*) 'pbuf_get_field_2d - bad aidx =', aidx
         call endrun( msg )
      end if

      return
      end subroutine pbuf_get_field_2d
    

!----------------------------------------------------------------------
      subroutine pbuf_get_field_2d_sk( apbuf, aidx, afield, start, kount )

      type(physics_buffer_desc), pointer :: apbuf(:)
      integer, intent(in)                :: aidx
      real(r8), pointer                  :: afield(:,:)
! start and kount are only used in 1 place by routines that are active in the cambox test driver
! this is for the CLD field, and the start/kount specify the time index because CLD is
!    stored at 2 time levels in CAM
! in the cambox test driver, CLD is only stored at one time level, so start/kount can be ignored
      integer, intent(in)                :: start(:)
      integer, intent(in)                :: kount(:)

      integer :: i
      character(len=100) :: msg

      if (aidx == 2000 + pcnst + 1) then
         i = aidx-2000
         afield => xx2d(:,:,i)
      else
         write(msg,*) 'pbuf_get_field_2d_sk - bad aidx =', aidx
         call endrun( msg )
      end if

      return
      end subroutine pbuf_get_field_2d_sk
    

!----------------------------------------------------------------------
      subroutine pbuf_get_field_3d( apbuf, aidx, afield )

      type(physics_buffer_desc), pointer :: apbuf(:)
      integer, intent(in)                :: aidx
      real(r8), pointer                  :: afield(:,:,:)

      integer :: i
      character(len=100) :: msg

      i = aidx-3000
      if (1 <= i .and. i <= nxx3d) then
         afield => xx3d(:,:,:,i)
      else
         write(msg,*) 'pbuf_get_field_3d - bad aidx =', aidx
         call endrun( msg )
      end if

      return
      end subroutine pbuf_get_field_3d
    

!----------------------------------------------------------------------
      subroutine pbuf_set_field( apbuf2d, aidx, avalue )

      type(physics_buffer_desc), pointer :: apbuf2d(:,:)
      integer, intent(in)                :: aidx
      real(r8), intent(in)               :: avalue

      integer :: i
      character(len=100) :: msg

      i = aidx-2000
      if (1 <= i .and. i <= nxx2d) then
         xx2d(:,:,i) = avalue
         return
      end if

      i = aidx-3000
      if (1 <= i .and. i <= nxx3d) then
         xx3d(:,:,:,i) = avalue
         return
      end if

      write(msg,*) 'pbuf_set_field - bad aidx =', aidx
      call endrun( msg )

      return
      end subroutine pbuf_set_field
    

!----------------------------------------------------------------------
      function pbuf_old_tim_idx( )

      integer :: pbuf_old_tim_idx

      pbuf_old_tim_idx = 1

      return
      end function pbuf_old_tim_idx
    

!----------------------------------------------------------------------
      end module physics_buffer
