load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

begin
  fname =  systemfunc("ls "+"regr*cam.h0*"+"*.nc")
  fall = addfiles(fname,"r")       ; Open netCDF files.  
  print("File used for energy diagnostics "+fname)
  print("done input summary")
  print(" ")  
  print("Summary of input to ncl script:")
  print("===============================")
  print(" ")

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
  var=fall[:]->PDELDRY
  time=fall[:]->time
  latlon = all(isdim(var,(/"time","lev","lat","lon"/)))

  if (latlon) then
    print("lat lon grid detected")
    nt  = dimsizes(var(:,0,0))
    lat = fall[0]->lat
    lat = deg2rad*lat
    lon = fall[0]->lon
    lon = deg2rad*lon
    nlat=dimsizes(lat)
    nlon=dimsizes(lon)
    area  = new((/nlat,nlon/),typeof(var(0,0,0,0)))    
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
    print("non lat lon grid detected")
    nt   = dimsizes(var(:,0,0))
    area = fall[0]->area   (:)
    ncol = dimsizes(area(:))
    area_sphere = sum(area(0:ncol-1))          
  end if  
  

  print(" "+area_sphere)
  print(" ")

  if (latlon) then
    mass   = new((/nt,3/),typeof(var(0,0,0,0)))
    int_vars      = new((/nt/)     ,typeof(var(0,0,0,0)))      
    twod   = new((/ncol/),typeof(var(0,0,0,0)))
  else
    mass   = new((/nt,3/),typeof(var(0,0,0)))
    int_vars      = new((/nt/)     ,typeof(var(0,0,0)))        
    int_vars_error      = new((/nt/)     ,typeof(var(0,0,0)))        
    twod     = new((/ncol/),typeof(var(0,0,0)))
  end if
  ;
  ; check that variables are on file and read them and compute global integrals
  ;
 
;  inv_area_sphere   = 1.0D0/area_sphere
  inv_area_sphere   = 1.0/area_sphere

;  mass(t,0,j) = subcycle(j)*(int_vars(idx,j,t))
;      dparam = new((/3/),typeof(tot_energy(0,0,0)))
;      dphys_total  = new((/3/),typeof(tot_energy(0,0,0)))

  printVarSummary(int_vars)
  t=0
  do i=0,ncol-1
    twod(i) = sum(var(t,:,i))
  end do
  int_vars(t) = sum(area(:)*twod(:))*inv_area_sphere

  do t=0,nt-1
    do i=0,ncol-1
      twod(i) = sum(var(t,:,i))
    end do
;    int_vars(t) = sum(doubletofloat(area(:))*twod(:))*doubletofloat(inv_area_sphere)
    int_vars(t) = sum(area(:)*twod(:))*inv_area_sphere
    int_vars_error(t) = (int_vars(t)-int_vars(0))/int_vars(0)
    print("t="+t+" "+int_vars_error(t)+"   "+int_vars(t))
  end do


  res=True
  wks = gsn_open_wks("pdf","mass")
  res@tiMainString = "Normalized dry mass conservation -  MPAS"
  plot = gsn_csm_xy(wks,time,int_vars_error,res)
end