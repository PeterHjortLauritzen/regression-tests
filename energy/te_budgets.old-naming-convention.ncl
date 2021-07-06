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
    lat1d  = fall->lat          ; Pull off lat/lon variable and
    lon1d  = fall->lon          ; convert both to 1D.
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
  print("dDP: state passed to parameterizations")
  print("dAM: dDP state + temperature and wind increments (no moisture change)")
  print("dPD: dDP state with full physics update (no physics-dynamics coupling dribbling errors)")
  end if


  if (dycore.eq."MPAS") then
    str_vars      = (/"SE","KE","WV","WL","WI"/)
    str_stage     = (/"pBF","pBP","pAP","pAM","zBF","zBP","zAP","zAM","dDP","dDM","dPD"/) 
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

  idDP = str_match_ind(str_stage,"dDP")
  idDM = str_match_ind(str_stage,"dDM")
  idPD = str_match_ind(str_stage,"dPD")



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
    checkB = (tot_energy(idx,t,idDM)-tot_energy(idx,t,idPD))/todouble(dtime)
    diff = (checkA-checkB)/checkA
    print(dtime)
    print("xxx checkA "+checkA)
    print("xxx checkB "+checkB)
    print("xxx diff   "+diff)

    checkA = (tot_energy(idx,t,izAP)-tot_energy(idx,t,idDM))/tot_energy(idx,t,izAP)
    checkB = (tot_energy(idx,t,izAM)-tot_energy(idx,t,idPD))/tot_energy(idx,t,izAP)
    checkC = (tot_energy(idx,t,izBF)-tot_energy(idx,t,idDP))/tot_energy(idx,t,izAP)
    print(dtime)
    print("ddd checkA "+checkA)

    print("ddd checkB "+checkB)
    print("ddd checkC "+checkC)


      print("dE/dt dry mass adjustment (pwork)       (zAM-zAP) "+sprintf("%4g",zDMEA(idx))+" W/M^2")      

    dmeadj2d  = (tot_energy_2d(t,ipAM,:)-tot_energy_2d(t,ipAP,:))/dtime
    dparam2d =  (tot_energy_2d(t,ipAP,:)-tot_energy_2d(t,ipBP,:))/dtime  

    dmeadjz2d  = (tot_energy_2d(t,izAM,:)-tot_energy_2d(t,izAP,:))/dtime
    dparamz2d =  (tot_energy_2d(t,izAP,:)-tot_energy_2d(t,izBP,:))/dtime  

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
        dDMEA(idx) = (tot_energy(idx,t,idPD)-tot_energy(idx,t,idDM))/dtime
        dparam(idx) = (tot_energy(idx,t,idDM)-tot_energy(idx,t,idDP))/dtime
        dphys_total(idx) = (tot_energy(idx,t,idPD)-tot_energy(idx,t,idDP))/dtime
      end do   
      do idx = 0,0
        print(" ")
        print("                                                  "+"total E  " +"  thermal E  "+"  K E")
        print("dE/dt parameterizations+efix in dycore (dparam)(dDM-dDP) "+sprintf("%4g",dparam(idx))+" W/M^2")
        print("dE/dt dry mass adjustment in dycore            (dPD-dDM) "+sprintf("%4g",dDMEA(idx))+" W/M^2")
        print("dE/dt physics total in dycore (phys)           (dPD-dDP) "+sprintf("%4g",dphys_total(idx)) +" W/M^2")
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
      print(" ")
      value = phys_total(0)+pDMEA(0)
      print("=> dMASS/dt dynamical core (estimated from physics)  ")
      print("   dMASS/dt energy fixer + dMASS/dt dry mass adjustment "+sprintf("%6.3g",value)+" Pa")

      print("=> dMASS/dt physics total                   (pAM-pBF)"+sprintf("%6.3g",phys_total(0))+" Pa")
 

      print("  ")
      print("  ")
      print("  ")
    end do

    output_format = "pdf"
    wks = gsn_open_wks(output_format,panelTitle)
    gsn_define_colormap(wks,"NCV_jaisnd");3gauss")      
  ; gsn_define_colormap(wks,"BlAqGrYeOrReVi200")   ; choose colormap
  ; gsn_define_colormap(wks,"GMT_polar")
    



    res                     = True         ; plot modifications desired
    res@gsnMaximize         = False         ; Maximize size of plot in frame
    res@gsnSpreadColors     = True         ; Use full colormap, but start
    res@gsnDraw             = False           ; don't draw
    res@gsnFrame            = False           ; don't advance frame
    res@cnFillOn            = True         ; Turn on contour fill
  ;  res@cnFillMode          = "AreaFill"   ; Style of fill. You can also
                                         ; use "CellFill" and "RasterFill"
    res@cnLinesOn           = False        ; Turn off contour lines
    res@cnLineLabelsOn      = False        ; Turn off contour line labels
    res@lbLabelAutoStride   = True         ; Clean up labelbar labels.
    res@cnFillMode="RasterFill"


    res@gsnStringFontHeightF = 0.02
    res@tiMainFontHeightF = 0.025
    res@lbLabelFontHeightF = 0.02
    res@tmXBLabelFontHeightF = 0.015
    res@tmYLLabelFontHeightF = 0.015
    res@pmLabelBarOrthogonalPosF = 0.2
 
    res@lbBoxLinesOn = False

    res_p=res

    plot = new(6,graphic) 

    str = "d/dt(parameterizations); cp"

    fld = dparam2d(0:ncol-1)

    res_p@cnLevelSelectionMode = "ManualLevels"    ; manually set the contour levels with the following 3 resources
    fmin = -150.
    fmax =  150.
    res_p@cnMinLevelValF  = fmin                        ; set the minimum contour level
    res_p@cnMaxLevelValF  = fmax                   ; set the maximum contour level
    res_p@cnLevelSpacingF = (fmax-fmin)/50.0 

    min_f = min(fld)
    max_f = max(fld)
    print("dparam "+min_f+" "+max_f)

    res_p@lbTitleString    = "global min = "+sprintf("%6.4g",min_f)+"  global  max="+sprintf("%6.4g",max_f)

    res_p@sfXArray            = lon1d
    res_p@sfYArray            = lat1d

    res_p@gsnLeftString        = str
    global_ave = sum(area(0:ncol-1)*fld(0:ncol-1))*inv_area_sphere
    print(str+" global ave: "+global_ave)
    res_p@gsnRightString        = "mean: "+sprintf("%3.2g", global_ave        )+" W/m^2"

    plot(0) = gsn_csm_contour_map_ce(wks,fld,res_p)

    ;
    ;
    ;
    str = "d/dt(parameterizations); cv"

    fld = dparamz2d(0:ncol-1)

    res_p@cnLevelSelectionMode = "ManualLevels"    ; manually set the contour levels with the following 3 resources
    fmin = -150.
    fmax =  150.
    res_p@cnMinLevelValF  = fmin                        ; set the minimum contour level
    res_p@cnMaxLevelValF  = fmax                   ; set the maximum contour level
    res_p@cnLevelSpacingF = (fmax-fmin)/50.0 

    min_f = min(fld)
    max_f = max(fld)
    print("dparam "+min_f+" "+max_f)

    res_p@lbTitleString    = "global min = "+sprintf("%6.4g",min_f)+"  global  max="+sprintf("%6.4g",max_f)

    res_p@sfXArray            = lon1d
    res_p@sfYArray            = lat1d

    res_p@gsnLeftString        = str
    global_ave = sum(area(0:ncol-1)*fld(0:ncol-1))*inv_area_sphere
    print(str+" global ave: "+global_ave)
    res_p@gsnRightString        = "mean: "+sprintf("%3.2g", global_ave        )+" W/m^2"

    plot(1) = gsn_csm_contour_map_ce(wks,fld,res_p)


    ;;;
    ;;;
    ;;;

    str = "Moisture adjustment (dmeadj); cp"
 
    fld = dmeadj2d(0:ncol-1)

    fmin = -20.
    fmax =  20.
    res_p@cnMinLevelValF  = fmin                        ; set the minimum contour level
    res_p@cnMaxLevelValF  = fmax                   ; set the maximum contour level
    res_p@cnLevelSpacingF = (fmax-fmin)/50.0 

    min_f = min(fld)
    max_f = max(fld)
    print("dparam "+min_f+" "+max_f)

    min_f = min(fld)
    max_f = max(fld)
    print("dmeajd2d "+min_f+" "+max_f)
    res_p@lbTitleString    = "global min = "+sprintf("%6.4g",min_f)+"  global  max="+sprintf("%6.4g",max_f)
    res_p@sfXArray            = lon1d
    res_p@sfYArray            = lat1d

    res_p@gsnLeftString        = str
    global_ave = sum(area(0:ncol-1)*fld(0:ncol-1))*inv_area_sphere
    print(str+" global ave: "+global_ave)
    res_p@gsnRightString        = "mean: "+sprintf("%3.2g", global_ave        )+" W/m^2"

    plot(2) = gsn_csm_contour_map_ce(wks,fld,res_p)

   ;;;
    ;;;
    ;;;

    str = "Moisture adjustment (dmeadj); cp"
 
    fld = dmeadj2d(0:ncol-1)

    fmin = -20.
    fmax =  20.
    res_p@cnMinLevelValF  = fmin                        ; set the minimum contour level
    res_p@cnMaxLevelValF  = fmax                   ; set the maximum contour level
    res_p@cnLevelSpacingF = (fmax-fmin)/50.0 

    min_f = min(fld)
    max_f = max(fld)
    print("dparam "+min_f+" "+max_f)

    min_f = min(fld)
    max_f = max(fld)
    print("dmeajd2d "+min_f+" "+max_f)
    res_p@lbTitleString    = "global min = "+sprintf("%6.4g",min_f)+"  global  max="+sprintf("%6.4g",max_f)
    res_p@sfXArray            = lon1d
    res_p@sfYArray            = lat1d

    res_p@gsnLeftString        = str
    global_ave = sum(area(0:ncol-1)*fld(0:ncol-1))*inv_area_sphere
    print(str+" global ave: "+global_ave)
    res_p@gsnRightString        = "mean: "+sprintf("%3.2g", global_ave        )+" W/m^2"

    plot(3) = gsn_csm_contour_map_ce(wks,fld,res_p)

    ;;;
    ;;;
    ;;;

    str = "Moisture adjustment (dmeadj); cv"
 
    fld = dmeadjz2d(0:ncol-1)

    fmin = -20.
    fmax =  20.
    res_p@cnMinLevelValF  = fmin                        ; set the minimum contour level
    res_p@cnMaxLevelValF  = fmax                   ; set the maximum contour level
    res_p@cnLevelSpacingF = (fmax-fmin)/50.0 

    min_f = min(fld)
    max_f = max(fld)
    print("dparam "+min_f+" "+max_f)

    min_f = min(fld)
    max_f = max(fld)
    print("dmeajdz2d "+min_f+" "+max_f)
    res_p@lbTitleString    = "global min = "+sprintf("%6.4g",min_f)+"  global  max="+sprintf("%6.4g",max_f)
    res_p@sfXArray            = lon1d
    res_p@sfYArray            = lat1d

    res_p@gsnLeftString        = str
    global_ave = sum(area(0:ncol-1)*fld(0:ncol-1))*inv_area_sphere
    print(str+" global ave: "+global_ave)
    res_p@gsnRightString        = "mean: "+sprintf("%3.2g", global_ave        )+" W/m^2"

    plot(4) = gsn_csm_contour_map_ce(wks,fld,res_p)

    ;;;
    ;;;
    ;;;

    str = "Moisture adjustment (dmeadj); cv-cp"
 
    fld = dmeadjz2d(0:ncol-1)-dmeadj2d(0:ncol-1)

    fmin = -10.
    fmax =  10.
    res_p@cnMinLevelValF  = fmin                        ; set the minimum contour level
    res_p@cnMaxLevelValF  = fmax                   ; set the maximum contour level
    res_p@cnLevelSpacingF = (fmax-fmin)/50.0 

    min_f = min(fld)
    max_f = max(fld)
    print("dparam "+min_f+" "+max_f)

    min_f = min(fld)
    max_f = max(fld)
    print("dmeajdz2d "+min_f+" "+max_f)
    res_p@lbTitleString    = "global min = "+sprintf("%6.4g",min_f)+"  global  max="+sprintf("%6.4g",max_f)
    res_p@sfXArray            = lon1d
    res_p@sfYArray            = lat1d

    res_p@gsnLeftString        = str
    global_ave = sum(area(0:ncol-1)*fld(0:ncol-1))*inv_area_sphere
    print(str+" global ave: "+global_ave)
    res_p@gsnRightString        = "mean: "+sprintf("%3.2g", global_ave        )+" W/m^2"

    plot(5) = gsn_csm_contour_map_ce(wks,fld,res_p)

    ; 
    ; ==============================================================================================================
    ;
    resP                  = True                   ; modify the panel plot
    resP@gsnFrame         = False                  ; don't advance panel plot
    resP@gsnPanelFigureStrings = (/"a","b","c","d","e","f"/)
    resP@gsnPanelYWhiteSpacePercent = 4.0
    resP@gsnPanelXWhiteSpacePercent = 4.0

    resP@txString   = panelTitle
    gsn_panel(wks,plot,(/3,3/),resP)               ; now draw as one plot



   txres               = True
   frame(wks)

;
  end do
end