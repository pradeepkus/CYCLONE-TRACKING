;===========================================================================================
;                 This code detects cyclonic systems and stores them in array  
;===========================================================================================

 begin 

  DataPath         = "/home/pradeep/Desktop/DATA/ERA-5/"  
  PlotPath         = "/home/pradeep/Desktop/Dropbox/PAPER2/AUTOMATIC_TRACKING/FIGURES/"

 f                 = addfile(DataPath+"ERA5_600HPA.grib","r")

;=====================================
;  flage for anomaly or actual field
;======================================

   ANOMALY_FIELD =  True
     TOTAL_FIELD =  True

;===================================================================
;               DEFINING THE REGION OF INTREST 
;   ARABIAN SEA, BAY OF BENGAL, AFRICA , SOUTH CHINA SEA
;===================================================================

; ; Choose the domain in which we want to track the cyclone; larger the size more time it will take to run 


; la1      =  5   ; START LATITUDE
; la2      =  30  ; END LATITUDE
; lo1      =  45  ; START LOGITUDE
; lo2      =  115 ; END LOGITUDE
; lev0     =  600 ; PRESSURE LEVEL

;---------   small test domain to see if detection is correct-------------------------

 la1       =  0   ; START LATITUDE
 la2       =  30  ; END LATITUDE
 lo1       =  45  ; START LOGITUDE
 lo2       =  95  ; END LOGITUDE
;lev0      =  600 ; PRESSURE LEVEL

;------------------choose the domain side litte wide so that the minimum can be detected even at the boundary.

LAT_WIDTH_REQURED   = 3  ; IN DEGREE THE SIZE OF ROTATED DOMAIN
LON_WIDTH_REQURED   = 3  ; IN DEGREE THE SIZE OF ROTATED DOMAIN

;================================================================================
; THIS IS THE DEFINATION OF THE LAYERS TO IFENTIFY THE MIDDLE TROPOSPHERECYCLONE
;===============================================================================

  l1   = 1000       ; STARTING PRESSURE LEVEL FOR LOWER LAYER ,  SI_L1
  l2   = 850        ; END PRESSURE LEVEL FOR  LOER LEVEL LAYER , SI_L2
  m1   = 650        ; STARTING PRESSURE FOR MIDDLE TROPOSPHERE LAYER, SI_M1
  m2   = 500        ; END PRESSURE LEVEL  FOR MIDDLE TROPOSPHERE LAYER SI_M2
  u1   = 350        ; STARTING PRESSUE LEVEL FOR UPPER LAYER , SI_U1
  u2   = 200        ; END PRESSURE LEVEL FOR UPPER LAYER, SI_U2 
   

LAT_MIN_MARGEN   =  la1-(LAT_WIDTH_REQURED)
LAT_MAX_MARGEN   =  la2+(LAT_WIDTH_REQURED)   

LON_MIN_MARGEN   =  lo1-(LON_WIDTH_REQURED)
LON_MAX_MARGEN   =  lo2+(LON_WIDTH_REQURED)   

;-------------------------------------------------------------------------------------------------------------
; ; defining the time Limits to get the data of intrest.

TIME_ERA         = f->initial_time0_hours

TIME_GDS0_ISBL   = cd_calendar(TIME_ERA, 3)

TT1 = ind(TIME_GDS0_ISBL.eq.2000060100) ;;
TT2 = ind(TIME_GDS0_ISBL.eq.2000093000) ;;

if (TOTAL_FIELD) then

    print_clock("extracting variables Z")

     h              = f->Z_GDS0_ISBL(TT1:TT2,:,{LAT_MIN_MARGEN:LAT_MAX_MARGEN}, {LON_MIN_MARGEN:LON_MAX_MARGEN})  

    print_clock("extracting variables W")  

     vor            = f->VO_GDS0_ISBL(TT1:TT2,:,{LAT_MIN_MARGEN:LAT_MAX_MARGEN},{LON_MIN_MARGEN:LON_MAX_MARGEN})

    print_clock("extracting variables Q")  

    q1              = f->Q_GDS0_ISBL(TT1:TT2,:,{LAT_MIN_MARGEN:LAT_MAX_MARGEN}, {LON_MIN_MARGEN:LON_MAX_MARGEN})  

end if 

;-------------------------------------------------------------------------------------------------------------------------------------------------
;                                         DO SMOOTING TO REMOVE NOISE
; smooting removes the small minima which might not be associated with weak cyclone or orograophic waves.
;  So the large cyclones will be highlighted. It is not necessary but it increases the accuracy and runs the code much faster.   
;-------------------------------------------------------------------------------------------------------------------------------------------------

h = smth9(h, 0.50,  0.25, True)
h = smth9(h, 0.50,  0.25, True)
h = smth9(h, 0.50,  0.25, True)
h = smth9(h, 0.50,  0.25, True)
;
;h = smth9(h, 0.50,  0.25, True)
;h = smth9(h, 0.50,  0.25, True)
;h = smth9(h, 0.50,  0.25, True)
;h = smth9(h, 0.50,  0.25, True)
;
;;---------------------------------------------------------------------------------------------------------------------------------------------------

print_clock("DEFINIG variables")  


  q         =  q1*1000 ; convert g/kg into kg/kg

  copy_VarCoords(q1,q)

 time       = vor&initial_time0_hours
 lev        = vor&lv_ISBL1
 lat        = vor&g0_lat_2
 lon        = vor&g0_lon_3

;---------------------------------------------------------------------------------------------------------------------------------------------------

 LAT        = dimsizes(lat)
 LON        = dimsizes(lon)
 LEV        = dimsizes(lev)

 h!0        = "time"
 h!1        = "lev"
 h!2        = "lat"
 h!3        = "lon"
 h&time     =  time
 h&lev      =  lev
 h&lat      =  lat
 h&lon      =  lon 

; D2         = dimsizes(time)
 TIME       = cd_calendar(time,3)

print_clock("calculate vorticity") 
 
vr          = 10^5*vor

date = cd_calendar(time,3)

print(date)

copy_VarCoords(h,vr)  

vr@units        = "10^5 s-1"

D1  = TT1            ; START DAY
D2  = TT2            ;dimsizes(time)   ; TOTAL NUMBER OF STEPS OR DAY IN THE DATA

;=======================================================================================================
SIZE_ARRAY = (TT2-TT1) + 1 ; this is the total time step in the range of data
;=======================================================================================================

NMM                     = 300                                                   ; 300 is asafe value on any single day systems can be more than 300
lev_com                 = todouble(lev)                                         ; array to store systems at each time step for all days
MIM                     = new( (SIZE_ARRAY)*NMM, double)                        ; maximum postible number of minima in all time step
M                       = dimsizes(MIM)                                         
VOR_DIFF                = new((/2,(SIZE_ARRAY)*NMM/), double)                   ; array to store vorticity difference
MTC_SIZE                = new( (SIZE_ARRAY)*NMM, double)                        ; array to store size of MTCs but not used  
NUMBER_MIN              = new( (SIZE_ARRAY), double)                            ; array to store number of minimum at each time step   
    
print_clock("DOMIAN DEFINATION COMPELETE")                               

;=========================================================================================================
;        NOW WE CREAT SOME ARRAY TO STORE THE INDEX OF EACH MINIMA SO WE CAN IDENTIDY EACH 
;                           ONE OF THEM CCORDING TO THEIR INDEX VALUE
;=========================================================================================================

MIN_INDEX_RECORD    =  new( (SIZE_ARRAY)*NMM, double )   ;;  TO CONTAIN THE INDEX VALUE FOR EACH MTC, MD
TIME_RECORD         =  new( (SIZE_ARRAY)*NMM, double )   ;;  TO RECORD THE DIMENTIONS OF THE TIME FOR MAXIMUM;; MEANING;; FOR EXAMPLE 20000601 WE HAVE 5 MINIMA THEN KEEP WRIGHTING 2000 DATE FOR THEM
LAT_RECORD          =  new( (SIZE_ARRAY)*NMM, double )   ;;  TO RECORD THE LATITUDE OF MINIMA WILL HELP IN TRAKE MAKING
LON_RECORD          =  new( (SIZE_ARRAY)*NMM, double )   ;;  TO RECORD THE LONGOTUDE OF EACH MINIMA WILL HElP IN TRACK MAKING
H_RECORD            =  new( (SIZE_ARRAY)*NMM, double )   ;;  TO RECORD THE  MINIM GEOPOTENTIAL CORROSPONDING TO EEACH MINIMA
Q_RECORD            =  new( (SIZE_ARRAY)*NMM, double )   ;;  TO RECORED THE MEAN SPACIFIC MUMIDITY IN MIDDLE LAYER
VOR_RECORD          =  new((/3,(SIZE_ARRAY)*NMM/),double);;  TO RECORED MEAN UPPER LOWER AND MIDDEL  RELATIVE VORTICITY VALUE, THREE
LEV_VMAX_RECO       =  new((/(SIZE_ARRAY)*NMM/),double)
TIME_FULL           =  new( (SIZE_ARRAY), double )       ;;  TO RECORED MEAN UPPER LOWER AND MIDDEL  RELATIVE VORTICITY VALUE, THREE DIMESION FOR LOWER MIDDLE AND UPPER
NUMNER_MIN          =  new( (SIZE_ARRAY), double )

MIN_INDEX_RECORD!0     = "min_index"
TIME_RECORD!0          = "time_index"
LAT_RECORD!0           = "lat_index"
LON_RECORD!0           = "lon_index"

VOR_RECORD!0           = "vor_lmu"
VOR_RECORD!1           = "min_flag"

Q_RECORD!0             =  "humidity_index"

Q_RECORD@units         =   "kg/kg"
LAT_RECORD@units       =   vor&g0_lat_2@units
LON_RECORD@units       =   vor&g0_lon_3@units
TIME_RECORD@units      =   vor&initial_time0_hours@units
VOR_RECORD@units       =   "10^-5 s-1"
TIME_FULL@units        =   vor&initial_time0_hours@units

TIME_RECORD@calendar   =   "standard"
TIME_RECORD@bounds     =   "time_bnds"
TIME_RECORD@long_name  =   "time"

time_com           = time                           ;; ARRAY TO RECORD THE TIME FOR WHICH MINIMA HS BEEN DETECTED

 MIM!0             =  "mini"                        ;; THIS IS THE COORDINATED VARIABLE WHICH WILL CONNECT ALL MAXIMA IN ARRAY
 MIM&mini          =  MIM                           ;; NAMING THE DIMESION MIN
time_com!0         = "time"                         ;; ASSIGNING CORRDINATE VARIABLE NAME FOR TIME
time_com&time      =  time_com                      ;; ASSIGNING COORDINATE VALUES FOR TIME

TIME_FULL!0       = "time"
TIME_FULL&time    = time
;=============================================================================================================
;               DEFINE ARRAY TO RECORD VARIABLE NOTE THAT THEY ARE OUTSIDE OF TIME LOOP 
    ; IF INSIDE THEY WILL ALL BECOME NEW IN EACH TIME STEP AND AND WE WILL NOT BE ABLE TO STORE VALUES
;=============================================================================================================

last_no_min = 0     ;; THIS IS THE DECLEARITION TO RECORD THE VALUES OF MINNIMA NUMBER CORSSED AFTER EACH TIME STEP
m           = 0
;===================================STARTING THE TIME LOOP=============================================
;  HERE D1  = 0  IS THE START INDEX OF LOOP D2 IS THE FINAL INDEX (TOTAL TIME STEP IN THE DATA)
;======================================================================================================
print_clock("begning of time loop")  

;return

do TT = TT1-TT1, TT2-TT1 ; since array index start form 0 to total number of time steps indata slice

         ;==============================================================================
        ;    CLACULATING EACH MINIMA  FOR EACH TIME STEP IN THE SPECIFIED REGION
        ;===============================================================================
         h_region    =  h(TT,{600},{la1:la2},{lo1:lo2})
        ;================================================================================
        ;                 NOW WE CALCULATE THE LOCAL MINIMA IN REGION OF INTREST
        ;================================================================================

         locmin      =  local_min(h_region,True,0.)


         x=h_region&lon(locmin@xi)                 ; GET LAT/LON POINTS OF MINIMA
         y=h_region&lat(locmin@yi)                 ; 
         minvalue = locmin@minval                  ; GET THE VALUES OF MINIMA

        ;=======================p==========================================================
        ;               VALUES TO STORE THE U V... FOR SLICING IN PRESSURE
        ;=================================================================================

          voravg = vr(TT,:,:,:)                    ; JUST TO REMOVE THE 0 TIME DIMENTIONS IF ANY
          qavg   = q(TT,:,:,:)
          havg   = h(TT,:,:,:)

        ;===============================================================================================================================
        ;             MAKE VORTICITY POSITIVE BLOW THE THE EQUATOR so differential vorticity will have same sign and constraint
        ;================================================================================================================================

                 if (LAT_MIN_MARGEN.lt.0) then 

                  voravg(:,{LAT_MIN_MARGEN:0},{:})  = -1*voravg(:,{LAT_MIN_MARGEN:0},{:}) ; make vorticity sout of eqator of postive sign

                 end if 

                 vor_low  = dim_avg_n_Wrap(voravg({l1:l2},{la1:la2},{lo1:lo2}),0)     ;; VORTICITY AVERAGE OVER LOWER ATMOSPHERE
                 vor_mid  = dim_avg_n_Wrap(voravg({m1:m2},{la1:la2},{lo1:lo2}),0)     ;; VORTICITY AVERAGE OVER MIDDEL ATMOSPHERE
                 vor_upp  = dim_avg_n_Wrap(voravg({u1:u2},{la1:la2},{lo1:lo2}),0)     ;; VORTICITY AVERAGE OVER UPPER ATMOSPHERE

                 q_mid      = dim_avg_n_Wrap(  qavg({m1:m2},{la1:la2},{lo1:lo2}),0)   ;; AVERAGE OF SPACIFIC HUMIDITY IN MIDDEL TROPOSPHERE
                 h_mid      = dim_avg_n_Wrap(  havg({m1:m2},{la1:la2},{lo1:lo2}),0)

                ;===============================================================================
                 VOR_filter =  vr(TT,:,:,:)
                 H_filter   =  h(TT,:,:,:)
                 Q_filter   =  q(TT,:,:,:)
                ;===============================================================================

            yy = dimsizes(y)

           do m = 0, dimsizes(y)-1

                     NDX  = 2.0
                     NDY  = 2.0

                     X1   = x(m)-NDX
                     X2   = x(m)+NDX
                     Y1   = y(m)-NDY
                     Y2   = y(m)+NDY

;------------------------------------------------------------------------------------------
                     if (X1.lt.0) then

                       X1    = X1-358.5

                     end if  
;-----------------------------------------------------------------------------------------
                     if (X2.gt.358.5) then

                      X2    = X2-358.5

                     end if
;-----------------------------------------------------------------------------------------

                      VOM   :=  avg(vor_mid(  {Y1:Y2},  {X1:X2}  )) ;; TAKING AVERAGE OVER 2 DEGREE SQURE CENTERED OVER THE REF LAT LON
                      VOL   :=  avg(vor_low(  {Y1:Y2},  {X1:X2}  )) ;; FOR LOWE VORTICITY
                      VOU   :=  avg(vor_upp(  {Y1:Y2},  {X1:X2}  )) ;; FOR UPPER VORTICITY
                     ; P_min :=  min(mslp(  {Y1:Y2},  {X1:X2}  ))
                     ; V_max :=  max(vc(  {Y1-4:Y2+4},  {X1-4:X2+4}  ))
                      QM    :=  avg(q_mid  (  {Y1:Y2},  {X1:X2}  )) ;; ACTUAL HUMIDITY
                      HM    :=  avg(h_mid  (  {Y1:Y2},  {X1:X2}  )) ;; ANOMALY
                      VOM1  :=  dim_avg_n_Wrap(voravg(:,{Y1:Y2},{X1:X2} ), 1)
                      VOM0  :=  dim_avg_n_Wrap(VOM1, 1)

            ;========================================================================================
            ;                   CALCULATING THE LEVEL OF, MAXIMUM VORTICITY
            ;========================================================================================

                     VOR_LEV  := VOM0 
                     VOR_MAX  := max(VOM0)
                     NUM_MAX  := dimsizes(ind(VOR_MAX.eq.VOR_LEV))

                     if (NUM_MAX.ne.1) then           
                                                 ; selection if more then one maximum is observe (which is quite rare) 
                      II        := ind(VOR_MAX.eq.VOR_LEV)
                      IND_VMAX  := II(NUM_MAX-1) ; choose which is at upper level 
                      LEV_VMAX  := lev(IND_VMAX)

                     else

                      IND_VMAX := ind(VOR_MAX.eq.VOR_LEV)
                      LEV_VMAX := lev(IND_VMAX)

                     end if

                    ;=======================================================================================
                    ;                         CONDITION FOR VORTICITY MAX IN CENTER
                    ;=======================================================================================

                      VORCU :=  vor_upp( {y(m)}, {x(m)} ) ;; THIS IS TO MAKE SURE THE CENTER OF MTC HAVING MXIMUM VORTICITY IN THE CENTER
                      VORCM :=  vor_mid( {y(m)}, {x(m)} )
                      VORCL :=  vor_low( {y(m)}, {x(m)} )

                      pradeep   = m + last_no_min
          
                    ;;====================================================================================
                    ;;                        FLAGE FOR VERTICAL STRENGHT OF MTC
                    ;;====================================================================================

                       VOR_DIFF(0,pradeep)  =  VOM-VOL
                       VOR_DIFF(1,pradeep)  =  VOM-VOU

                    ;==============================================================================
                    ;                 strore the value of index
                     ;================================================================================

                       TIME_RECORD(pradeep)           =  todouble(time(TT)); TIME WHEN CYLONE DETECTED
                       LAT_RECORD(pradeep)            =  todouble(y(m))    ; LAT OF CYCLONE 
                       LON_RECORD(pradeep)            =  todouble(x(m))    ; LON OF CYCLONE 
                       VOR_RECORD(0,pradeep)          =  todouble(VOL)     ; LOW LEVEL VORTICITY OF CYCLONE
                       VOR_RECORD(1,pradeep)          =  todouble(VOM)     ; MIDDLE LEVEL VORTICITY OF CYCLONE 
                       VOR_RECORD(2,pradeep)          =  todouble(VOU)     ; UPPER LEVEL VORTICITY OF CYCLONE 
                       Q_RECORD(pradeep)              =  todouble(QM)      ; MIDDLE LEVEL MOISTURE OF CYCLONE
                       H_RECORD(pradeep)              =  todouble(HM)      ; Middle level geopotential heigh mean around the center
                       LEV_VMAX_RECO(pradeep)         =  todouble(LEV_VMAX); LEVEL OF VORTICITY MAXIMUM OF A CENTER;  
                     ;  RAINM(pradeep)                 =  todouble(RAINACC) ; 

         end do       ;; LOOP loop for maximum for mth time step

            last_no_min = pradeep + 1    ;  JUST STORE THE VALUE OF NUMBER OF CUMULATIVE MINIMA UPTO mTH time step
                                         ;   print_clock("working for DATE "+date(TT)+"rotating domain" )
            NUMNER_MIN(TT)  = yy

                   delete(x)             ; delete so new values can be stored
                   delete(y)
                   delete(minvalue)

            print_clock("WORKING ON TIME "+cd_calendar(time(TT),3)+"")


end do  ;; for each TT time loop


;-----------------------------------------------------------------------------------------------------------
         N_LIMIT = toint(sum(NUMNER_MIN))  ; claculated total number of minima detected in entire duration 
                                           ; this will allow to store the length of array of total
                                           ; number of systems and reduces the size of the array
;---------------------------------------------------------------------------------------------------------
;===================================================================================================
;                   now wrighting all cyclonic centers in Netcdf and their properties 
;===================================================================================================

                                         print_clock("WRIGHTING IN NETCDF")

basePath             =  "/home/pradeep/Desktop/Dropbox/CODE_SHURITU/data/"
pathOut              =  basePath + "CYCLONE_CENTERS_TEST_"+cd_calendar(time(TT1-TT1), 3)+"_"+cd_calendar(time(TT2-TT1), 3)+".nc"
makeNewFile          =  True
setfileoption( "nc", "Format", "LargeFile" )

      if ( makeNewFile ) then

          system( "rm " + pathOut )
          fout  = addfile( pathOut, "c" )

;==================================================================================================
                           ; create global attributes of the file (optional)
;==================================================================================================

               fAtt               = True            ; assign file attributes
               fAtt@title         = "NCL Simple Approach to netCDF Creation"
               fAtt@source_file   =  "original-file.nc"
               fAtt@Conventions   = "None"
               fAtt@creation_date = systemfunc ("date")
               fileattdef(fout , fAtt )            ; copy file attributes

;=====================================================================================================================
              ;make time an UNLIMITED dimension; recommended  for most applications
;=====================================================================================================================

              filedimdef(fout,"minima",-1,True) 

               fout->time               = time_com
               fout->TIME_FULL          = TIME_FULL
               fout->NUM_MIN            = NUMNER_MIN
               fout->MIN_INDEX_STORE    = MIM(0:N_LIMIT-1)
               fout->TIME_RECORD        = TIME_RECORD(0:N_LIMIT-1)
               fout->LAT_RECORD         = LAT_RECORD(0:N_LIMIT-1)
               fout->LON_RECORD         = LON_RECORD(0:N_LIMIT-1)
               fout->VOR_RECORD         = VOR_RECORD(:,0:N_LIMIT-1)
               fout->Q_RECORD           = Q_RECORD(0:N_LIMIT-1)
               fout->H_RECORD           = H_RECORD(0:N_LIMIT-1)
               fout->VOR_DIFF           = VOR_DIFF(:,0:N_LIMIT-1)
               fout->LEV_VMAX_RECO      = LEV_VMAX_RECO(0:N_LIMIT-1)

       else

           fout  = addfile( pathOut, "w" )

       end if

            print_clock("WRIGHTING OVER FOR ALL MINIMA" )


           ; print_clock("!!! GREAT  PLOTTING FINISHED !!!")

end
