load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
  diags_fname = fname+".te_budgets.txt"
  fname =  systemfunc("ls "+fname)
  fall = addfile(fname,"r")       ; Open netCDF files.  
  print("File used for energy diagnostics "+fname)
  print("done input summary")
  print(" ")  
  print("Summary of input to ncl script:")
  print("===============================")
  print(" ")

  print("dtime                    ="+dtime)
  ;
  ; initialization
  ;
  g         = 9.80665D0
  PI        = get_pi("double")
  deg2rad   = PI/180.0
  eps       = 1.0D-13
  ;
  ; get area
  ;
  vartmp=fall->SE_pBF
  latlon = all(isdim(vartmp,(/"time","lat","lon"/)))
  if (latlon) then
    nt  = dimsizes(vartmp(:,0,0))
    lat = fall->lat
    lat = deg2rad*lat
    lon = fall->lon
    lon = deg2rad*lon
    nlat=dimsizes(lat)
    nlon=dimsizes(lon)
    area  = new((/nlat,nlon/),typeof(vartmp(0,0,0)))    
    dlat  = lat(3)-lat(2)
    dlat2 = 0.5*dlat    
    dlon  = lon(2)-lon(1)
    j=0
    do i=0,nlon-1
      area(j,i) = (sin(lat(j)+dlat2)-sin(lat(j)))*dlon
    end do    
    do j=1,nlat-2
      dsinlat =  (sin(lat(j)+dlat2)-sin(lat(j)-dlat2))      
      do i=0,nlon-1
        area(j,i) = dsinlat*dlon
      end do
    end do
    j=nlat-1
    do i=0,nlon-1
      area(j,i) = (sin(lat(j))-sin(lat(j)-dlat2))*dlon
    end do
    area_sphere = sum(area)
  else
    nt   = dimsizes(vartmp(:,0))
    area = fall->area   (:)
    ncol = dimsizes(area(:))
    area_sphere = sum(area(0:ncol-1))          
  end if  
  

  print(" ")
  print(" ")


  print("suffix (parameterization side)")
  print("pBF: state passed to parameterizations, before energy fixer")
  print("pBP: after energy fixer, before parameterizations")
  print("pAP: after last phys_update in parameterizations and state saved for energy fixer")
  print("pAM: after dry mass correction calculate but not used in SE")
  print(" ")
  print("history files saved off here")

  if (dycore.eq."MPAS") then
  print("suffix (dynamics side)")
  print("dBF: state passed to parameterizations")
  print("dAP: dBF state + temperature and wind increments (no moisture change)")
  print("dAM: dBF state with full physics update (no physics-dynamics coupling dribbling errors)")
  end if


  if (dycore.eq."MPAS") then
    str_vars      = (/"SE","KE","WV","WL","WI"/)
    str_stage     = (/"pBF","pBP","pAP","pAM","zBF","zBP","zAP","zAM","dBF","dAP","dAM"/) 
    subcycle      = (/1D0,1D0,1D0,1D0,1D0,1D0,1D0,1D0,1D0,1D0,1D0/)          
  else
    str_vars      = (/"SE","KE","WV","WL","WI"/)
    str_stage     = (/"pBF","pBP","pAP","pAM","zBF","zBP","zAP","zAM"/)
    subcycle      = (/1D0,1D0,1D0,1D0,1D0,1D0,1D0,1D0/)          
  end if

  nvars       = dimsizes(str_vars)
  nstage      = dimsizes(str_stage)

  if (latlon) then
    vars          = new((/nvars,nstage,nt,nlat,nlon/),typeof(vartmp(0,0,0)))
    tot_energy    = new((/3,nt,nstage/),typeof(vartmp(0,0,0)))
    tot_energy_2d = new((/nt,nstage,nlat,nlon/),typeof(vartmp(0,0,0)))
    tracer_mass   = new((/nt,3,nstage/),typeof(vartmp(0,0,0)))
    int_vars      = new((/nvars,nstage,nt/)     ,typeof(vartmp(0,0,0)))        
  else
    vars          = new((/nvars,nstage,nt,ncol/),typeof(vartmp(0,0)))
    tot_energy    = new((/3,nt,nstage/),typeof(vartmp(0,0)))
    tot_energy_2d = new((/nt,nstage,ncol/),typeof(vartmp(0,0)))
    tracer_mass   = new((/nt,3,nstage/),typeof(vartmp(0,0)))
    int_vars      = new((/nvars,nstage,nt/)     ,typeof(vartmp(0,0)))    
  end if
  vars = 0.0D0  
  tot_energy_2d =  0.0D0


  int_vars  = 0.0D0
  ;
  ; check that variables are on file and read them and compute global integrals
  ;
  inv_area_sphere   = 1.0D0/area_sphere
  print("nvars="+nvars)
  do variable=0,nvars-1
    do stage=0,nstage-1
      str = str_vars(variable)+"_"+str_stage(stage)
      print("str = "+str)
      if (isfilevar(fall,str)) then
        if (latlon) then
          vars(variable,stage,:,:,:) = fall->$str$(:,:,:)
          do t=0,nt-1
            int_vars(variable,stage,t) = sum(area(:,:)*vars(variable,stage,t,:,:))*inv_area_sphere		  
	  end do
	else
          fld = fall->$str$(:,:)
	  if (dimsizes(fld(0,:)).eq.ncol) then
            vars(variable,stage,:,0:ncol-1) = fall->$str$(:,:)
            do t=0,nt-1	      
              int_vars(variable,stage,t) = sum(area(0:ncol-1)*fld(t,0:ncol-1))*inv_area_sphere
	    end do
          else
            do t=0,nt-1	      	  
              int_vars(variable,stage,t) = sum(area(0:ncol-1)*fld(t,0:ncol-1))*inv_area_sphere
              vars(variable,stage,:,0:ncol-1) = fall->$str$(:,:)	  
	    end do
	  end if
	  delete(fld)
   	end if
	
      else
        print("Variable "+str+" not found")
        exit
      end if
    end do
  end do
  print("Done integrals")
  ;
  ; For code clarity define indices corresponding to the different stages
  ;
  ipBF = str_match_ind(str_stage,"pBF")
  ipBP = str_match_ind(str_stage,"pBP")
  ipAP = str_match_ind(str_stage,"pAP")
  ipAM = str_match_ind(str_stage,"pAM")

  izBF = str_match_ind(str_stage,"zBF")
  izBP = str_match_ind(str_stage,"zBP")
  izAP = str_match_ind(str_stage,"zAP")
  izAM = str_match_ind(str_stage,"zAM")

  idBF = str_match_ind(str_stage,"dBF")
  idAP = str_match_ind(str_stage,"dAP")
  idAM = str_match_ind(str_stage,"dAM")



  do t=0,nt-1
    do j=0,nstage-1
      tot_energy(0,t,j)     = subcycle(j)*(int_vars(0,j,t)+int_vars(1,j,t))
      ;
      ;
      tot_energy(1,t,j)  = subcycle(j)*int_vars(0,j,t) ; thermal energy only
      tot_energy(2,t,j)  = subcycle(j)*int_vars(1,j,t) ; K energy only	       

      if (latlon) then
        tot_energy_2d(t,j,:,:) = subcycle(j)*(vars(0,j,t,:,:)+vars(1,j,t,:,:))
      else
        tot_energy_2d(t,j,:)   = subcycle(j)*(vars(0,j,t,:)+vars(1,j,t,:))
      end if

      idx = str_match_ind(str_vars,"WV")
      tracer_mass(t,0,j) = subcycle(j)*(int_vars(idx,j,t))
      idx = str_match_ind(str_vars,"WL")
      tracer_mass(t,1,j) = subcycle(j)*(int_vars(idx,j,t))
	
	print("iii "+j+" "+tracer_mass(t,2,j)+" "+int_vars(idx,j,t))		
      idx = str_match_ind(str_vars,"WI")
      tracer_mass(t,2,j) = subcycle(j)*(int_vars(idx,j,t))
      print("qqq "+str_stage(j)+" "+tracer_mass(t,2,j)+" "+int_vars(idx,j,t))
    end do
  end do
  print("  ")
  print("  ")
  print("  ")
  print("ANALYSIS_START_ANALYSIS_START_ANALYSIS_START_ANALYSIS_START_ANALYSIS_START_ANALYSIS_START")
  print("  ")
  print("  ")
  print("  ")

  energy_names = new(3, string)
  energy_names = (/"TOTAL ENERGY","THERMAL ENERGY","KINETIC ENERGY"/)

    pEFIX  = new((/3/),typeof(tot_energy(0,0,0)))
    pDMEA  = new((/3/),typeof(tot_energy(0,0,0)))
    param  = new((/3/),typeof(tot_energy(0,0,0)))
    phys_total  = new((/3/),typeof(tot_energy(0,0,0)))
    zEFIX  = new((/3/),typeof(tot_energy(0,0,0)))
    zDMEA  = new((/3/),typeof(tot_energy(0,0,0)))
    zaram  = new((/3/),typeof(tot_energy(0,0,0)))
    zhys_total  = new((/3/),typeof(tot_energy(0,0,0)))

      dEFIX  = new((/3/),typeof(tot_energy(0,0,0)))
      dDMEA  = new((/3/),typeof(tot_energy(0,0,0)))
      dparam = new((/3/),typeof(tot_energy(0,0,0)))
      dphys_total  = new((/3/),typeof(tot_energy(0,0,0)))

  do t=0,nt-1
    do idx = 0,0
      pEFIX(idx) = (tot_energy(idx,t,ipBP)-tot_energy(idx,t,ipBF))/dtime
      pDMEA(idx) = (tot_energy(idx,t,ipAM)-tot_energy(idx,t,ipAP))/dtime
      param(idx) = (tot_energy(idx,t,ipAP)-tot_energy(idx,t,ipBP))/dtime
      phys_total(idx) = (tot_energy(idx,t,ipAM)-tot_energy(idx,t,ipBF))/dtime

      zEFIX(idx) = (tot_energy(idx,t,izBP)-tot_energy(idx,t,izBF))/dtime
      zDMEA(idx) = (tot_energy(idx,t,izAM)-tot_energy(idx,t,izAP))/dtime
      zaram(idx) = (tot_energy(idx,t,izAP)-tot_energy(idx,t,izBP))/dtime
      zhys_total(idx) = (tot_energy(idx,t,izAM)-tot_energy(idx,t,izBF))/dtime
    end do

    idx=1
;    checkA = (tot_energy(idx,t,ipAP)-tot_energy(idx,t,ipAM))/dtime
    checkA = (tot_energy(idx,t,izAP)-tot_energy(idx,t,izAM))/todouble(dtime)
    checkB = (tot_energy(idx,t,idAP)-tot_energy(idx,t,idAM))/todouble(dtime)
    diff = (checkA-checkB)/checkA
    print(dtime)
    print("xxx checkA "+checkA)
    print("xxx checkB "+checkB)
    print("xxx diff   "+diff)

    checkA = (tot_energy(idx,t,izAP)-tot_energy(idx,t,idAP))/tot_energy(idx,t,izAP)
    checkB = (tot_energy(idx,t,izAM)-tot_energy(idx,t,idAM))/tot_energy(idx,t,izAP)
    checkC = (tot_energy(idx,t,izBF)-tot_energy(idx,t,idBF))/tot_energy(idx,t,izAP)
    print(dtime)
    print("ddd checkA "+checkA)

    print("ddd checkB "+checkB)
    print("ddd checkC "+checkC)


      print("dE/dt dry mass adjustment (pwork)       (zAM-zAP) "+sprintf("%4g",zDMEA(idx))+" W/M^2")      

;    pwork = (tot_energy_2d(t,ipAM,:)-tot_energy_2d(t,ipAP,:))/dtime

;    dparam = (tot_energy_2d(t,ipAP,:)-tot_energy_2d(t,ipBP,:))/dtime  

    str_data  = new( 1, "string")
    print(" ")
    print("=================================================================================")
    print("|                                                                               |")
    print("| ANALYSIS OF ENERGY DIAGNOSTICS IN PHYSICS                                     |")
    print("|                                                                               |")
    print("=================================================================================")
    do idx = 0,0
      print(" ")
;      print(energy_names(idx))
      print("                                                  "+"total E  " +"  thermal E  "+"  K E")
      print("dE/dt parameterizations (param)         (pAP-pBP) "+sprintf("%4g",param(idx))+" W/M^2")
      print("dE/dt parameterizations (param)         (zAP-zBP) "+sprintf("%4g",zaram(idx))+" W/M^2")
      print("dE/dt dry mass adjustment (pwork)       (pAM-pAP) "+sprintf("%4g",pDMEA(idx))+" W/M^2")
      print("dE/dt dry mass adjustment (pwork)       (zAM-zAP) "+sprintf("%4g",zDMEA(idx))+" W/M^2")
      print("dE/dt energy fixer (efix)               (pBP-pBF) "+sprintf("%4g",pEFIX(idx))+" W/M^2")
      print("dE/dt energy fixer (efix)               (zBP-zBF) "+sprintf("%4g",zEFIX(idx))+" W/M^2")
      pe = pEFIX(idx)+ param(idx)
      print("dE/dt energy fixer (param+efix)         (pAP-pBF) "+sprintf("%4g",pe)+" W/M^2")
      pe = zEFIX(idx)+ zaram(idx)      
      print("dE/dt energy fixer (param+efix)         (zAP-zBF) "+sprintf("%4g",pe)+" W/M^2")
      print("dE/dt physics total (phys)              (pAM-pBF) "+sprintf("%4g",phys_total(idx)) +" W/M^2")
      print("dE/dt physics total (phys)              (zAM-zBF) "+sprintf("%4g",zhys_total(idx)) +" W/M^2")
    end do

    if (dycore.eq."MPAS") then
      print(" ")
      print("=================================================================================")
      print("|                                                                               |")
      print("| ANALYSIS OF ENERGY DIAGNOSTICS IN MPAS DYCORE                                 |")
      print("|                                                                               |")
      print("=================================================================================")      
      print(" ")
      do idx = 0,0
        dDMEA(idx) = (tot_energy(idx,t,idAM)-tot_energy(idx,t,idAP))/dtime
        dparam(idx) = (tot_energy(idx,t,idAP)-tot_energy(idx,t,idBF))/dtime
        dphys_total(idx) = (tot_energy(idx,t,idAM)-tot_energy(idx,t,idBF))/dtime
      end do   
      do idx = 0,0
        print(" ")
        print("                                                  "+"total E  " +"  thermal E  "+"  K E")
        print("dE/dt parameterizations+efix in dycore (dparam)(dAP-dBF) "+sprintf("%4g",dparam(idx))+" W/M^2")
        print("dE/dt dry mass adjustment in dycore            (dAM-dAP) "+sprintf("%4g",dDMEA(idx))+" W/M^2")
        print("dE/dt physics total in dycore (phys)           (dAM-dBF) "+sprintf("%4g",dphys_total(idx)) +" W/M^2")
      end do
    end if

 
    print("    ")
    print("    ")
    print(" ")
    print("=================================================================================")
    print("|                                                                               |")
    print("| ANALYSIS OF WATER VAPOR, CLOUD LIQUID AND CLOUD ICE BUDGETS IN PHYSICS        |")
    print("|                                                                               |")
    print("=================================================================================")
    print(" ")
    print(" ")

    do m_cnst=0,2
      if (m_cnst.eq.0) then 
        print("Water vapor")
        print("-----------")
      end if
      if (m_cnst.eq.1) then
        print("Cloud liquid")
        print("------------")
      end if
      if (m_cnst.eq.2) then 
        print("Cloud ice")
        print("---------")
      end if
      print(" ")
      phys_total(0)    = ((tracer_mass(t,m_cnst,ipBP)-tracer_mass(t,m_cnst,ipBF)))
      pDMEA(0) = (tracer_mass(t,m_cnst,ipAM)-tracer_mass(t,m_cnst,ipAP))
      param(0)           = (tracer_mass(t,m_cnst,ipAP)-tracer_mass(t,m_cnst,ipBP))
;      phys_total      = (tracer_mass(t,m_cnst,ipAM)-tracer_mass(t,m_cnst,ipBF))

      print("dMASS/dt energy fixer                      (pBP-pBF) "+sprintf("%6.3g",phys_total(0))+" Pa")
      print("dMASS/dt parameterizations                 (pAP-pBP) "+sprintf("%6.3g",param(0))+" Pa")
      print("dMASS/dt dry mass adjustment               (pAM-pAP) "+sprintf("%6.3g",pDMEA(0))+" Pa")


      phys_total(0)    = ((tracer_mass(t,m_cnst,idAP)-tracer_mass(t,m_cnst,idBF)))
      pDMEA(0) = (tracer_mass(t,m_cnst,idAM)-tracer_mass(t,m_cnst,idAP))
;      phys_total      = (tracer_mass(t,m_cnst,idAM)-tracer_mass(t,m_cnst,idBF))

      print("dMASS/dt energy fixer  + phys total in dycore      (dAP-dBF) "+sprintf("%6.3g",phys_total(0))+" Pa")
      print("dMASS/dt dry mass adjustment in dycore             (dAM-dAP) "+sprintf("%6.3g",pDMEA(0))+" Pa")
      print(" ")
      value = phys_total(0)+pDMEA(0)
      print("=> dMASS/dt dynamical core (estimated from physics)  ")
      print("   dMASS/dt energy fixer + dMASS/dt dry mass adjustment "+sprintf("%6.3g",value)+" Pa")

      print("=> dMASS/dt physics total                   (pAM-pBF)"+sprintf("%6.3g",phys_total(0))+" Pa")
 

      print("  ")
      print("  ")
      print("  ")
    end do
  end do
end