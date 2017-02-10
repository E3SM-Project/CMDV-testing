
module Test_name_list_mod
   use name_list_mod
   use pfunit_mod
   
   implicit none
   public :: Setup
   
!@TestCase
   type, extends(TestCase) :: mySetup
     
     integer :: mymin = 30, mymax = 100 , list_length=3
     character(50) :: myname
     character(len=20) :: name_to_find
     character(len=20) , dimension(5):: list_of_names
     integer :: name_id
   
   contains
      procedure :: setUp     ! overides generic
      procedure :: tearDown  ! overrides generic
   end type mySetup

contains

   ! No need to annotate setUp() when _extending_ TestCase
   subroutine setUp(this)
      class (mySetup), intent(inout) :: this

      this%name_id = 2
      this%list_of_names(1) = "Hans"
      this%list_of_names(2) = "Peter"
      this%list_of_names(3) = "Klaus"

   end subroutine setUp

   ! No need to annotate tearDown() _extending_ TestCase
   subroutine tearDown(this)
      class (mySetup), intent(inout) :: this
     
      print * , "Clean up"
   end subroutine tearDown

!@Test
   subroutine test_search_list_of_names(this)
     ! Testing search_list_of_names
     ! Objective : check if existing name from list is found 
     class (mySetup), intent(inout) :: this
     integer :: name_id  
  
     
     this%name_to_find = "Peter"
     print *, size(this%list_of_names), this%list_length
     
     call search_list_of_names(this%name_to_find, name_id, this%list_of_names, SIZE(this%list_of_names))
#line 55 "Test_name_list.pf"
  call assertGreaterThan(name_id, 0 , message="name_id and should be equal or greater 0.", &
 & location=SourceLocation( &
 & 'Test_name_list.pf', &
 & 55) )
  if (anyExceptions()) return
#line 56 "Test_name_list.pf"
   end subroutine test_search_list_of_names
   
!@Test
    subroutine test_search_list_of_names_fail(this)
      ! Testing search_list_of_names
      ! Objective : check if call returns false for empty name 
      class (mySetup), intent(inout) :: this
      integer :: name_id  
       
      this%name_to_find = "Hui"
      print *, size(this%list_of_names), this%list_length  
   
      call search_list_of_names(this%name_to_find, name_id, this%list_of_names, size(this%list_of_names))
#line 69 "Test_name_list.pf"
  call assertLessThan(name_id, 1 , message="name_id  should be equal or less than 0.", &
 & location=SourceLocation( &
 & 'Test_name_list.pf', &
 & 69) )
  if (anyExceptions()) return
#line 70 "Test_name_list.pf"
    end subroutine test_search_list_of_names_fail




end module Test_name_list_mod




module WrapTest_name_list_mod
   use pFUnit_mod
   use Test_name_list_mod
   implicit none
   private

   public :: WrapUserTestCase
   public :: makeCustomTest
   type, extends(mySetup) :: WrapUserTestCase
      procedure(userTestMethod), nopass, pointer :: testMethodPtr
   contains
      procedure :: runMethod
   end type WrapUserTestCase

   abstract interface
     subroutine userTestMethod(this)
        use Test_name_list_mod
        class (mySetup), intent(inout) :: this
     end subroutine userTestMethod
   end interface

contains

   subroutine runMethod(this)
      class (WrapUserTestCase), intent(inout) :: this

      call this%testMethodPtr(this)
   end subroutine runMethod

   function makeCustomTest(methodName, testMethod) result(aTest)
#ifdef INTEL_13
      use pfunit_mod, only: testCase
#endif
      type (WrapUserTestCase) :: aTest
#ifdef INTEL_13
      target :: aTest
      class (WrapUserTestCase), pointer :: p
#endif
      character(len=*), intent(in) :: methodName
      procedure(userTestMethod) :: testMethod
      aTest%testMethodPtr => testMethod
#ifdef INTEL_13
      p => aTest
      call p%setName(methodName)
#else
      call aTest%setName(methodName)
#endif
   end function makeCustomTest

end module WrapTest_name_list_mod

function Test_name_list_mod_suite() result(suite)
   use pFUnit_mod
   use Test_name_list_mod
   use WrapTest_name_list_mod
   type (TestSuite) :: suite

   suite = newTestSuite('Test_name_list_mod_suite')

   call suite%addTest(makeCustomTest('test_search_list_of_names', test_search_list_of_names))

   call suite%addTest(makeCustomTest('test_search_list_of_names_fail', test_search_list_of_names_fail))


end function Test_name_list_mod_suite

