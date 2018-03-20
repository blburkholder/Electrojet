pro electrojet_fit
  COMMON share1,sx,jx,jy,xs,n_peaks,spacing,c
  
;  HERE ARE THE DISTANCES FROM 57 DEG MAG LAT IN METERS
;  [1584067.1646552389,
;  1306883.2405518263,
;  1154376.4228724404,
;  949549.7480329715,
;  1036378.4471497029,
;  671252.6354793457,
;  574405.2403106834,
;  345088.4195664962]
;
;  KAKTOVIK
;  TOOLIK LAKE
;  FORT YUKON
;  POKER FLAT
;  EAGLE
;  GAKONA
;  TRAPPER CREEK
;  KENAI COLLEGE

  shiftee = 150.
  
  ;location of each magnetometer in km
  xtoo = 1307. - shiftee
  xpok = 950. - shiftee
  xeag = 1036. - shiftee
  xgak = 671. - shiftee
  xken = 345. - shiftee
  xtra = 574. - shiftee
  xkak = 1584. - shiftee
  xfty = 1154. - shiftee
  nstations = 8
  
  ;altitude of current sheet
  ;num fits before overwrite
  ;distance in km between 57 and 72 lat 
  jy = 130.  
  hist = 100
  dlat = 1700. - shiftee*2.
  
  pyth_pathpath = '/home/computation/Documents/Classes/Aeronomy/Electrojet2/python_data/'
  now_pathpath = '/home/computation/Documents/Classes/Aeronomy/Electrojet2/now_mag_data/'
  
  ;arrays to print for python plotting
  if not file_test(pyth_pathpath+'fitted_j.csv') then begin
    j = make_array(dlat+1,hist)
    YFIT_arr = make_array(2*nstations,hist)
    now_t = make_array(nstations,hist)
    
    jj = create_struct('j',j)
    yy = create_struct('yy',YFIT_arr)
    nt = create_struct('nt',now_t)
    
    now = make_array(2*nstations,1,/DOUBLE,VALUE = -5000000)
    xw = 0
    
    write_csv, pyth_pathpath+'fitted_j.csv', jj
    write_csv, pyth_pathpath+'fitted_B.csv', yy
    write_csv, pyth_pathpath+'now_t.csv', nt
    write_csv, pyth_pathpath+'now.csv', now
    write_csv, now_pathpath+'xw.csv', xw
  endif

  j = read_csv(pyth_pathpath+'fitted_j.csv')
  YFIT_arr = read_csv(pyth_pathpath+'fitted_B.csv')
  now_t = read_csv(pyth_pathpath+'now_t.csv')
  now = read_csv(pyth_pathpath+'now.csv')
  xw = read_csv(now_pathpath+'xw.csv') 

  j = j.FIELD1
  j = reform(j,dlat+1,hist)
  YFIT_arr = YFIT_arr.FIELD1
  YFIT_arr = reform(YFIT_arr,2*nstations,hist)
  now_t = now_t.FIELD1
  now_t = reform(now_t,nstations,hist)
  now = now.FIELD1 
  xw = xw.FIELD1
  
  magsites = ['toolik','poker','eagle','gakona','kenai','trapper','kaktovik','ftyukon']
  xs = [xtoo,xtoo,xpok,xpok,xeag,xeag,xgak,xgak,xken,xken,xtra,xtra,xkak,xkak,xfty,xfty]  
  
  bases = get_baseline()
  get_realtime_alaskan_magnetometer_data, now_pathpath
   
  infile = now_pathpath+'magnetometer_realtime.csv'
  mag_in = read_csv(infile)
  
  site = mag_in.FIELD1
  time = mag_in.FIELD2
  H = mag_in.FIELD3
  Z = mag_in.FIELD5
  modmod = xw mod hist
    
  now_t[*,modmod] = 0.
  YFIT_arr[*,modmod] = 0.
    
  ;determine time now for sake of dealing with data gaps
  tnow = TIMESTAMP()
  yy = long(tnow.Substring(0,3))
  mm = long(tnow.Substring(5,6))
  dd = long(tnow.Substring(8,9))
  hh = long(tnow.Substring(11,12))
  mimi = long(tnow.Substring(14,15))
  ss = long(tnow.Substring(17,20))  
  jd = 367*yy-7*(yy+(mm+9)/12)/4-3*((yy+(mm-9)/7)/100+1)/4 $
    +275*mm/9+dd+1721029
  tnow_j = (3600.*hh + 60.*mimi + ss) + (jd-2451545)*86400d0
  
  for k=0,n_elements(magsites) - 1 do begin
    p = where(site eq magsites[k],cp)
    if cp ne 0 then begin
      t =  time(p)
      ;watch for data gaps
      if tnow_j - t[-1] lt 300 then begin
        hh = H(p) - bases[k,0]
        zz = Z(p) - bases[k,1]
        now[2*k] = hh[-1]
        now[2*k+1] = zz[-1]
        now_t[k,modmod] = t[-1]
        write_csv, pyth_pathpath+'real_h_'+magsites(k)+'.csv',hh
        write_csv, pyth_pathpath+'real_z_'+magsites(k)+'.csv',zz
        write_csv, pyth_pathpath+'real_time_'+magsites(k)+'.csv',t
      endif     
    endif
  endfor

  ;only want active stations
  X = [ where(now ne -5000000) ]
  Y = now(X)
  ;n_peaks = n_elements(Y)/2.
  n_peaks = 4
  spacing = dlat/n_peaks
  A = make_array(n_peaks,1,/DOUBLE,VALUE = 1.)
  
  ;calculate width of guassian
  ;right now using width is 75% of spacing 
  sig = spacing/(2.*0.75)
  c = 2.*sig*sig

;sanity check?
;   X = [0, 1, 2, 3, 6, 7, 8, 9]
;  n_peaks = 4
;  spacing = dlat/n_peaks
;  A = make_array(4,1.,/DOUBLE,VALUE = 1.)
;  Y = contrived_example()

  ;do the fit!
  result1 = SVDFIT(X,Y,A=A,FUNCTION_NAME='svd_fitfunctz',YFIT=YFIT,/DOUBLE)      
      
  ;add up result from each gaussian  
  xx = findgen(dlat+1)
  jn = make_array(n_elements(xx),1)
  for i = 0,n_peaks - 1 do begin
    jjx = spacing/2. + i*spacing
    jn = jn + result1(i)*exp(-(xx-jjx)^2/c)
    ;p = PLOT(xx,result1(i)*exp(-(xx-jjx)^2/c),'g',/OVERPLOT,TITLE='current density',name='cd')
  endfor

  ;p1 = PLOT(xx,jn,'r',TITLE='current density',name='cd')
  j[*,modmod] = jn
        
  j_add = 0
  for l = 0,nstations-1 do begin
    if now_t[l,modmod] ne 0 then begin
      YFIT_arr[2*l:2*l+1,modmod] = YFIT(j_add:j_add+1)
      j_add = j_add + 2
    endif
  endfor

  xw = xw + 1

  write_csv, pyth_pathpath+'fitted_j.csv',j
  write_csv, pyth_pathpath+'fitted_B.csv',YFIT_arr
  write_csv, pyth_pathpath+'now_t.csv',now_t
  write_csv, pyth_pathpath+'now.csv', now
  write_csv, now_pathpath+'xw.csv', xw
end

FUNCTION svd_fitfunctz, X, M
  COMMON share1,sx,jx,jy,xs,n_peaks,spacing,c
  ret = make_array(n_peaks,1) 
  nint = 1000.
  sx = xs(X)
  if X mod 2 eq 0 then begin ;do h component
    for i = 0,n_peaks-1 do begin
      jx = spacing/2. + i*spacing
      ret[i] = QROMB('CS_H',jx-nint,jx+nint) 
    endfor  
  endif else begin ;do z component
    for i = 0,n_peaks-1 do begin
      jx = spacing/2. + i*spacing
      ret[i] =  QROMB('CS_Z',jx-nint,jx+nint)
    endfor
  endelse
  return, ret  
END

;convert km to m where necessary
function CS_Z,x
  COMMON share1,sx,jx,jy,xs,n_peaks,spacing,c
  return, -2.*100.*((x-sx)*1000.)*exp(-(x-jx)^2./c)/(((x-sx)*1000.)^2.+(jy*1000.)^2.)
end

function CS_H,x
  COMMON share1,sx,jx,jy,xs,n_peaks,spacing,c
  return, 2.*100.*(jy*1000.)*exp(-(x-jx)^2./c)/(((x-sx)*1000.)^2.+(jy*1000.)^2.)
end

