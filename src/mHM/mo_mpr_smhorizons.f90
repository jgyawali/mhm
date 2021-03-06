!> \file mo_mpr_smhorizons.f90

!> \brief setting up the soil moisture horizons

!> \details This module sets up the soil moisture horizons

!> \author Stephan Thober, Rohini Kumar
!> \date Dec 2012

module mo_mpr_SMhorizons

  use mo_kind, only: i4, dp

  implicit none

  public :: mpr_SMhorizons

  private

contains

  ! ----------------------------------------------------------------------------

  !      NAME
  !         mpr_SMhorizons

  !>        \brief upscale soil moisture horizons

  !>        \details calculate soil properties at the level 1.\n
  !>        Global parameters needed (see mhm_parameter.nml):\n
  !>           - param(1) = rootFractionCoefficient_forest     \n
  !>           - param(2) = rootFractionCoefficient_impervious \n
  !>           - param(3) = rootFractionCoefficient_pervious   \n
  !>           - param(4) = infiltrationShapeFactor            \n


  !      INTENT(IN)
  !>        \param[in] "real(dp)    :: param(:)"         - four or six global parameters depending on SM process
  !>        \param[in] "integer(i4) :: processMatrix"    - matrix specifying user defined processes

  !>        \param[in] "real(dp)    :: nodata"           - no data value
  !>        \param[in] "integer(i4) :: iFlag_soil"       - flags for handling multiple soil databases
  !>        \param[in] "integer(i4) :: nHorizons_mHM"    - number of horizons to model
  !>        \param[in] "integer(i4) :: HorizonDepth(:)"  - [mm] horizon depth from surface,
  !>                                                            postive downwards
  !>        \param[in] "integer(i4) :: L0_LUC(:,:)"      - land use cover at level 0
  !>        \param[in] "integer(i4) :: L0_soilID(:,:)"   - soil IDs at level 0
  !>        \param[in] "integer(i4) :: nHorizons(:)"     - horizons per soil type
  !>        \param[in] "integer(i4) :: nTillHorizons(:)" - Number of Tillage horizons
  !>        \param[in] "real(dp)    :: thetaS_till(:,:,:)"  - saturated water content of soil
  !>                                                          horizons upto tillage depth,
  !>                                                          f(OM, management)
  !>        \param[in] "real(dp)    :: thetaFC_till(:,:,:)" - Field capacity of tillage 
  !>                                                          layers; LUC dependent, f(OM, management)
  !>        \param[in] "real(dp)    :: thetaPW_till(:,:,:)" - Permament wilting point of
  !>                                                          tillage layers; LUC dependent, f(OM, management)
  !>        \param[in] "real(dp)    :: thetaS(:,:)"         - saturated water content of soil
  !>                                                           horizons after tillage depth
  !>        \param[in] "real(dp)    :: thetaFC(:,:)"     - Field capacity of deeper layers
  !>        \param[in] "real(dp)    :: thetaPW(:,:)"     - Permanent wilting point of deeper layers
  !>        \param[in] "real(dp)    :: Wd(:,:,:)"        - weights of mHM Horizons according to horizons provided
  !>                                                     in soil database
  !>        \param[in] "real(dp)    :: Db(:,:,:)"        - Bulk density
  !>        \param[in] "real(dp)    :: DbM(:,:)"         - mineral Bulk density
  !>        \param[in] "real(dp)    :: RZdepth(:)"       - [mm] Total soil depth
  !>        \param[in] "integer(i4) :: L0_cellCoor(:,:)" - cell coordinates at level 0
  !>        \param[in] "integer(i4) :: L0_cell_id(:,:)"  - cell ids of high resolution field, 
  !>                                                     Number of rows times Number of columns
  !>                                                     of high resolution field
  !>        \param[in] "integer(i4) :: upp_row_L1(:)"    - Upper row id in high resolution field
  !>                                                     (L0) of low resolution cell (L1 cell)
  !>        \param[in] "integer(i4) :: low_row_L1(:)"    - Lower row id in high resolution field
  !>                                                     (L0) of low resolution cell (L1 cell)
  !>        \param[in] "integer(i4) :: lef_col_L1(:)"    - Left column id in high resolution 
  !>                                                     field (L0) of low resolution cell
  !>        \param[in] "integer(i4) :: rig_col_L1(:)"    - Right column id in high resolution
  !>                                                     field (L0) of low resolution cell
  !>        \param[in] "integer(i4) :: nL0_in_L1(:)"     - Number of high resolution cells (L0)
  !>                                                     in low resolution cell (L1 cell)

  !      INTENT(OUT)
  !>       \param[in,out] "real(dp) :: L1_beta(:,:)"     - Parameter that determines the
  !>                                                     relative contribution to SM, upscaled
  !>                                                     Bulk density. Number of cells at L1
  !>                                                     times number of horizons in mHM
  !>       \param[in,out] "real(dp) :: L1_SMs(:,:)"      - [10^-3 m] depth of saturated SM cont
  !>                                                     Number of cells at L1 times number
  !>                                                     of horizons in mHM
  !>       \param[in,out] "real(dp) :: L1_FC(:,:)"       - [10^-3 m] field capacity. Number
  !>                                                     of cells at L1 times number of horizons
  !>                                                     in mHM
  !>       \param[in,out] "real(dp) :: L1_PW(:,:)"       - [10^-3 m] permanent wilting point.
  !>                                                     Number of cells at L1 times number 
  !>                                                     of horizons in mHM
  !>       \param[in,out] "real(dp) :: L1_fRoots(:,:)"   - fraction of roots in soil horizons.
  !>                                                     Number of cells at L1 times number
  !>                                                     of horizons in mHM

  !      HISTORY
  !>       \author Luis Samaniego, Rohini Kumar, Stephan Thober
  !>       \date Dec 2012
  !        Written Stephan Thober, Dec 2012
  !        Modified, Stephan Thober, Jan 2013 - updated calling sequence for upscaling operators
  !                  Juliane Mai,    Oct 2013 - OLD parametrization
  !                                                --> param(1) = rootFractionCoefficient_forest
  !                                                --> param(2) = rootFractionCoefficient_impervious 
  !                                                --> param(3) = rootFractionCoefficient_pervious
  !                                                --> param(4) = infiltrationShapeFactor
  !                                             -------------------------------
  !                                             rootFractionCoeff_perv   = rootFractionCoeff_forest - delta_1
  !                                             -------------------------------
  !                                             NEW parametrization
  !                                                --> param(1) = rootFractionCoefficient_forest
  !                                                --> param(2) = rootFractionCoefficient_impervious 
  !                                                --> param(3) = delta_1 
  !                                                --> param(4) = infiltrationShapeFactor
  !                                                ! if processMatrix(3,1) = 3 additionally
  !                                                --> param(5) = rootFractionCoefficient_sand
  !                                                --> param(6) = rootFractionCoefficient_clay
  !                  Stephan Thober, Mar 2014 - added omp parallelization
  !                  Rohini Kumar,   Mar 2016 - changes for handling multiple soil database options
  ! M. Cuneyd Demirel, Simon Stisen, Apr 2017 - added FC dependency on root fraction coefficient


  subroutine mpr_SMhorizons( &
                                ! Input -----------------------------------------------------------------
       param         , & ! global parameters, three are required
       processMatrix , & ! matrix specifying user defined processes
       nodata        , & ! no data value
       iFlag_soil    , & ! flag to handle different soil database
       nHorizons_mHM , & ! number of horizons to model
       HorizonDepth  , & ! depth of the different horizons
       LCOVER0       , & ! land use cover at L0
       soilID0       , & ! soil Ids at L0
       nHorizons     , & ! Number of horizons per soilType
       nTillHorizons , & ! Number of Tillage horizons
       thetaS_till   , & ! saturated water content of soil horizons upto tillage depth
       thetaFC_till  , & ! Field capacity of tillage layer 
       thetaPW_till  , & ! Permament wilting point of tillage layer 
       thetaS        , & ! saturated water content
       thetaFC       , & ! Field capacity of deeper layers
       thetaPW       , & ! Permanent wilting point
       Wd            , & ! weights of mHM Horizons according to horizons provided in soil database
       Db            , & ! Bulk density
       DbM           , & ! mineral Bulk density
       RZdepth       , & ! [mm] Total soil depth
       mask0         , & ! mask at L0
       cell_id0      , & ! cell ids at L0
       upp_row_L1    , & ! upper row of L0 block within L1 cell
       low_row_L1    , & ! lower row of L0 block within L1 cell
       lef_col_L1    , & ! left column of L0 block within L1 cell
       rig_col_L1    , & ! right column of L0 block within L1 cell
       nL0_in_L1     , & ! Number of L0 cells in L0 block within L1 cell
                                ! Output ----------------------------------------------------------------
       L1_beta       , & ! Parameter that determines the relative contribution to SM
       L1_SMs        , & ! [10^-3 m] depth of saturated SM cont
       L1_FC         , & ! [10^-3 m] field capacity
       L1_PW         , & ! [10^-3 m] permanent wilting point
       L1_fRoots )       ! fraction of roots in soil horizons

    use mo_upscaling_operators, only: upscale_harmonic_mean
    use mo_message,             only: message
    use mo_string_utils,        only: num2str

    !$  use omp_lib

    implicit none

    ! Input
    real(dp),    dimension(:),     intent(in) :: param         ! parameters
    integer(i4), dimension(:,:),   intent(in) :: processMatrix ! matrix specifying user defined processes
    real(dp),                      intent(in) :: nodata        ! no data value
    integer(i4),                   intent(in) :: iFlag_soil    ! flag to handle different soil database
    integer(i4),                   intent(in) :: nHorizons_mHM ! Number of Horizons in mHM
    real(dp),    dimension(:),     intent(in) :: HorizonDepth  ! [10^-3 m] horizon depth from
    !                                                          ! surface, postive downwards
    integer(i4), dimension(:),     intent(in) :: LCOVER0       ! Land cover at level 0
    integer(i4), dimension(:,:),   intent(in) :: soilID0       ! soil ID at level 0
    integer(i4), dimension(:),     intent(in) :: nHorizons     ! horizons per soil type
    integer(i4), dimension(:),     intent(in) :: nTillHorizons ! Number of Tillage horizons
    real(dp),    dimension(:,:,:), intent(in) :: thetaS_till   ! saturated water content of soil
    !                                                          ! horizons upto tillage depth,
    !                                                          !f(OM, management)
    real(dp),    dimension(:,:,:), intent(in) :: thetaFC_till  ! Field capacity of tillage 
    !                                                          ! layers; LUC dependent,
    !                                                          !f(OM, management)
    real(dp),    dimension(:,:,:), intent(in) :: thetaPW_till  ! Permament wilting point of
    !                                                          ! tillage layers; LUC dependent,
    !                                                          ! f(OM, management)
    real(dp),    dimension(:,:),   intent(in) :: thetaS       ! saturated water content of soil
    !                                                         ! horizons after tillage depth
    real(dp),    dimension(:,:),   intent(in) :: thetaFC      ! Field capacity of deeper layers
    real(dp),    dimension(:,:),   intent(in) :: thetaPW      ! Permanent wilting point of
    !                                                         ! deeper layers
    real(dp),    dimension(:,:,:), intent(in) :: Wd           ! weights of mHM Horizons
    !                                                         ! according to horizons provided
    !                                                         ! in soil database
    real(dp),    dimension(:,:,:), intent(in) :: Db           ! Bulk density
    real(dp),    dimension(:,:),   intent(in) :: DbM          ! mineral Bulk density
    real(dp),    dimension(:),     intent(in) :: RZdepth      ! [mm]       Total soil depth

    ! Ids of L0 cells beneath L1 cell
    logical,     dimension(:,:), intent(in)   :: mask0
    integer(i4), dimension(:),   intent(in)   :: cell_id0 ! Cell ids of hi res field
    integer(i4), dimension(:),   intent(in)   :: upp_row_L1 ! Upper row of hi res block
    integer(i4), dimension(:),   intent(in)   :: low_row_L1 ! Lower row of hi res block
    integer(i4), dimension(:),   intent(in)   :: lef_col_L1 ! Left column of hi res block
    integer(i4), dimension(:),   intent(in)   :: rig_col_L1 ! Right column of hi res block
    integer(i4), dimension(:),   intent(in)   :: nL0_in_L1  ! Number of L0 cells within a L1 cel

    ! Output
    ! The following five variables have the dimension: Number of cells at L1 times nHorizons_mHM
    real(dp),   dimension(:,:), intent(inout) :: L1_beta   ! Parameter that determines the
    !                                                      ! relative contribution to SM, upscaled
    !                                                      ! Bulk density
    real(dp),   dimension(:,:), intent(inout) :: L1_SMs    ! [10^-3 m] depth of saturated SM cont
    real(dp),   dimension(:,:), intent(inout) :: L1_FC     ! [10^-3 m] field capacity
    real(dp),   dimension(:,:), intent(inout) :: L1_PW     ! [10^-3 m] permanent wilting point
    real(dp),   dimension(:,:), intent(inout) :: L1_fRoots ! fraction of roots in soil horizons

    ! Local Variables
    integer(i4)                             :: h         ! loop index
    integer(i4)                             :: k         ! loop index
    integer(i4)                             :: l         ! loop index
    integer(i4)                             :: s         ! loop index
    real(dp)                                :: dpth_f
    real(dp)                                :: dpth_t
    real(dp)                                :: fTotRoots
    real(dp), dimension(size(LCOVER0,1))    :: beta0   ! beta 0
    real(dp), dimension(size(LCOVER0,1))    :: Bd0     ! [10^3 kg/m3] Bulk density
    real(dp), dimension(size(LCOVER0,1))    :: SMs0    ! [10^-3 m] depth of saturated SM cont
    real(dp), dimension(size(LCOVER0,1))    :: FC0     ! [10^-3 m] field capacity
    real(dp), dimension(size(LCOVER0,1))    :: PW0     ! [10^-3 m] permanent wilting point
    real(dp), dimension(size(LCOVER0,1))    :: fRoots0 ! fraction of roots in soil horizons

    real(dp)                                :: tmp_rootFractionCoefficient_forest
    real(dp)                                :: tmp_rootFractionCoefficient_impervious
    real(dp)                                :: tmp_rootFractionCoefficient_pervious
    real(dp)                                :: tmp_rootFractionCoefficient_perviousFC ! Field capacity dependent
    !                                                                                 ! root frac coeffiecient

    real(dp)                  :: tmp_rootFractionCoefficient_sand ! Model parameter describing the threshold for
    !                                                             ! actual ET reduction for sand  
    real(dp)                  :: tmp_rootFractionCoefficient_clay ! Model parameter describing the threshold for actual
    !                                                             ! ET reduction for clay 

    real(dp)                  :: tmp_FC0min                       ! Calculate FCmin at level 0 once to speed up the code
    real(dp)                  :: tmp_FC0max                       ! Calculate FCmax at level 0 once to speed up the code


    ! decide which parameterization should be used for route fraction:
    ! 1:2 - dependent on land cover 
    tmp_rootFractionCoefficient_forest     = param(1)            ! min(1.0_dp, param(2) + param(3) + param(1))
    tmp_rootFractionCoefficient_impervious = param(2)
    tmp_rootFractionCoefficient_pervious   = param(1) - param(3) ! min(1.0_dp, param(2) + param(3))
                              
    !   3 - dependent on land cover and additionally soil texture
    select case (processMatrix(3,1))    
    case(3)
       !delta approach is used as in tmp_rootFractionCoefficient_pervious
       tmp_rootFractionCoefficient_sand       = param(6) - param(5)
       !the value in parameter namelist is before substraction i.e. param(5)
       tmp_rootFractionCoefficient_clay       = param(6)
    end select

    ! select case according to a given soil database flag
    SELECT CASE(iFlag_soil)
       ! classical mHM soil database format
    CASE(0)
       do h = 1, nHorizons_mHM
          Bd0     = nodata
          SMs0    = nodata
          FC0     = nodata
          PW0     = nodata
          fRoots0 = nodata
          tmp_rootFractionCoefficient_perviousFC = nodata
          ! Initalise mHM horizon depth
          !  Last layer depth is soil type dependent, and hence it assigned within the inner loop 
          ! by default for the first soil layer
          dpth_f = 0.0_dp
          dpth_t = HorizonDepth(H)
          ! check for the layer (2, ... n-1 layers) update depth
          if(H .gt. 1 .and. H .lt. nHorizons_mHM) then
             dpth_f = HorizonDepth(H - 1)
             dpth_t = HorizonDepth(H)
          end if

          !$OMP PARALLEL
          !$OMP DO PRIVATE( l, s ) SCHEDULE( STATIC )
          cellloop0: do k = 1, size(LCOVER0,1)
             l = LCOVER0(k)
             s = soilID0(k,1)  !>> in this case the second dimension of soilId0 = 1
             ! depth weightage bulk density
             Bd0(k) = sum( Db(s,:nTillHorizons(s), L)*Wd(S, H, 1:nTillHorizons(S) ), &
                  Wd(S,H, 1:nTillHorizons(S)) > 0.0_dp ) &
                  + sum( dbM(S,nTillHorizons(S)+1 : nHorizons(S)) &
                  * Wd(S,H, nTillHorizons(S)+1:nHorizons(S)), &
                  Wd(S,H, nTillHorizons(S)+1:nHorizons(S)) >= 0.0_dp )
             ! depth weightage thetaS
             SMs0(k) = sum( thetaS_till(S,:nTillHorizons(s), L) &
                  * Wd(S,H, 1:nTillHorizons(S) ), &
                  Wd(S,H, 1:nTillHorizons(S)) > 0.0_dp ) &
                  + sum( thetaS(S,nTillHorizons(S)+1-minval(nTillHorizons(:)):nHorizons(s)-minval(nTillHorizons(:))) &
                  * Wd(S,H, nTillHorizons(S)+1:nHorizons(S)), &
                  Wd(S,H, nTillHorizons(S)+1:nHorizons(S)) > 0.0_dp )
             ! depth weightage FC
             FC0(k) = sum( thetaFC_till(S, :nTillHorizons(s), L) &
                  * Wd(S, H, 1:nTillHorizons(S) ), &
                  Wd(S, H, 1:nTillHorizons(S)) > 0.0_dp ) &
                  + sum( thetaFC(S, nTillHorizons(S)+1-minval(nTillHorizons(:)):nHorizons(s)-minval(nTillHorizons(:))) &
                  * Wd(S, H, nTillHorizons(S)+1:nHorizons(S)), &
                  Wd(S, H, nTillHorizons(S)+1:nHorizons(S)) > 0.0_dp )
             ! depth weightage PWP
             PW0(k) = sum( thetaPW_till(S, :nTillHorizons(s), L) &
                  * Wd(S, H, 1:nTillHorizons(S) ), &
                  Wd(S, H, 1:nTillHorizons(S)) > 0.0_dp ) &
                  + sum( thetaPW(S,nTillHorizons(S)+1-minval(nTillHorizons(:)) :nHorizons(s)-minval(nTillHorizons(:))) &
                  * Wd(S, H, nTillHorizons(S)+1:nHorizons(S)), &
                  Wd(S, H, nTillHorizons(S)+1:nHorizons(S)) > 0.0_dp )
             ! Horizon depths: last soil horizon is varying, and thus the depth
             ! of the horizon too...
             if(H .eq. nHorizons_mHM) then
                dpth_f = HorizonDepth(nHorizons_mHM - 1)
                dpth_t = RZdepth(S) 
             end if
             ! other soil properties [SMs, FC, PWP in mm]
             SMs0(k) = SMs0(k) * (dpth_t - dpth_f)
             FC0(k)  = FC0(k)  * (dpth_t - dpth_f)
             PW0(k)  = PW0(k)  * (dpth_t - dpth_f)
          end do cellloop0
          !$OMP END DO
          !$OMP END PARALLEL    

          tmp_FC0min=minval(FC0(:))
          tmp_FC0max=maxval(FC0(:))

          if(tmp_FC0min .lt. 0.0_dp) then
             tmp_FC0min=minval(FC0(cell_id0))
          end if

          !$OMP PARALLEL
          !$OMP DO PRIVATE( l, tmp_rootFractionCoefficient_perviousFC ) SCHEDULE( STATIC )
          celllloop0: do k = 1, size(LCOVER0,1)
             l = LCOVER0(k)
             !---------------------------------------------------------------------
             ! Effective root fractions in soil horizon... 
             !  as weightage sum (according to LC fraction)
             !---------------------------------------------------------------------
             ! vertical root distribution = f(LC), following asymptotic equation
             ! [for refrence see, Jackson et. al., Oecologia, 1996. 108(389-411)]

             ! Roots(H) = 1 - beta^d
             !  where,  
             !   Roots(H) = cumulative root fraction [-], range: 0-1
             !   beta     = fitted extinction cofficient parameter [-], as a f(LC)
             !   d        = soil surface to depth [cm] 

             ! NOTES **
             !  sum(fRoots) for soil horions = 1.0 

             !  if [sum(fRoots) for soil horions < 1.0], then 
             !  normalise fRoot distribution such that all roots end up
             !  in soil horizon and thus satisfying the constrain that
             !  sum(fRoots) = 1

             !  The above constrains means that there are not roots below the soil horizon. 
             !  This may or may not be realistic but it has been coded here to satisfy the
             !  conditions of the EVT vales, otherwise which the EVT values would be lesser
             !  than the acutal EVT from whole soil layers.

             !  Code could be modified in a way that a portion of EVT comes from the soil layer
             !  which is in between unsaturated and saturated zone or if necessary the saturated
             !  layer (i.e. Groundwater layer) can also contribute to EVT. Note that the above 
             !  modification should be done only if and only if [sum(fRoots) for soil horions < 1.0]. 
             !  In such cases, you have to judiciously decide which layers (either soil layer between 
             !  unsaturated and saturated zone or saturated zone) will contribute to EVT and in which
             !  proportions. Also note that there are no obervations on the depth avialable ata a 
             !  moment on these layers. 
             !------------------------------------------------------------------------

             select case(L)
             case(1)      
                ! forest
                fRoots0(k) = (1.0_dp - tmp_rootFractionCoefficient_forest**(dpth_t*0.1_dp)) &
                     - (1.0_dp - tmp_rootFractionCoefficient_forest**(dpth_f*0.1_dp) )
             case(2)
                ! impervious
                fRoots0(k) = (1.0_dp - tmp_rootFractionCoefficient_impervious**(dpth_t*0.1_dp)) &
                     - (1.0_dp - tmp_rootFractionCoefficient_impervious**(dpth_f*0.1_dp) )
             case(3)
                
                select case (processMatrix(3,1))
                case(1:2)
                   ! permeable   
                   fRoots0(k) = (1.0_dp - tmp_rootFractionCoefficient_pervious**(dpth_t*0.1_dp)) &
                       - (1.0_dp - tmp_rootFractionCoefficient_pervious**(dpth_f*0.1_dp) )
                     
                case(3)
                   ! permeable 
                   ! introducing FC dependency on root frac coef. by Simon Stisen and M. Cuneyd Demirel from GEUS.dk
                   tmp_rootFractionCoefficient_perviousFC=(((FC0(k) - tmp_FC0min)/ &
                        ((tmp_FC0max-tmp_FC0min)) * tmp_rootFractionCoefficient_clay)) &
                        + ((1-(FC0(k) - tmp_FC0min)/(tmp_FC0max-tmp_FC0min)) * &
                        tmp_rootFractionCoefficient_sand)  

                   if(tmp_rootFractionCoefficient_perviousFC .lt. 0.0_dp .OR. tmp_rootFractionCoefficient_perviousFC .gt. 1.0_dp) &
                        print*, "CHECK tmp_rootFractionCoefficient_perviousFC", tmp_rootFractionCoefficient_perviousFC
                   
                   fRoots0(k) = (1.0_dp - tmp_rootFractionCoefficient_perviousFC**(dpth_t*0.1_dp)) &
                        - (1.0_dp - tmp_rootFractionCoefficient_perviousFC**(dpth_f*0.1_dp) )  
                   
                   if((fRoots0(k) .lt. 0.0_dp) .OR. (fRoots0(k) .gt. 1.0_dp)) then
                      call message('***ERROR: Fraction of roots out of range [0,1]. Cell', &
                           num2str(k), ' has value ', num2str(fRoots0(k)))
                      ! stop
                   end if
                end select
             end select

          end do celllloop0
          !$OMP END DO
          !$OMP END PARALLEL

          beta0 = Bd0*param(4)

          !---------------------------------------------
          ! Upscale the soil related parameters
          !---------------------------------------------
          L1_SMs(:,h) = upscale_harmonic_mean( nL0_in_L1, Upp_row_L1, Low_row_L1, &
               Lef_col_L1, Rig_col_L1, cell_id0, mask0, nodata, SMs0 )
          L1_beta(:,h) = upscale_harmonic_mean( nL0_in_L1, Upp_row_L1, Low_row_L1, &
               Lef_col_L1, Rig_col_L1, cell_id0, mask0, nodata, beta0 )
          L1_PW(:,h) = upscale_harmonic_mean( nL0_in_L1, Upp_row_L1, Low_row_L1, &
               Lef_col_L1, Rig_col_L1, cell_id0, mask0, nodata, PW0 )
          L1_FC(:,h) = upscale_harmonic_mean( nL0_in_L1, Upp_row_L1, Low_row_L1, &
               Lef_col_L1, Rig_col_L1, cell_id0, mask0, nodata, FC0 )
          L1_fRoots(:,h) = upscale_harmonic_mean( nL0_in_L1, Upp_row_L1, Low_row_L1, &
               Lef_col_L1, Rig_col_L1, cell_id0, mask0, nodata, fRoots0 )

       end do
       ! to handle multiple soil horizons with unique soil class   
    CASE(1)
       ! horizon wise calculation
       do h = 1, nHorizons_mHM
          Bd0     = nodata
          SMs0    = nodata
          FC0     = nodata
          PW0     = nodata
          fRoots0 = nodata
          tmp_rootFractionCoefficient_perviousFC = nodata
          ! initalise mHM horizon depth
          if (h .eq. 1 ) then
             dpth_f = 0.0_dp
             dpth_t = HorizonDepth(h)
             ! check for the layer (2, ... n-1 layers) update depth
          else 
             dpth_f = HorizonDepth(h-1)
             dpth_t = HorizonDepth(h)
          end if
          ! need to be done for every layer to get fRoots
          !$OMP PARALLEL
          !$OMP DO PRIVATE( l, s ) SCHEDULE( STATIC )
          cellloop1: do k = 1, size(LCOVER0,1)
             L = LCOVER0(k)
             s =  soilID0(k,h)
             if ( h .le. nTillHorizons(1) ) then
                Bd0(k)  = Db(s,1,L)
                SMs0(k) = thetaS_till (s,1,L) * (dpth_t - dpth_f) ! in mm
                FC0(k)  = thetaFC_till(s,1,L) * (dpth_t - dpth_f) ! in mm
                PW0(k)  = thetaPW_till(s,1,L) * (dpth_t - dpth_f) ! in mm
             else
                Bd0(k)  = DbM(s,1)
                SMs0(k) = thetaS (s,1) * (dpth_t - dpth_f) ! in mm
                FC0(k)  = thetaFC(s,1) * (dpth_t - dpth_f) ! in mm
                PW0(k)  = thetaPW(s,1) * (dpth_t - dpth_f) ! in mm          
             end if
          end do cellloop1
          !$OMP END DO
          !$OMP END PARALLEL    


          tmp_FC0min=minval(FC0(:))
          tmp_FC0max=maxval(FC0(:))

          if(tmp_FC0min .lt. 0.0_dp) then 
             print*,"CHECK FC0min, -9999s effected",tmp_FC0min
             tmp_FC0min=minval(FC0(cell_id0))
             print*,"NEW FC0min is",tmp_FC0min
          end if

          !$OMP PARALLEL
          !$OMP DO PRIVATE( l, tmp_rootFractionCoefficient_perviousFC ) SCHEDULE( STATIC )
          celllloop1: do k = 1, size(LCOVER0,1)
             l = LCOVER0(k)
             !================================================================================
             ! fRoots = f[LC] --> (fRoots(H) = 1 - beta^d)
             ! see below for comments and references for the use of this simple equation
             ! NOTE that in this equation the unit of soil depth is in cm 
             !================================================================================

             select case(L)
             case(1)              
                ! forest
                fRoots0(k) = (1.0_dp - tmp_rootFractionCoefficient_forest**(dpth_t*0.1_dp)) &
                     - (1.0_dp - tmp_rootFractionCoefficient_forest**(dpth_f*0.1_dp) )
             case(2)              
                ! impervious
                fRoots0(k) = (1.0_dp - tmp_rootFractionCoefficient_impervious**(dpth_t*0.1_dp)) &
                     - (1.0_dp - tmp_rootFractionCoefficient_impervious**(dpth_f*0.1_dp) )
             case(3)

                select case (processMatrix(3,1))

                case(1:2)        
                   ! permeable   
                   fRoots0(k) = (1.0_dp - tmp_rootFractionCoefficient_pervious**(dpth_t*0.1_dp)) &
                       - (1.0_dp - tmp_rootFractionCoefficient_pervious**(dpth_f*0.1_dp) )
                           
                case(3)
                   ! permeable 
                   !introducing FC dependency on root frac coef. by Simon Stisen and M. Cuneyd Demirel from GEUS.dk
                   tmp_rootFractionCoefficient_perviousFC=(((FC0(k) - tmp_FC0min)/&
                        ((tmp_FC0max-tmp_FC0min)) * tmp_rootFractionCoefficient_clay))&
                        + ((1-(FC0(k) - tmp_FC0min)/(tmp_FC0max-tmp_FC0min)) * &
                        tmp_rootFractionCoefficient_sand)  

                   if(tmp_rootFractionCoefficient_perviousFC .lt. 0.0_dp .OR. tmp_rootFractionCoefficient_perviousFC .gt. 1.0_dp) &
                        print*, "CHECK tmp_rootFractionCoefficient_perviousFC", tmp_rootFractionCoefficient_perviousFC

                   fRoots0(k) = (1.0_dp - tmp_rootFractionCoefficient_perviousFC**(dpth_t*0.1_dp)) &
                        - (1.0_dp - tmp_rootFractionCoefficient_perviousFC**(dpth_f*0.1_dp) )  

                   if((fRoots0(k) .lt. 0.0_dp) .OR. (fRoots0(k) .gt. 1.0_dp)) then
                      call message('***ERROR: Fraction of roots out of range [0,1]. Cell', &
                           num2str(k), ' has value ', num2str(fRoots0(k)))
                      ! stop
                   end if
                end select
             end select

          end do celllloop1
          !$OMP END DO
          !$OMP END PARALLEL

          ! beta parameter
          beta0 = Bd0*param(4)

          ! Upscale the soil related parameters
          L1_SMs(:,h)  = upscale_harmonic_mean( nL0_in_L1, Upp_row_L1, Low_row_L1, &
               Lef_col_L1, Rig_col_L1, cell_id0, mask0, nodata, SMs0 )
          L1_beta(:,h) = upscale_harmonic_mean( nL0_in_L1, Upp_row_L1, Low_row_L1, &
               Lef_col_L1, Rig_col_L1, cell_id0, mask0, nodata, beta0)
          L1_PW(:,h)   = upscale_harmonic_mean( nL0_in_L1, Upp_row_L1, Low_row_L1, &
               Lef_col_L1, Rig_col_L1, cell_id0, mask0, nodata, PW0  )
          L1_FC(:,h)   = upscale_harmonic_mean( nL0_in_L1, Upp_row_L1, Low_row_L1, &
               Lef_col_L1, Rig_col_L1, cell_id0, mask0, nodata, FC0  )
          L1_fRoots(:,h) = upscale_harmonic_mean( nL0_in_L1, Upp_row_L1, Low_row_L1, &
               Lef_col_L1, Rig_col_L1, cell_id0, mask0, nodata, fRoots0 )

       end do
       ! anything else   
    CASE DEFAULT
       call message()
       call message('***ERROR: iFlag_soilDB option given does not exist. Only 0 and 1 is taken at the moment.')
       stop
    END SELECT


    ! below operations are common to all soil databases flags
    !$OMP PARALLEL
    !------------------------------------------------------------------------
    ! CHECK LIMITS OF PARAMETERS
    !   [PW <= FC <= ThetaS]
    !  units of all variables are now in [mm]
    ! If by any means voilation of this rule appears (e.g. numerical errors)
    ! than correct it --> threshold limit = 1% of the upper ones
    !------------------------------------------------------------------------
    L1_FC = merge( L1_SMs - 0.01_dp * L1_SMs, L1_FC, L1_FC .gt. L1_SMs)
    L1_PW = merge( L1_FC  - 0.01_dp * L1_FC,  L1_PW, L1_PW .gt. L1_FC)
    ! check the physical limit
    L1_SMs = merge( 0.0001_dp, L1_SMs, L1_SMs .lt. 0.0_dp )
    L1_FC  = merge( 0.0001_dp, L1_FC,  L1_FC  .lt. 0.0_dp )
    L1_PW  = merge( 0.0001_dp, L1_PW,  L1_PW  .lt. 0.0_dp )
    ! Normalise the vertical root distribution profile such that [sum(fRoots) = 1.0]
    !$OMP DO PRIVATE( fTotRoots ) SCHEDULE( STATIC )
    do k = 1, size(L1_fRoots,1)
       fTotRoots = sum(L1_fRoots(k, :), L1_fRoots(k, :) .gt. 0.0_dp)
       ! This if clause is necessary for test program but may be redundant in actual program
       if ( fTotRoots .gt. 0.0_dp ) then
          L1_fRoots(k, :) = L1_fRoots(k,:) / fTotRoots
       else
          L1_fRoots(k, :) = 0.0_dp
       end If
    end do



    !$OMP END DO  
    !$OMP END PARALLEL


  end subroutine mpr_SMhorizons

end module mo_mpr_SMhorizons


