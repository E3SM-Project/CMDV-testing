! Comment - call name list

program check_name
  !implicit none
  use name_list_mod
 
  INTEGER, PARAMETER :: mymin = 30, mymax = 100 , list_length=3
  character(50) :: name
 
   character(len=20) :: name_to_find
   character(len=20) , dimension(list_length):: list_of_names
   integer :: name_id
 
   name_id      = 0
   name_to_find = "Peter"
   list_of_names(1) = "Hans"
   list_of_names(2) = "Peter"
   list_of_names(3) = "Klaus"
    
  read(*,*) name_to_find  
  print *, "Searching for  ", name_to_find
 
  call search_list_of_names(name_to_find, name_id, list_of_names, list_length)
  print *, "Found: ", name_id
  

end program check_name