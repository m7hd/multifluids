!    Copyright (C) 2006 Imperial College London and others.
!    
!    Please see the AUTHORS file in the main source directory for a full list
!    of copyright holders.
!
!    Prof. C Pain
!    Applied Modelling and Computation Group
!    Department of Earth Science and Engineering
!    Imperial College London
!
!    amcgsoftware@imperial.ac.uk
!    
!    This library is free software; you can redistribute it and/or
!    modify it under the terms of the GNU Lesser General Public
!    License as published by the Free Software Foundation,
!    version 2.1 of the License.
!
!    This library is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied arranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
!    Lesser General Public License for more details.
!
!    You should have received a copy of the GNU Lesser General Public
!    License along with this library; if not, write to the Free Software
!    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
!    USA

#include "fdebug.h"

module radiation_particle_data_type
   
   !!< Radiation particle data type module

   use global_parameters, only : OPTION_PATH_LEN
   use state_module
   
   use radiation_materials_data_types
   use radiation_materials_interpolation_data_types
      
   implicit none
   
   private 

   public :: particle_type, &
             keff_type
         

   ! the keff (eigenvalue) type
   type keff_type
      ! the latest keff
      real :: keff_new
      ! the previous keff
      real :: keff_iter
      ! the previous coupled keff
      real :: keff_iter_coupled
      ! the previous control iteration keff
      real :: keff_iter_control
   end type keff_type

   
   ! the particle data type
   type particle_type    
      !! the particle_type name
      character(len=OPTION_PATH_LEN) :: name='/uninitialised_name/'
      !! path to options in the options tree
      character(len=OPTION_PATH_LEN) :: option_path='/uninitialised_path/'
      !! the collection of radiation data sets associated with the particle type
      type(particle_radmat_type) :: particle_radmat
      !! the data sets interpolation instructions (ii) associated with the particle type
      type(particle_radmat_ii_type) :: particle_radmat_ii
      !! the data associated with the particle keff (eigenvalue)
      type(keff_type) :: keff
      !! a pointer to a state type that contains the necessary fields associated with this particle
      type(state_type), pointer :: state
      !! a flag to say that this type has been created
      logical :: created = .false.   
   end type particle_type      

end module radiation_particle_data_type
