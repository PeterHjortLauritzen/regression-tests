load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
  print(titles)
  ;
  ; user set variables
  ;
  print(vname)
  
;  vname      = (/var_left_panel,var_right_panel/)
;  vname                 = "PS"      ; variable you wish to output
  horizontal_resolution = "ne30_ne30" ; -res setting
  compset="FKESSLER"                ; compset used
;  iday  = 10                        ; plot day
;  iday  = 3                        ; plot day
  iday = tointeger(time_idx)
  output_format = "pdf"             ; output format
  

;******************************************************
; create plot
;******************************************************
  cellfill = True
  fnames =  systemfunc("ls *."+hnum+"*.nc")
  print("fnames: "+fnames)
;  fnames = (/"fkessler.h0.nc","fkessler.h0.nc"/)
  wks = gsn_open_wks(output_format,outfname)
  print("output file "+outfname)
  fall = addfiles(fnames,"r")       ; Open netCDF files.
  
  fcnt = dimsizes(fnames)
  print(fnames)



  gsn_define_colormap(wks,"BlAqGrYeOrReVi200")   ; choose colormap

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
  res@mpOutlineOn     = False       ; No continents
;  res@cnFillMode="RasterFill"

  res@mpMinLatF = 10.                   ; set the minimum latitude = -70.
  res@mpMaxLatF = 70.                    ; set the maximum latitude = 70.

  res@mpMinLonF = 30.                    ; set the minimum latitude = -70.
  res@mpMaxLonF = 210.

  res@gsnStringFontHeightF = 0.02
  res@tiMainFontHeightF = 0.025
  res@lbLabelFontHeightF = 0.02
  res@tmXBLabelFontHeightF = 0.015
  res@tmYLLabelFontHeightF = 0.015
  res@pmLabelBarOrthogonalPosF = 0.2


  plot = new(2*fcnt,graphic) 
  plotk=0
  do k=0,fcnt-1
    time= fall[k]->time(iday)
    print("time "+time)
  
    do nvar=0,1
      print("plot "+k)
      vartmp = fall[k]->$vname(nvar)$
      latlon=all(isdim(vartmp,(/"time","lat","lon"/)))
      delete(vartmp)
      
      if (latlon) then
        print("lat lon data")
        var  = fall[k]->$vname(nvar)$(iday,:,:)    ; Read some data; convert to 1D.i
        lat = fall[k]->lat          ; Pull off lat/lon variable and
        lon = fall[k]->lon          ; convert both to 1D.    	
      else
        print("1D data")      
        var  = fall[k]->$vname(nvar)$(iday,:)    ; Read some data; convert to 1D.i
        lat1d = fall[k]->lat          ; Pull off lat/lon variable and
        lon1d = fall[k]->lon          ; convert both to 1D.    	
        res@sfXArray            = lon1d        ; Required to tell NCL where to
        res@sfYArray            = lat1d        ; overlay data on globe.	
      end if
      
        res@tiMainString        = titles(k)

      if (model.eq."fv3") then
	if (cellfill) then
  	  sf = addfile("/glade/u/home/pel/src/regression-tests/grid_descriptor_files/FV3.SCRIP.nc","r")
          print("adding /glade/u/home/pel/src/regression-tests/grid_descriptor_files/FV3.SCRIP.nc")
	end if
      end if
      if (model.eq."fv") then
	if (cellfill) then
  	  sf = addfile("/glade/u/home/pel/src/regression-tests/grid_descriptor_files/FV.SCRIP.nc","r")
	end if	
      end if
      if (model.eq."se") then
	if (cellfill) then
  	  sf = addfile("/glade/u/home/pel/src/regression-tests/grid_descriptor_files/SE.SCRIP.nc","r")
	end if	
      end if
      if (model.eq."se-cslam") then
	if (cellfill) then
  	  sf = addfile("/glade/u/home/pel/src/regression-tests/grid_descriptor_files/SE-CSLAM.SCRIP.nc","r")
	end if	
      end if
      if (model.eq."mpas") then
	if (cellfill) then
  	  sf = addfile("/glade/u/home/pel/src/regression-tests/grid_descriptor_files/MPAS.SCRIP.nc","r")
	end if
      end if



    if (cellfill) then
        latvert = sf->grid_corner_lat
        lonvert = sf->grid_corner_lon
	if (lonvert@units.eq."radians") then
	  r2d  = get_r2d("double")
	  latvert =r2d*latvert
	  lonvert = r2d*lonvert
	end if

        res@cnFillMode = "CellFill"
        res@sfXCellBounds = lonvert
        res@sfYCellBounds = latvert

        delete([/sf,latvert,lonvert/])
      else
        res@cnFillMode          ="RasterFill"      
      end if     

      res@cnLevelSelectionMode = "AutomaticLevels"

      if (vname(nvar).eq."iCL") then
        res@cnLevelSelectionMode = "ManualLevels"
        res@cnMinLevelValF  = 5.0E-7
        res@cnMaxLevelValF  = 4.0E-6
        res@cnLevelSpacingF = 0.25E-6	
      end if
;      if (vname(nvar).eq."iCLy") then
;        res@cnLevels = (/3.e-6,  3.7e-6, 3.9e-6, 3.97e-6, 3.99e-6, 4.01e-6, 4.03e-6, 4.1e-6, 4.3e-6, 5e-6 /)
;        res@lbLabelStrings  = sprintf("%4.2fe-6",1e6*res@cnLevels)   ; Format the labels
;      end if

      if (vname(nvar).eq."PRECL") then
        var = 1000*24*3600*var ;convert from m/s to mm/day  
        res@cnLevelSelectionMode = "ManualLevels"
        res@gsnRightString = "mm/day"
        res@cnMinLevelValF  = 0.0
        res@cnMaxLevelValF  = 60.0
        res@cnLevelSpacingF = 2.0
      end if


      if (vname(nvar).eq."PS") then
        var = var/100.0 ;convert from Pa to hPa
        res@gsnRightString = "hPa"
        if (time.eq.10) then
          res@cnLevelSelectionMode = "ManualLevels"
          res@cnMinLevelValF  = 945.0
          res@cnMaxLevelValF  = 1015.0
          res@cnLevelSpacingF = 5.0
        end if
        if (time.eq.3) then
          res@cnLevelSelectionMode = "ManualLevels"
          res@cnMinLevelValF  = 990.0
          res@cnMaxLevelValF  = 1010.0
          res@cnLevelSpacingF = 2.0
        end if
        if (k.eq.2) then
          res@cnLevelSelectionMode = "ManualLevels"
          res@cnMinLevelValF  = -2.0
          res@cnMaxLevelValF  = 2.0
          res@cnLevelSpacingF = 0.1
        end if
;xxx        if (time.eq.1) then
;	  print("setting countours to detail")
;          res@cnLevelSelectionMode = "ManualLevels"
;          res@cnMinLevelValF  = 999.80
;          res@cnMaxLevelValF  = 1000.2
;          res@cnLevelSpacingF = 0.005
;xxx        end if	
      end if

      res@mpCenterLonF = 180.0           ; Rotate the projection.
      plot(plotk) = gsn_csm_contour_map_ce(wks,var,res)
      plotk=plotk+1
      delete(var)
      delete(res@cnMinLevelValF)
      delete(res@cnMaxLevelValF)
      delete(res@cnLevelSpacingF)
      if (latlon) then
        delete(lat)
        delete(lon)
      else
        delete(lat1d)
        delete(lon1d)
        delete(res@sfXArray)
        delete(res@sfYArray)      
      end if      
;      delete(res@cnLevels)
;      delete(res@lbLabelStrings)
      if (cellfill) then
        delete(res@sfXCellBounds)
        delete(res@sfYCellBounds)
      end if
    end do
;    delete(time)    
  end do
;************************************************
; create panel
;************************************************
  resP                  = True                   ; modify the panel plot
  txres               = True  
  resP@gsnFrame         = False                  ; don't advance panel plot
;  resP@gsnPanelLabelBar = True                  ; add common colorbar
;  resP@gsnPanelBottom   = 0.05
  txres@txFontHeightF = 0.015
  resP@txString   = "Day "+time+" moist baroclinic wave with Kessler physics"
  resP@gsnPanelYWhiteSpacePercent = 2.0
;    resP@gsnPanelYWhiteSpacePercent = 10.0
  resP@gsnPanelXWhiteSpacePercent = 4.0
  gsn_panel(wks,plot,(/fcnt,2/),resP)            ; now draw as one plot


;  txres@txFontHeightF = 0.015
;  gsn_text_ndc(wks,"Figure 1: A nifty panel plot",0.5,0.02,txres)
  frame(wks)
end
