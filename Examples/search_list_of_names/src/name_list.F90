Module name_list_mod
  implicit none
  
contains
    !==============================================================
     subroutine search_list_of_names(                                &
          name_to_find, name_id, list_of_names, list_length )
       !
       !   searches for a name in a list of names
       !
       !   name_to_find - the name to be found in the list  [input]
       !   name_id - the position of "name_to_find" in the "list_of_names".
       !       If the name is not found in the list, then name_id=0.  [output]
       !   list_of_names - the list of names to be searched  [input]
       !   list_length - the number of names in the list  [input]
       !
       character(len=*), intent(in):: name_to_find, list_of_names(:)
       integer, intent(in) :: list_length
       integer, intent(out) :: name_id
      
       integer :: i
       name_id = -999888777
       if (name_to_find .ne. ' ') then
          do i = 1, list_length
             if (name_to_find .eq. list_of_names(i)) then
                name_id = i
                exit
             end if
          end do
       end if
     end subroutine search_list_of_names
     
   end Module name_list_mod